# Architecture Research

**Domain:** iOS/SwiftUI native-feel features on an existing MVVM + `@Observable` + SwiftData app (DrinkPulse v1.3)
**Researched:** 2026-07-28
**Confidence:** HIGH — all findings are grounded in direct reads of the current codebase (`Features/Insights/*`, `Features/History/*`, `drinkpulse.xcodeproj/project.pbxproj`), not general framework docs.

This is not greenfield ecosystem research. All three v1.3 features are additive/modificative work against a codebase whose patterns are already fixed by `docs/architecture.md` and `CLAUDE.md`. This document maps each feature onto those existing patterns, calls out where a new pattern must be introduced, and gives a build order.

## Standard Architecture (current, unchanged by this milestone)

```
┌─────────────────────────────────────────────────────────────────────┐
│  Views (Features/<Name>/)                                           │
│  @Query fetch, @Environment(\.modelContext) mutation, @State (vm)   │
│  ├── Insights/  (InsightsView → InsightsHeroCard → AlcoholAreaChart)│
│  └── History/   (HistoryView → segment switch → List | ScrollView)  │
├───────────────────────────────────────────────────────────────────── ┤
│  View Models (@Observable @MainActor, stateless re: persistence)     │
│  ├── InsightsViewModel (+Charts, +Formatting, +HealthMetrics exts)   │
│  └── HistoryViewModel  (pure functions; owns NO @State-like fields)  │
├───────────────────────────────────────────────────────────────────── ┤
│  Domain (Domain/) — ConsumptionEvent, AlcoholUnit, GuidelineChoice   │
├───────────────────────────────────────────────────────────────────── ┤
│  DesignSystem/ — DPColors, DPBrand, DPGlass (.dpGlassCard()), etc.   │
└───────────────────────────────────────────────────────────────────── ┘
```

None of the three v1.3 features touch Domain or Services. All three are Views/DesignSystem-layer work; two touch a View Model at most incidentally.

### Component Responsibilities (existing, relevant to this milestone)

| Component | Responsibility | File |
|-----------|----------------|------|
| `InsightsHeroCard` | Headline total + trend badge + embeds `AlcoholAreaChart` | `Features/Insights/Components/InsightsHeroCard.swift` |
| `AlcoholAreaChart` | Pure chart view, no VM dependency; takes `[ChartPoint]` + `period` | `Features/Insights/Components/AlcoholAreaChart.swift` |
| `WeekdayBarChart` | Pure chart view; takes `[WeekdayBar]` + unit divisor/label (no VM dependency) | `Features/Insights/Components/WeekdayBarChart.swift` |
| `InsightsViewModel+Formatting` | Sole place unit-aware string formatting happens (`formattedValue(_:)`) | `Features/Insights/InsightsViewModel+Formatting.swift` |
| `HistoryView` | Owns `segment: HistorySegment` and all other transient UI `@State` (window start, month shown, selected day) | `Features/History/HistoryView.swift` |
| `HistoryViewModel` | Pure computation only (grid cells, grouping, window math) — **owns zero transient UI state today** | `Features/History/HistoryViewModel.swift` |
| `HistorySegment` | 2-case enum (`.list`, `.calendar`), `CaseIterable` | `Features/History/HistorySegment.swift` |
| `OnboardingView` | Existing `reduceMotion`-gated `.animation(_:value:)` pattern to reuse verbatim | `Features/Onboarding/OnboardingView.swift:9,80` |
| `DPGlassModifier` (`.dpGlassCard()`) | Liquid Glass surface — the required look for any new callout bubble | `DesignSystem/DPGlass.swift` |
| `project.pbxproj` build settings | `GENERATE_INFOPLIST_FILE = YES` + `INFOPLIST_KEY_UILaunchScreen_Generation = YES` — **no physical `Info.plist` or storyboard exists**; launch screen is entirely synthesized from build settings | `drinkpulse.xcodeproj/project.pbxproj:419,455` |
| `AppIcon.icon` | Icon Composer (`.icon`) asset — **App Icon only**, not a usable launch-screen image source as-is | `drinkpulse/AppIcon.icon/` |

---

## Feature 1: Chart Scrubbing

