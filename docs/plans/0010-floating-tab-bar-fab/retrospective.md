# 0010 — Retrospective

**Completed**: 2026-05-20
**Status**: completed

## What was built

`AppTab` enum with SF Symbol icon names and localized labels. `RootShellView`
owning tab state and sheet presentation via `.safeAreaInset(edge: .bottom)`.
`DPBottomBar` — floating glass capsule pill (4 tabs) + detached 64pt gradient
FAB. `InsightsView` placeholder. Toolbar `+` stripped from `DashboardView` and
`HistoryView`.

## What changed vs the plan

**Design pivot during implementation:** The original plan described a
full-width flat tab bar using `.bar` Material background (standard iOS tab bar
aesthetic). After reviewing the Claude Design bundle's HTML source, the user
confirmed they wanted the native iOS 26 Liquid Glass look: a floating capsule
pill + a detached circle FAB — both floating at `bottom: 14`. DPBottomBar was
rewritten accordingly.

**Specific changes from plan:**
- `glassEffect(.regular, in: Capsule())` on the pill (iOS 26) vs
  `ultraThinMaterial + strokeBorder` fallback (iOS 18).
- FAB size bumped to 64pt (plan said 54pt) to match design.
- Tab switch uses `@ViewBuilder switch` (no state preservation) rather than
  `ZStack + opacity` — simpler for v1, acceptable tradeoff documented.
- `ContentView.swift` not deleted — deferred (cosmetic-only, needs pbxproj
  edit, not worth the churn).

## What worked well

- **`glassEffect(.regular, in: Capsule())`** is a single call for full iOS 26
  Liquid Glass on the pill; fallback `ultraThinMaterial + shadow` looks nearly
  identical on iOS 18. The `#available(iOS 26, *)` branch is clean and minimal.
- **Detached FAB layout** (`HStack(spacing: 10)` pill + FAB, full-width
  horizontal padding) is simple and requires no absolute positioning.
- **SpringButtonStyle** (`scaleEffect(0.91)` on press) gives the FAB tactile
  feedback with 3 lines of code.
- Visual QA via Previews: Ember light ✓, Iris dark ✓.

## What could be better

- `@ViewBuilder switch` recreates each `NavigationStack` on every tab change.
  Deep navigation state is lost. Acceptable v1 tradeoff; upgrade to
  `ZStack + allowsHitTesting(false)` if deep navigation becomes common.
- The tab pill has no explicit width — it sizes to content. If a future locale
  produces longer labels, the pill could overflow the available space before
  the FAB. Worth monitoring when adding more localisations.

## Tests

No new view-model logic in this plan. All 127 project tests pass.
