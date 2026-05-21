# Plan 0018 — Native iOS 26 Shell Redesign

Status: in-progress
Frozen: 2026-05-21
Size: medium
Created: 2026-05-21

## Problem

Two separate non-native design issues need fixing in the same pass:

**1. Shell / tab bar (plan-0010 leftover):**
`Tab(role: .search)` was introduced to detach the "+" button from the
native tab bar pill. The result looks non-native and inconsistent with iOS 26.

**2. Settings cards (flash bug + non-native):**
`SettingsForm` uses `ScrollView + VStack + dpGlassCard()` on top of an
explicit `.background(Color(.systemGroupedBackground))`. When the user
switches dark/light mode inside Settings, two independent rendering paths
(the explicit background and the `glassEffect`) do not sync → visible
flash. The fix is replacing custom cards with native `List` (same pattern
as the iOS system Settings app), which manages its own background and
section styling natively.

**3. Dashboard cards:**
`MetricCard`, `StreakCard`, `ConsumptionOverviewCard`, `ThisWeekCard`
all use `Color(.secondarySystemBackground)` solid backgrounds instead of
`glassEffect`.

Reference for shell: WhatsApp iOS 26 — standard native tab bar +
prominent colored circle "+" in navigation bar.

## Goal

One pass that makes the entire app shell + Settings + dashboard cards
fully native iOS 26 Liquid Glass. No custom backgrounds, no explicit
material wrappers where the system already provides them.

### Decisions confirmed before writing this plan

| Question | Answer |
|---|---|
| "+" button style | Colored gradient circle (filled, like WhatsApp green) |
| "+" button scope | Visible on **all 4 tabs** |
| Background tint | Follows selected `DPTheme` (`theme.primary.opacity(0.04)`) |
| Dashboard cards | `glassEffect(.regular)` (Liquid Glass) |
| Settings layout | Native `List` with `.insetGrouped` — same as iOS Settings app |

## Out of scope

- Any navigation or routing logic changes
- Insights / History screen content
- Tab order or tab icons
- New features or data model changes
- `SettingsRow` used in `AppearanceCard` — row layout stays; only the
  card container changes

## File changes

### 1. `Features/Shell/Tab.swift`

Remove the `addDrink` case from `AppTab`. After this change, `AppTab`
has 4 cases: `home`, `insights`, `history`, `settings`.

### 2. `Features/Shell/Components/AddDrinkButton.swift` *(new)*

Standalone `View` for the colored circle "+" in the navigation bar.
`theme.gradient` fill (same gradient as the former FAB — brand consistent).

```
AddDrinkButton(action: () -> Void)
  └─ Button
       └─ ZStack
            ├─ Circle().fill(theme.gradient)   // 36×36 pt
            └─ Image(systemName: "plus")
                 .foregroundStyle(.white)
                 .font(.system(size: 16, weight: .semibold))
```

`accessibilityLabel("add.drink")`, `.accessibilityAddTraits(.isButton)`.

### 3. `Features/Shell/RootShellView.swift`

Remove plan-0010 hacks, add background tint, wire toolbar button.

**Remove:**
- `@State private var lastRealTab: AppTab`
- `Tab(role: .search)` block
- `onChange(of: selectedTab)` block

**Add:**
- `@Environment(\.dpTheme) private var theme`
- `ZStack` wrapping `TabView` with `theme.primary.opacity(0.04).ignoresSafeArea()` as background layer
- `AddDrinkButton { showAddDrink = true }` in `.toolbar` of every `NavigationStack`

Each tab becomes:
```swift
Tab("tab.home", systemImage: "house", value: AppTab.home) {
    NavigationStack {
        DashboardView()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AddDrinkButton { showAddDrink = true }
                }
            }
    }
}
```

`showAddDrink` state and `.sheet(isPresented:)` stay at `RootShellView` level.

### 4. `Features/Dashboard/Components/DashboardMetricCards.swift`

`MetricCard` + `StreakCard`: replace
```swift
.background(Color(.secondarySystemBackground))
.clipShape(RoundedRectangle(cornerRadius: 16))
```
with `.dpGlassCard()`.

`GuidelineAlertCard`: apply `.dpGlassCard()` as base; overlay
`Color.dpRed.opacity(0.10)` in the same `RoundedRectangle(cornerRadius: 24)`
so glass shows through the tint.

### 5. `Features/Dashboard/Components/ConsumptionOverviewCard.swift`

`secondarySystemBackground + clipShape` → `.dpGlassCard()`.

### 6. `Features/Dashboard/Components/ThisWeekCard.swift`

`secondarySystemBackground + clipShape` → `.dpGlassCard()`.

### 7. `Features/Settings/SettingsView.swift`

**Root cause of flash:** `SettingsForm` has both `.background(Color(.systemGroupedBackground))` and cards using `glassEffect`. On dark/light switch, the explicit background re-renders before glass → flash.

**Fix:** Replace `ScrollView + VStack + dpGlassCard()` with a native
`List` using `.listStyle(.insetGrouped)`. The List manages its own
background (and glass-styled section cards on iOS 26) — no explicit
background needed.