### Integration points (new vs modified)

**Modified:**
- `AlcoholAreaChart.swift` — add `.chartXSelection(value:)` bound to a **view-local** `@State private var selectedKey: String?` (the chart's x-axis is a categorical `String` key, see `key(for:)`/`dateByKey`, not a raw `Date` — selection type must match the mark's `.value()` type). Resolve `selectedKey` → `ChartPoint` via the existing `dateByKey` dictionary. Add a `RuleMark` + annotation at the selected x, and a new closure parameter `onSelectionChange: (ChartPoint?) -> Void = { _ in }` so the resolved point (not the raw key) bubbles to the parent — this keeps `AlcoholAreaChart` a "pure chart view" (per its existing header comment) while still letting the hero card react.
- `WeekdayBarChart.swift` — same `.chartXSelection` pattern, but **self-contained**: no bubbling needed since nothing outside the bar chart card displays a per-bar headline. Owns its own `@State private var selectedLabel: String?` and renders its own annotation inline.
- `InsightsHeroCard.swift` — add `@State private var selectedPoint: ChartPoint?`, pass it as the `onSelectionChange` callback into `AlcoholAreaChart`. Headline `Text(vm.formattedValue(...))` switches its source value between `selectedPoint?.grams` (while scrubbing) and `vm.periodTotalGrams` (default/on release) — **do not add this state to `InsightsViewModel`**; it is transient view presentation state, not derived data, and the VM has no existing precedent for owning transient selection state (its only stored properties are `events`/`profile`/`period`/offsets, all persistence-derived or navigation state, never gesture state).
- `InsightsViewModel+Formatting.swift` — **no changes needed**. `formattedValue(_ grams: Double)` already exists and is unit/guideline-aware; both charts route their annotation text through it (passed down as a formatting closure/direct call from the owning card, never formatted inline in the chart view, per CLAUDE.md accessibility/domain rules).

**New:**
- A small reusable `DesignSystem/DPChartSelectionCallout.swift` (or similar) — a Liquid-Glass-styled annotation bubble (`.dpGlassCard(.chip)`) used by both `AlcoholAreaChart`'s `RuleMark` annotation and `WeekdayBarChart`'s bar annotation, so the two charts don't duplicate bespoke bubble styling (the todo explicitly calls out "not a bespoke bubble").
- Both chart views need a first `accessibilityChartDescriptor` implementation — **there is none in the codebase today** (confirmed via grep); this is new work, not an extension of existing code, despite the todo's "keep/extend" phrasing. Per-point values must remain reachable via VoiceOver independent of the drag gesture.
- `drinkpulseUITests/Features/Insights/InsightsChartScrubbingUITests.swift` — new UI test driving the real Insights screen (mandatory per CLAUDE.md for any user-facing behavior change); should join the existing `Features/Insights/` UI test folder alongside `InsightsUITests.swift`.

### Data flow

```
User drag on AlcoholAreaChart
    ↓
Chart's own @State (selectedKey: String?) — Swift Charts native chartXSelection
    ↓ (resolve via dateByKey)
onSelectionChange(ChartPoint?) closure
    ↓
InsightsHeroCard.@State selectedPoint
    ↓
vm.formattedValue(selectedPoint?.grams ?? vm.periodTotalGrams)   ← InsightsViewModel+Formatting (unit-aware)
    ↓
Headline Text re-renders
```

`WeekdayBarChart`'s selection loop is identical but shorter — it never leaves the chart view, since no headline outside the bar chart card needs to react.

### Reused pattern
`reduceMotion` gate for the selection/annotation animation: reuse `OnboardingView.swift:9,80`'s exact idiom — `@Environment(\.accessibilityReduceMotion) private var reduceMotion` + `.animation(reduceMotion ? nil : .spring(...), value: selectedKey)`. Do not invent a new reduce-motion pattern.

### Risk / research flag
Low. Swift Charts' native `chartXSelection` is well-trodden (iOS 17+); the only non-trivial part is the categorical-key ↔ `Date` mapping already baked into `AlcoholAreaChart`, and the new `accessibilityChartDescriptor` (first one in the codebase — budget explicit time for it, it is not a copy-paste of an existing pattern).

