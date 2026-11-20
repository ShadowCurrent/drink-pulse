# 0042 — Execution Log

Append-only. Never edit or delete previous entries.

---

## 2026-11-20 — Tasks 1–5 executed (superpowers `executing-plans`, inline)

Branch `port/0042-design-tokens`, commits `6045e12` … `7d164ef`. Simulator only (iPhone 18 Pro,
iOS 27.2), all builds and tests through Xcode MCP (`RunSomeTests`, `BuildProject`,
`GetBuildLog`, `RenderPreview`). No CLI `xcodebuild`.

### Done
- **Task 1 — one risk palette** (`6045e12`). `RiskLow` / `RiskModerate` / `RiskHigh` Light
  appearances set to the former `RiskText*` Light values; Dark unchanged. `RiskText*` colour sets
  deleted. `RiskLevel+Color.swift` → `RiskLevel+Tone.swift` with `nonisolated var tone`.
  `dpRisk*` / `dpRiskText*` statics removed; every `.color` / `.chartColor` / `.textColor` /
  `Color.dpRisk*` call site now reads `.tone` / `RiskLevel.<case>.tone`.
  `RiskToneTests` (12 cases) RED (`tone` undefined) → GREEN; `RiskLevelTests` green.
- **Task 2 — Frost palette, tint, card surface** (`5464967`). `AccentColor` Light `#2F6CC2`,
  Dark `#3F86E8`. `Brand.swift` (accent, ink, heroMesh, tintFraction, surfaceFraction),
  `BrandBackground.swift` (BrandBackdrop, BrandSurface, three modifiers, Light/Dark previews).
  `DPBrand.swift` deleted; 4 `Color.dpAccent` call sites → `Brand.accent`. `BrandTests`
  (13 cases) RED → GREEN.
- **Task 3 — card style and typography** (`f9c43c2`). `BrandCardStyle.swift` (`CardMetrics`
  24 / 16, `BrandCardStyle`, previews Light / Dark / AX5), `BrandTypography.swift` (`CardTitle`,
  `brandNavigationTitle`), `brandBackground()` now applies `BrandCardStyle`.
  `CardMetricsTests` RED → GREEN; previews rendered.
- **Task 4 — animatable arc** (`3bef22c`). `ArcShape` internal, `var from/to`,
  `animatableData` = `to`; `DPArcProgress.trackOpacity` 0.2 / 0.4 under Increase Contrast.
  `ArcShapeTests` RED → GREEN; `DashboardUITests` 5/5.
- **Task 5 — gates, audit, docs.** `docs/architecture.md`: new "Design system" section, audit
  policy in "Accessibility and motion". Old Today badge fix (`7d164ef`, see Deviations).
  Scoped run: `RiskToneTests`, `BrandTests`, `CardMetricsTests`, `ArcShapeTests`,
  `RiskLevelTests`, `DPMotionTests`, `DashboardViewModelTests`, `DashboardUITests`,
  `InsightsUITests` → 132/132 passed. Build: 0 warnings. No Swift file over 300 lines. No
  logging, network or `try!` added.
  Coverage (MCP xcresult, `xccov`): `Brand.swift` 100 % (23/23), `RiskLevel+Tone.swift` 100 %
  (7/7), `DPArcProgress.swift` 96.3 % (only the pre-existing view default initialisers of
  `size` / `strokeWidth`); the three new view files are excluded (layout).

### API sources (Xcode MCP `DocumentationSearch`, SwiftUI, iOS 27.2 SDK)
- `Color.resolve(in:)` / `Color.Resolved` — test helpers resolve tokens per `colorScheme`.
- `EnvironmentValues.colorScheme` / `colorSchemeContrast`, `ColorSchemeContrast.increased` —
  docs note: per-appearance / per-contrast colours belong in the asset catalog (used for the
  palette).
- `Color.mix(with:by:in:)` — tint and surface (default `.perceptual`).
- `View.containerBackground(for:alignment:content:)`, `ContainerBackgroundPlacement.navigation`
  — fills the enclosing `NavigationStack`.
- `scrollContentBackground(_:)`, `listRowBackground(_:)` — list screens.
- `GroupBoxStyle.makeBody(configuration:)` — card style.
- `ToolbarItemPlacement.largeTitle` — "A placement for items in the navigation bar's title area".
- `Animatable.animatableData` — manual conformance for a derived value (only `to` animates).

