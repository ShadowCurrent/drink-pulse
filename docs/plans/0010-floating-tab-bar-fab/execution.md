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

---

## 2026-05-20 — Design pivot: flat bar → glass pill + detached FAB

**Context:** After reviewing the Claude Design bundle (`DrinkPulse.html`), the original flat full-width `.bar` Material bar was replaced with the design's specified layout: a floating glass capsule pill (4 tabs) + a separate 64pt gradient circle FAB to the right, both pinned at `bottom: 14` from the screen edge.

**DPBottomBar rewrite:**
- Outer `HStack(spacing: 10)` with `.padding(.horizontal, 16).padding(.bottom, 14)`.
- `tabPill`: `pillContent.glassEffect(.regular, in: Capsule())` on iOS 26; `.ultraThinMaterial` + `Capsule` stroke border + shadow on iOS 18 fallback.
- `TabItemButton`: `minWidth: 54`, active background `RoundedRectangle(cornerRadius: 18).fill(activeColor.opacity(0.12/0.16 dark))`, `VStack(spacing: 1)` icon + label.
- `AddDrinkFAB`: 64pt `Circle` filled with `theme.gradient`, inner white highlight overlay, `primary.opacity(0.40)` colored shadow + black shadow; `SpringButtonStyle` (scale 0.91 on press).
- `fallbackPillBackground`: `Capsule().fill(.ultraThinMaterial)` + `0.5pt` stroke + shadow — identical visual weight as iOS 26 glass on iOS 18.

**RootShellView:** unchanged — `.safeAreaInset(edge: .bottom)` continues to host the bar.

**Build:** clean. **Tests:** 127/127 passing (via `-only-testing:drinkpulseTests`).