Before structure:
```swift
ScrollView {
    VStack(spacing: 6) {
        sectionHeader("...")
        AppearanceCard()          // dpGlassCard wrapper
        sectionHeader("...")
        profileCard               // VStack + dpGlassCard
        ...
    }
    .background(Color(.systemGroupedBackground).ignoresSafeArea())
}
```

After structure:
```swift
List {
    Section { AppearanceRows() } header: { sectionHeader("...") }
    Section {
        SettingsRow(...) { Picker(...) }
        SettingsRow(...) { DatePicker(...) }
    } header: { sectionHeader("...") }
    Section { ... } header: { ... }
    Section { ... } header: { ... }
    Section { ... } header: { ... }
}
.listStyle(.insetGrouped)
```

No more `.dpGlassCard()` on settings cards (List provides native glass).
No more `rowDivider` (List adds separators automatically).
No more `.padding(.bottom, 16)` spacing (Section spacing is system-managed).
No more `.background(Color(.systemGroupedBackground).ignoresSafeArea())`.

`SettingsRow` padding: remove explicit `.padding(.horizontal, 16).padding(.vertical, 12)`
from `SettingsRow`'s body — replace with `.listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))` applied per-row. This keeps the same visual spacing but via the List layout system.

### 8. `Features/AddDrink/DrinkTypeGridView.swift`

Two fixes:

**`DrinkTypeTile`**: replace
```swift
.background(Color(.secondarySystemBackground))
.clipShape(.rect(cornerRadius: 12))
```
with `.dpGlassCard(.chip)` (chip = 14 pt corner radius, appropriate for
the compact tile size).

**`DrinkTypeGridView` body**: remove `.background(Color(.systemBackground))`
— no explicit background needed; the sheet's native presentation surface
already handles it.

### 10. `Features/Settings/Components/AppearanceCard.swift` → refactored

Strip the `VStack(spacing: 0) + dpGlassCard + padding` card shell.
Rename to `AppearanceRows` (or keep `AppearanceCard` — the name no
longer describes a card). The view returns just the two rows:
- `SettingsRow("settings.appearance.theme") { ... }`
- `SettingsRow("settings.appearance.mode") { ... }`

These rows are embedded in a `Section` in `SettingsView`, so the List
provides the card appearance automatically.

### 11. `Features/Settings/Components/SettingsRow.swift`

Remove hardcoded padding from body. Each callsite in a `List` will apply
`.listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))`
via a view modifier, OR `SettingsRow` adds it internally with a check for
when it's inside a List (use `listRowInsets` modifier directly on the row).

Simplest correct approach: remove padding from `SettingsRow` entirely and
let each call site in `SettingsView` set `.listRowInsets(...)` once per
Section via `.listRowInsets(...)` applied to the Section content.

Also remove `cardRow()` extension — no longer used after settings migration.

### 12. `Features/Onboarding/Components/GuidelineStep.swift`

One-line fix: change `listStyle(.plain)` to `listStyle(.insetGrouped)`.
The guideline choices list gets a native iOS 26 glass card container,
consistent with `HistoryView` and the new `SettingsView`.

## What does NOT change

- `DPGlass.swift` — `dpGlassCard()` modifier unchanged
- `DPTheme.swift` — no changes
- `GuidelinePickerSheet.swift` — already native `List + NavigationStack` ✅
- `DrinkDetailInputView` — already native `Form + Section` ✅
- `EditEventView` — already native `Form + Section` ✅
- `HistoryView` — already native `List + insetGrouped` ✅
- `InsightsView` — placeholder only, untouched

## Testing

### Compile verification

After removing `AppTab.addDrink`, the compiler will catch any remaining
reference immediately. Confirmed references are only in `RootShellView.swift`
and `Tab.swift` — both rewritten in this plan. No other file uses the symbol.

After removing `cardRow()` from `SettingsRow.swift`, verify no other file
calls `.cardRow()` outside Settings (currently used only in `SettingsView`
— both callsites disappear with the List conversion).

### Existing tests

All 127+ tests are domain/viewmodel/logic tests. None reference:
- `AppTab` or its cases
- Any SwiftUI view or modifier
- `SettingsRow`, `DPGlass`, `DrinkTypeTile`, or any UI component

All existing tests must pass unchanged after this plan.
Run: `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

### New tests

**None required.** Every change in this plan is a pure UI layout change
(modifier swaps, container type change, background removal). Per CLAUDE.md:
"Pure layout / SwiftUI view structure" is excluded from the coverage
denominator and does not require unit tests.

Coverage will remain ≥90% because the denominator (testable logic) does
not change.

## Risk

**Low–medium.** Settings refactor is the highest-risk piece — it touches
the most code, but it's still purely visual with no data or logic changes.
The `List + Section` pattern is well-established SwiftUI. The flash bug
should be completely eliminated by removing the explicit background.
Dashboard card changes are low-risk (modifier swap only).

## End-of-task checklist targets

- `xcodebuild build` clean
- All existing tests green (0 new tests required — no new logic)
- No Swift file > 300 lines (SettingsView may need splitting if it
  crosses 300 lines after conversion — split card sections to Components)
- Living docs updated: `current-focus.md`, `roadmap.md`, `DEVLOG.md`
- Plan tracked in `execution.md` on start, `retrospective.md` on close