---

## Feature 2: History List↔Calendar Slide Transition

### Integration points (new vs modified)

**Modified:**
- `HistoryView.swift` (body, `:64-79`) — the bare `Group { switch segment { ... } }` gets `.transition(.asymmetric(insertion:removal:))` per branch plus an `.animation(_:value: segment)` (or a `withAnimation` wrap at the point `segment` is mutated). Add a new `@State private var transitionEdge: Edge = .trailing` (or equivalent), updated inside `.onChange(of: segment) { oldValue, newValue in ... }` using **`HistorySegment.allCases` index comparison** (`.list` index 0, `.calendar` index 1) to derive direction — this needs no change to `HistorySegment` itself (`CaseIterable` already gives the ordering for free).
- `HistoryView.swift`'s `segmentPickerRow` — the `Picker`'s `selection: $segment` binding currently mutates directly with no animation; wrap the mutation (or the `.onChange`) so the transition actually animates, per the todo's finding that nothing animates today "by construction."
- `HistoryView.swift`'s `emptyState` fork inside `listContent` — this is a third transition state (list-with-data / list-empty / calendar), not just two; the transition logic must account for it or the empty state will pop instead of slide.

**Not modified — explicitly kept out of the view model:**
- `HistoryViewModel.swift` — confirmed by direct read: it currently owns **zero** transient UI state (no `@State`-equivalent stored property at all; every method is a pure function taking parameters). All transient UI state for this screen (`segment`, `listWindowStart`, `monthShown`, `selectedDay`, `editingEvent`) already lives directly in `HistoryView`'s own `@State`, not in the VM. **"Previous segment" tracking should follow that exact same precedent** — it belongs in `HistoryView` as another `@State` (or is derived for free from the two-value `.onChange(of:) { old, new in }` callback), never added to `HistoryViewModel`. Introducing it into the VM would be a first-of-its-kind regression against the "stateless w.r.t. persistence" pattern's spirit (this VM is stateless full-stop today) and against `docs/architecture.md`'s "View Models Owning ModelContext" anti-pattern's underlying rationale (VMs should stay pure/testable; gesture-adjacent transient state belongs to the view that owns the gesture).

**New:**
- Likely no new files — this is a body-only change to `HistoryView.swift` plus possibly extracting the `Group`/switch into a small `Components/HistorySegmentContent.swift` if the transition logic pushes `HistoryView` toward the 300-line ceiling (worth checking after the change; `HistoryView.swift` is currently ~223 lines including two previews).
- Extend `HistoryInteractionUITests+Helpers.swift` (existing) rather than adding a new UI test file, per the todo's own suggestion — assert the **end state** (correct segment's content visible after the switch), not the animation itself (XCUITest cannot reliably assert mid-animation frames).

### Data flow

```
User taps Picker segment
    ↓
segment: HistorySegment @State mutates (List ↔ Calendar)
    ↓
.onChange(of: segment) { old, new in transitionEdge = direction(old, new) }
    ↓
Group{switch segment {...}} re-renders with .transition(.asymmetric(edge: transitionEdge))
    ↓
listContent (List, HistoryListQueryView, @Query-backed)  ⟷  calendarContent (ScrollView, HistoryCalendarQueryView)
```

### Known structural risk (flagged in the todo, confirmed by reading the view)
`listContent` resolves to a `List` (`.insetGrouped`) while `calendarContent` is a `ScrollView` — two structurally different scroll containers. Cross-fading/sliding between them is the single highest-risk part of this feature and **must be verified on a real device**, not just Preview — a Preview cannot reveal the "flash of unstyled background" or scroll-position artifacts the todo warns about. This is also why `HistoryListQueryView`'s `@Query`-driven re-fetch-on-appear timing needs a manual check (row content should not visibly pop in mid-slide).

### Risk / research flag
Medium — not because the SwiftUI API is exotic (`.transition`/`.animation` are basic), but because of the List-vs-ScrollView container mismatch, which has no clean "just works" answer and may need a fallback (e.g. crossfade instead of slide, or wrapping both in a shared outer container) discovered only by running on device.

---

## Feature 3: Branded Static Launch Screen

### Integration points