### Deviations from plan
- Call sites outside the plan's list also read `.color`: `ThisWeekCard.swift:60`,
  `HistoryViewModel.swift:137` → `.tone`.
- `RiskLevel.tone`, `Brand`, `CardMetrics`, `DPArcProgress.trackOpacity` are `nonisolated`
  (the target's default isolation is `MainActor`; tests and Charts read them off the main actor).
- `Brand.accent = Color("AccentColor")`, not `Color.accentColor`: `accentColor` resolved outside
  a view returned system blue `#0088FF` (`BrandTests` RED). The named asset is the same colour
  the system uses as global accent (`ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`).
- `BrandSurface` always mixes by `Brand.surfaceFraction` (0 in Light and under Increase
  Contrast) instead of the prototype's `if` / `else`.
- `brandBackground()` got `.groupBoxStyle(BrandCardStyle())` in Task 3, not Task 2 (the style
  did not exist yet).
- Audit: all 8 ungated classes run, not 7. New failure found and fixed: Dashboard Dark
  `contrast` on "113%" (the exceeded badge). The Dark exceeded tone (1.00 / 0.33 / 0.30) is
  darker than the old `RiskTextHigh` Dark (1.00 / 0.45 / 0.43); under the badge's 15 % risk fill
  on the glass card it fell below 4.5:1. Fix in `ConsumptionOverviewCard`: risk-coloured outline
  instead of the fill; palette unchanged. After the fix Dashboard Dark passes.
- `DPArcProgress` body left unchanged (fill still under `if pct > 0`, first change after appear
  unanimated through `hasSettledOnce`): Task 4 scopes only `animatableData` and the track. The
  first-log sweep from 0 is left to the owner device check; the hero is redesigned in step 6.

### Discoveries
- Audit on the branch vs the pre-0042 commit `e074f2f` (same simulator, same day):
  Dashboard standard (header subtitle) and Insights standard / dark (`dynamicType` stat tiles)
  unchanged from the baseline; Onboarding standard now **passes** (Frost "Get Started").
  History standard / dark / ax5 and HistorySearch standard / ax5 fail identically on
  `e074f2f` (not in the first baseline, which ran only 3 classes). History ax5 `dynamicType`
  (`none#type=nil` ×4) is intermittent: it moves between the two ax5 tests across runs, and
  fails on `e074f2f` too.

### Open questions updated
- Updated: "Accessibility audit failures on the old UI" — History / HistorySearch failures
  added as pre-existing (cleared by step 5); Onboarding now passes.
- New: "Increase Contrast variants for the accent and risk colours" (owner decision 2026-11-20:
  later).

---

## 2026-11-20 — Final whole-branch review and fix pass

### Done
- Fresh reviewer on `e074f2f..7d164ef`: 0 critical, 3 important, 5 minor.
- **Fixed — arc first log jumped** (review focus 4). Two causes: the fill arc was inserted at
  `pct > 0` (no `to` change to interpolate), and `hasSettledOnce` was set in `onChange`, after
  the first change. Now the fill arc is always in the tree, hidden by
  `DPArcProgress.fillOpacity(_:)` at 0, and `hasSettledOnce` is set in `.task` (after the first
  frame). `test_fillOpacity_hidesFillOnlyAtZero` RED (undefined) → GREEN; `DashboardUITests`,
  `ProbeAccessibilityAuditUITests`, `DashboardAccessibilityAuditUITests` (only the baseline
  header-subtitle failure) green. Sweep itself: owner device check.
- **Not reproduced — hero "High Risk" label in Dark**: new
  `DashboardOverLimitAccessibilityAuditUITests` logs a beer through Add Drink to push today
  over the limit and audits Dark; it passes. Label unchanged; the test stays as a guard.
- Close-out docs committed (this entry, retrospective, INDEX, DEVLOG, current-focus,
  open-questions, architecture.md).

### Deferred minors (old UI replaced in later steps, or cosmetic)
- `ConsumptionOverviewCard` `color` / `textColor` are now the same expression.
- `ThisWeekCard` no-limit fallback still `.dpGreen`.
- `HistorySearchField.swift:30` comment still names the ember accent.
- Preview-only strings extracted into `Localizable.xcstrings` as empty entries.
- `RiskToneTests` light-contrast test name says "NonText" but asserts the 4.5:1 text threshold.
