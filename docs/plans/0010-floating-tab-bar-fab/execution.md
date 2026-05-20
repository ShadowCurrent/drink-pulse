# 0010 — Execution Journal

_Append-only. Newest entries at the bottom._

---

## 2026-05-20 — Initial implementation

**Open questions resolved before freeze:**
- Q1: in-flow via `.safeAreaInset(edge: .bottom)`.
- Q2: sheets cover bar automatically.
- Q3: SF Symbols `.fill` variant when active.
- Q4: four tabs, no reserved fifth slot.

**Files created:**
- `Features/Shell/Tab.swift` — `AppTab` enum with `label`, `icon`, `activeIcon`.
- `Features/Shell/Components/DPBottomBar.swift` — bar + `TabItemButton` + `AddDrinkFAB` + `SpringButtonStyle`. Bar background uses `.bar` Material on iOS 26 / `.ultraThinMaterial` + top Divider on iOS 18; background extended into safe area via `.ignoresSafeArea(edges: .bottom)`.
- `Features/Shell/RootShellView.swift` — `@ViewBuilder switch` over `AppTab`; `.safeAreaInset` for the bar; single `showAddDrink` sheet.
- `Features/Insights/InsightsView.swift` — placeholder `ContentUnavailableView` pending plan-0012.

**Files modified:**
- `DashboardView.swift` — removed `showAddDrink` state, toolbar item, and sheet.
- `HistoryView.swift` — same.
- `drinkpulseApp.swift` — `ContentView()` → `RootShellView()`.
- `Localizable.xcstrings` — added `tab.insights`, `insights.comingSoon.title/description` (en/de/pl).

**Deviation from plan:** `ContentView.swift` kept (not deleted) since it still has a Preview; removing it is a cosmetic-only change that requires project.pbxproj edits — deferred.

**Note on tab state:** `@ViewBuilder switch` recreates each `NavigationStack` on tab change (no state preservation). Acceptable for v1; upgrade to `opacity + allowsHitTesting` pattern if deep navigation becomes common.

**Build:** clean. **Tests:** 127/127 passing.