This is **not a SwiftUI or Feature-folder change at all** — confirmed: the project has `GENERATE_INFOPLIST_FILE = YES` and no physical `Info.plist`/`.storyboard` file exists anywhere in the tree. The launch screen is currently 100% synthesized from the single build setting `INFOPLIST_KEY_UILaunchScreen_Generation = YES` (present at both `project.pbxproj:419` and `:455` — Debug and Release configs for the app target).

**Modified:**
- `drinkpulse.xcodeproj/project.pbxproj` — add `INFOPLIST_KEY_UILaunchScreen_*` build settings (image name + optional background color key) at the same two lines (`:419`, `:455`) that currently only set `_Generation = YES`. This is most safely done through Xcode's target editor ("General" tab → App Icons and Launch Screen section) rather than hand-editing the pbxproj, since Xcode writes the exact key spelling/format it expects; hand-editing risks a subtly wrong key that silently falls back to blank.
- `Assets.xcassets` — add a new image set (e.g. `LaunchLogo`) holding a flattened raster/PDF export of the brand mark. **`AppIcon.icon` (the Icon Composer document) cannot be pointed to directly** — it's a multi-layer icon-authoring format for the App Icon slot only, not a static image source; the launch image must be a conventional exported PNG/PDF placed in the asset catalog. This export step is new design/asset work, not just configuration.

