# 0010 — Floating tab bar with prominent Add-Drink FAB

**Status**: draft
**Size**: medium
**Created**: 2026-05-19

## Summary

Replace the standard `TabView` with a custom bottom bar that combines the
four primary tabs (Home, Insights, History, Settings) and a large circular
gradient FAB on the right for "Add Drink". Visible on every primary screen.
Add Drink presents as a sheet (existing behaviour); the FAB is the *one*
discoverable entry point — the per-screen toolbar `+` button is removed.

## Context

- The user (transcript) explicitly noted that "the Add Drink button should
  be easy to find and tap, should be good visible". A 54pt FAB anchored in
  the tab bar beats a 28pt nav-bar `+`.
- A new **Insights** tab is added — see [[plan-0012]] for its content.
  Order: Home · Insights · History · Settings · FAB.
- Today both `DashboardView` and `HistoryView` carry their own toolbar
  "+ Add Drink" buttons. After this plan the FAB owns it.

## Scope

### In
- `Features/Shell/RootShellView.swift` — owns the tab state, renders the
  active screen + the floating bar; replaces `ContentView`.
- `Features/Shell/Components/DPBottomBar.swift` — visual bar:
  * Height 74; flat full-width background; theme-tinted glass material.
  * Four tab buttons (icon + label, filled vs outline for active).
  * 54pt circular FAB on the right with linear-gradient fill
    (`theme.gradientStart` → `theme.gradientEnd`), inner highlight,
    drop shadow.
  * `scale(0.91)` on press with spring response.
- `Tab` model + state lives in `RootShellView`. The current `TabView`
  + `Tab {}` block in `ContentView` is replaced.
- Remove toolbar "+ Add Drink" buttons in `DashboardView` and `HistoryView`.
- Add `InsightsView` placeholder (real content is in [[plan-0012]]) so the
  new tab compiles before that plan ships.

### Out
- Sheet content for Add Drink — unchanged.
- Edge gestures / iPad-specific layouts.
- Reordering tabs by user.
- Badge counts on tabs.

## Implementation steps

1. **`DPBottomBar`** — pure view, takes `selected: Tab`, `onSelect`,
   `onAddDrink`. No state of its own. Configure via
   `@Environment(\.dpTheme)`.
2. **`RootShellView`** — replaces `ContentView`; owns:
   - `@State private var tab: Tab = .home`
   - `@State private var showAddDrink = false`
3. **`Tab` enum** — `home, insights, history, settings`.
4. **Routing** — switch over `tab` in shell; each branch wraps
   `NavigationStack { screen }`.
5. **Wire FAB** — `onAddDrink` flips `showAddDrink`; `.sheet(isPresented:)`
   presents `AddDrinkView()`.
6. **Strip toolbars** — remove `+` toolbar items from `DashboardView` and
   `HistoryView`. Keep their navigation titles.
7. **InsightsView placeholder** — `Text("Insights")` and TODO comment
   pointing to [[plan-0012]].
8. **Persist tab choice**: do NOT persist — fresh launch starts on Home
   (matches design).
9. **Accessibility**:
   - Each tab button labelled e.g. "Home tab, selected" / "not selected".
   - FAB labelled "Add drink".
   - `AccessibilityTraits.isSelected` on the active tab.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/Shell/RootShellView.swift` | Create |
| `drinkpulse/Features/Shell/Components/DPBottomBar.swift` | Create |
| `drinkpulse/Features/Shell/Tab.swift` | Create |
| `drinkpulse/ContentView.swift` | Delete (replaced by RootShellView) |
| `drinkpulse/drinkpulseApp.swift` | Modify (use RootShellView) |
| `drinkpulse/Features/Dashboard/DashboardView.swift` | Modify (strip toolbar) |
| `drinkpulse/Features/History/HistoryView.swift` | Modify (strip toolbar) |
| `drinkpulse/Features/Insights/InsightsView.swift` | Create (placeholder) |

## Open questions

- [ ] **Q1 — Should the bar overlay or push content?**
  - A) In-flow (content sits above; bar consumes layout height) (default —
       matches design's later iteration)
  - B) Overlay with safe-area inset on screens

- [ ] **Q2 — Hide bar in modal sheets?** The Add Drink sheet should overlay
  the bar (covers it). Confirm full-screen sheets keep system behaviour
  (system hides nav/tab bars automatically).
  - A) Yes — sheet always covers the bar (default)

- [ ] **Q3 — Tab icons**: use SF Symbols `house` / `chart.bar` /
  `clock` / `gearshape` with `.fill` variants for active?
  - A) Yes (default — matches iOS 26 convention)

- [ ] **Q4 — Tab count and order**: four tabs leaves no room for a future
  fifth (e.g. BAC). Acceptable, or reserve slot now?
  - A) Four tabs; route any future feature into Settings or a card on
       Dashboard (default)
  - B) Five tabs from day one — would push FAB into a centred position

## Tests required

- ViewModel-less feature; cover via Previews and a UI test that confirms
  FAB tap presents Add Drink.
- Snapshot of bar in light + dark with all three themes.

## Future links

- [[plan-0007]] — glass material on the bar.
- [[plan-0008]] — gradient comes from the active theme.
- [[plan-0012]] — Insights tab populated.
- Apple Watch glance — separate idea on roadmap; bar layout unaffected.
