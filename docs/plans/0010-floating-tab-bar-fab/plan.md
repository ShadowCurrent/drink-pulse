# 0010 — Floating tab bar with prominent Add-Drink FAB

**Status**: in-progress
**Frozen**: 2026-05-20
**Size**: medium
**Created**: 2026-05-19

## Summary

Replace `ContentView`'s standard `TabView` with a custom bottom bar that
combines four primary tabs (Home, Insights, History, Settings) and a 54pt
circular gradient FAB on the right for "Add Drink". The FAB is the single
discoverable entry point — per-screen toolbar `+` buttons are removed.

## Context

- User requirement: "the Add Drink button should be easy to find and tap,
  should be good visible". A 54pt FAB beats a 28pt nav-bar `+`.
- Insights tab added as a placeholder — content lands in [[plan-0012]].
- Tab order: Home · Insights · History · Settings · FAB.
- Theme gradient (from [[plan-0008]]) fills the FAB.

## Scope

### In
- `Features/Shell/Tab.swift` — `enum AppTab: String, CaseIterable` (home,
  insights, history, settings) with icon names and localized label.
- `Features/Shell/RootShellView.swift` — owns `@State tab` + `@State
  showAddDrink`; renders active screen + bar; presents Add Drink sheet.
- `Features/Shell/Components/DPBottomBar.swift` — pure view: four tab
  buttons + FAB. Reads `@Environment(\.dpTheme)`. No internal state.
- `Features/Insights/InsightsView.swift` — placeholder (`ContentUnavailableView`).
- Strip `showAddDrink` state, toolbar item, and sheet from `DashboardView`
  and `HistoryView`.
- `drinkpulseApp.swift` — swap `ContentView` → `RootShellView`.

### Out
- Sheet content for Add Drink — unchanged.
- Edge gestures / iPad-specific layouts.
- Reordering tabs by user.
- Badge counts on tabs.

## Open questions resolved

- **Q1 — Bar position**: in-flow via `.safeAreaInset(edge: .bottom)` (A).
  Bar background extends into home-indicator safe area via
  `.ignoresSafeArea(edges: .bottom)`.
- **Q2 — Sheet hides bar**: yes — sheets cover bar automatically (A).
- **Q3 — Tab icons**: SF Symbols with `.fill` variant when active (A).
- **Q4 — Tab count**: four tabs; future features route into existing tabs
  or Dashboard cards (A).

## Implementation steps

1. `Tab.swift` — `AppTab` enum (name avoids SwiftUI's `Tab` type).
2. `DPBottomBar.swift` — `DPBottomBar(selected:onSelect:onAddDrink:)` +
   private `TabItemButton` + private `AddDrinkFAB` with spring press.
3. `RootShellView.swift` — tab switch via `@ViewBuilder` + ZStack-with-opacity
   to preserve per-tab navigation state.
4. `InsightsView.swift` placeholder.
5. Strip toolbar `+` and `showAddDrink` from `DashboardView`, `HistoryView`.
6. `drinkpulseApp.swift` — replace `ContentView()` with `RootShellView()`.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/Shell/Tab.swift` | Create |
| `drinkpulse/Features/Shell/RootShellView.swift` | Create |
| `drinkpulse/Features/Shell/Components/DPBottomBar.swift` | Create |
| `drinkpulse/Features/Insights/InsightsView.swift` | Create (placeholder) |
| `drinkpulse/ContentView.swift` | Delete |
| `drinkpulse/drinkpulseApp.swift` | Modify |
| `drinkpulse/Features/Dashboard/DashboardView.swift` | Modify (strip toolbar) |
| `drinkpulse/Features/History/HistoryView.swift` | Modify (strip toolbar) |
| `drinkpulse/Localizable.xcstrings` | Add `tab.insights` key |

## Tests required

No view-model logic; covered by Previews. Existing test suite must remain
green.

## Future links

- [[plan-0008]] — `theme.gradient` fills the FAB.
- [[plan-0012]] — Insights tab content.