Because `drinkpulse` target is a `PBXFileSystemSynchronizedRootGroup` (per CLAUDE.md's testing section, confirmed for all three targets), dropping the new image set into `Assets.xcassets` on disk requires no separate manual file-registration step — only the two build-setting keys need touching.

**New:**
- One new image asset (exported from existing brand source, "consistent with the existing `AppIcon.icon` asset" per the todo — do not introduce new artwork).
- No new Swift files, no new tests in the unit/UI sense — the todo itself notes a `drinkpulseUITests` assertion on the launch screen is not meaningful (it's pre-process, pre-SwiftUI UI); if anything is pinned in a test, it should be the **first in-app screen after launch**, not the launch screen itself.

### Why this is architecturally independent of the other two
It touches zero Swift source, zero `Features/`, zero `DesignSystem/` code paths used by Features 1/2. Its only shared surface with the rest of the codebase is the `Assets.xcassets` catalog and the app-target build settings — neither of which Features 1/2 touch. It can be built, verified (real device force-quit cold launch, not simulator warm start — per the todo), and shipped in complete isolation.

---

## Suggested Build Order

All three features are mutually independent (confirmed above — no shared files, no shared VM, no shared DesignSystem component required by more than one). Recommended order is by **risk-discovery-cost**, not dependency, since there is no true dependency chain:

1. **Branded launch screen** — smallest surface area, zero Swift code, fastest to land and verify (single real-device cold-launch check). Do this first to bank an easy, low-risk win and free later attention for the two riskier items.
2. **Chart scrubbing** — medium scope but low *architectural* risk: the pattern (view-local selection `@State` + existing `InsightsViewModel+Formatting` for display) is a straightforward extension of established conventions. The one genuinely new piece — `accessibilityChartDescriptor` — has no existing precedent in the codebase, so budget dedicated time for it rather than assuming it's a copy-paste.
3. **History slide transition** — do this last. It is the smallest amount of code but carries the highest *discovery* risk (List-vs-ScrollView container mismatch can only be confirmed on a real device, and the fix, if the naive slide looks broken, is unknown until then — could range from a CSS-like tweak to a container-unification rework). Sequencing it last means any schedule slip lands on the smallest, most isolated feature, and the other two ship on time regardless of how this one goes.

If parallelized instead of sequenced: safe to build all three concurrently (different engineers/sessions) since they share no files — the only shared conventions are the `reduceMotion` idiom (Features 1 and 2) and `.dpGlassCard()` (Feature 1's new callout component), both already stable/read-only dependencies, not points of contention.

---

## Anti-Patterns to Avoid (specific to this milestone)

### Putting chart-selection state on `InsightsViewModel`
**What people might do:** add `var selectedChartPoint: ChartPoint?` to `InsightsViewModel` since it already holds `events`/`profile`/`period`.
**Why it's wrong:** every existing stored property on that VM is either persistence-derived (`events`, `profile`) or explicit period navigation state (`weekOffset`/`monthOffset`/`yearOffset`) — never transient gesture/presentation state. Mixing gesture state into the VM breaks its current 100%-computed-or-navigation-state shape and makes the VM harder to reason about/test in isolation.
**Do this instead:** view-local `@State` in the chart view (or the card that embeds it), bubbled via a plain closure — exactly as `InsightsHeroCard` already relates to `AlcoholAreaChart` (a plain-data view, no VM reference).

### Adding "previous segment" to `HistoryViewModel`
**What people might do:** add `var previousSegment: HistorySegment` to `HistoryViewModel` since it's "history-related state."
**Why it's wrong:** `HistoryViewModel` today has **zero** stored properties — it is purely a bag of pure functions. Every other piece of transient screen state (`segment`, `listWindowStart`, `monthShown`, `selectedDay`, `editingEvent`) already lives in `HistoryView`'s own `@State`. Adding this one piece of transient state to the VM while its four siblings stay in the View creates an inconsistent, split source of truth for screen state.
**Do this instead:** track it in `HistoryView`'s own `@State`, or better, derive it for free from the two-value `.onChange(of: segment) { oldValue, newValue in }` closure — no persistent "previous" field may even be needed if direction is computed once per transition and stashed only as long as the transition needs it.

### Treating the launch screen as an in-app loading state
**What people might do:** try to add a spinner, animation, or dynamic text to the launch screen to also address the "long wait" problem.
**Why it's wrong:** `UILaunchScreen` (whether storyboard-based or the modern `GENERATE_INFOPLIST_FILE` synthesized form used here) is a **static image displayed by the OS before your process/SwiftUI runtime even starts** — there is no code running, no animation possible, by platform design.
**Do this instead:** keep this feature scoped to "look branded instead of blank" only. The actual wait-time problem is a separate, already-tracked concern (`2026-07-27-async-model-container-startup-and-error-state.md`, cluster A) with its own `StartupErrorView`/`ContainerLoadState` in-app solution — don't conflate the two.

### Sliding two structurally different scroll containers naively
**What people might do:** apply `.transition(.slide)` to the `Group` and assume it "just works" the same way it would for two `VStack`s.
**Why it's wrong:** `listContent` is a `List` and `calendarContent` is a `ScrollView` — different underlying UIKit-bridged scroll machinery with different content-inset/background behavior. A naive slide risks a visible flash of unstyled background or scroll-position jump that a Preview will not surface.
**Do this instead:** verify on a real device before considering this feature done; if the naive slide looks broken, prefer a crossfade fallback (`.opacity` transition) over forcing a directional slide that fights the containers' native scroll chrome.

---

## Sources

- `.planning/codebase/ARCHITECTURE.md` (2026-07-18 codebase architecture snapshot) — HIGH confidence, first-party project doc.
- Direct reads of `drinkpulse/Features/Insights/{InsightsView,InsightsViewModel,InsightsViewModel+Charts,InsightsViewModel+Formatting,InsightsChartModels}.swift` and `Components/{AlcoholAreaChart,WeekdayBarChart,InsightsHeroCard}.swift` — HIGH confidence, current code.
- Direct reads of `drinkpulse/Features/History/{HistoryView,HistorySegment,HistoryViewModel}.swift` — HIGH confidence, current code.
- Direct read of `drinkpulse.xcodeproj/project.pbxproj` (grep for `UILaunchScreen`, `GENERATE_INFOPLIST_FILE`, `AppIcon`) — HIGH confidence, confirms no physical Info.plist/storyboard and the build-setting-only launch screen mechanism.
- `.planning/todos/pending/2026-07-26-scrub-insights-charts-for-per-point-values.md`, `2026-07-26-slide-transition-between-history-list-and-calendar.md`, `2026-07-27-branded-static-launch-screen.md` — HIGH confidence, project-owner-authored requirement source.
- CLAUDE.md (project instructions) — accessibility, file-size, testing, and stateless-VM rules cited throughout.

---
*Architecture research for: DrinkPulse v1.3 "Native Feel" milestone*
*Researched: 2026-07-28*
