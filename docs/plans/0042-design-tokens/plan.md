# 0042 — Port step 2: design tokens

**Status**: in-progress
**Size**: medium
**Created**: 2026-11-20
**Frozen**: 2026-11-20
**Programme**: [0040 — Native UI port](../0040-native-ui-port/plan.md), step 2
**Branch**: `port/0042-design-tokens` (from `ui-revamp` at `aeade12`; `main` already merged)

> Execution: superpowers `executing-plans`, inline, one session (owner workflow, plan 0040
> "Workflow"). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the accepted design tokens (Frost palette and tint, one risk palette, one card
style, rounded typography, an animatable arc) to `DesignSystem/`, switch the app's risk and
accent colours to them, and write the design rules and the audit policy into
`docs/architecture.md`, so steps 3–8 port each screen once, on the final look.

**Architecture:** Tokens live in `DesignSystem/` as small value types, view modifiers and
asset colour sets. Every appearance-dependent decision that is not a colour lookup is a pure
static function (tint fraction, card surface fraction, hero ink, arc track opacity), so it is
unit tested without rendering. Screens adopt the new card, tint and title helpers in their own
port steps; this step only swaps the colour sources that every screen already reads (accent,
risk). No Domain logic, persistence, service or view-model change; no schema change.

**Tech stack:** SwiftUI (`GroupBoxStyle`, `Color.mix(with:by:in:)`,
`containerBackground(for: .navigation)`, `scrollContentBackground(.hidden)`,
`listRowBackground`, `ToolbarItemPlacement.largeTitle`, `Animatable`), asset catalog colour
sets, Swift Testing.

**Spec:** plan 0040 ("Decisions carried into the port → Visual design", step 2,
"Accessibility audit policy", "Documentation"); prototype
`~/Developer/drinkpulse-native-proto/DrinkPulseNativeProto/DrinkPulseNativeProto/Components/`
(`Brand.swift`, `BrandBackground.swift`, `BrandCard.swift`, `BrandTypography.swift`,
`riskTone` in `CardComponents.swift`); FINDINGS rounds 4, 5c–5d, 8–12, 15, 16.

## Summary

Step 2 of the native UI port. The prototype's tokens move into the app's `DesignSystem/`.
Two colour sources change app-wide at once, on the old UI too: the accent (ember `#FA5D36` →
Frost `#2F6CC2` Light / `#3F86E8` Dark, via `AccentColor`) and the risk colours (three fill
sets + three text sets → one tone per level). The other tokens (tint, card style, typography)
are added with previews and tests but are applied by the screen steps. `ArcShape` gets
`animatableData`, which fixes the jumping hero sweep in the current app. The design rules
(native components, no Liquid Glass on content, one card style, one risk palette, tint on every
screen, rounded headings) and the round-21 audit policy go into `docs/architecture.md`.

## Context

- Current tokens (read 2026-11-20): `DPBrand.swift` (`Color.dpAccent = .accentColor`),
  `AccentColor` = ember `#FA5D36`, one appearance; `DPColors.swift` (five fixed hues);
  `DPSemanticColors.swift` (`dpRiskLow/Moderate/High`, `dpRiskTextLow/Moderate/High`,
  `dpSecondaryText`); `RiskLevel+Color.swift` (`color` → fixed hues, `chartColor` → `Risk*`,
  `textColor` → `RiskText*`); `DPArcProgress.swift` (`ArcShape` with `let from/to`, no
  `animatableData`); `DPLargeTitle.swift` (28 pt bold).
- The prototype's `riskTone` is exactly the app's `RiskText*` Light values plus the app's
  `Risk*` Dark values (checked component by component):

  | Level | Light | Dark |
  |------|-------|------|
  | safe | 0.11 / 0.42 / 0.14 (`RiskTextLow` light) | 0.30 / 0.75 / 0.32 (`RiskLow` dark) |
  | caution | 0.62 / 0.30 / 0.00 (`RiskTextModerate` light) | 1.00 / 0.68 / 0.20 (`RiskModerate` dark) |
  | exceeded | 0.72 / 0.12 / 0.12 (`RiskTextHigh` light) | 1.00 / 0.33 / 0.30 (`RiskHigh` dark) |

  So the one palette is three asset colour sets, not code: asset colours resolve per
  appearance in the system, are `Sendable`-safe off the main thread (the prototype's
  `UIColor` provider trap, FINDINGS "Bug … crash when paging Insights periods"), and can take
  Increase Contrast variants later.
- Risk thresholds: the prototype's 75 % / 100 % are placeholders (plan 0040). The app's real
  levels stay: `RiskLevel.from(pct:)` = safe `< 0.5`, caution `<= 1.0`, exceeded `> 1.0`.
  `riskTone` is keyed on `RiskLevel`, not on a fraction.
- Audit baseline on the old UI: open-questions, "Accessibility audit failures on the old UI"
  (4 known failures in Dashboard and Insights). Rule: old-UI failures are not fixed; this step
  must not add new ones.

## Decisions (this plan)

- **D0042-1 — Risk palette in the asset catalog.** `RiskLow`, `RiskModerate`, `RiskHigh` get
  the table values above; `RiskTextLow/Moderate/High` are deleted. API: `RiskLevel.tone:
  Color`; `color`, `chartColor`, `textColor` are removed. Non-risk call sites that borrowed a
  risk colour (Insights area chart, Health Impact icons, notes counter) map to the matching
  `RiskLevel.<case>.tone` unchanged in meaning; their screen steps (6, 7) give them the
  accent or natural icon colours.
- **D0042-2 — Accent in the asset catalog.** `AccentColor` gets Light `#2F6CC2`
  (0.184 / 0.424 / 0.761) and Dark `#3F86E8` (0.247 / 0.525 / 0.910). `Brand.accent =
  Color.accentColor`; `Color.dpAccent` and `DPBrand.swift` are removed (4 call sites).
- **D0042-3 — Hero ink and mesh are tokens now** (`Brand.ink(for:)`, `Brand.heroMesh(for:)`),
  used from step 6. Keeps the whole Frost palette in one file.
- **D0042-4 — Unchanged in this step:** `DPColors.swift` fixed hues, `dpSecondaryText`,
  `DPGlass.swift`, `DPLargeTitle.swift`. Each goes in the step that ports its last caller,
  or in step 11 (cleanup). Per "no fixes to replaced UI", old screens keep their glass and
  layout; only the accent and risk colours change under them.

## Scope

### In
- Frost palette, tint backdrop, card surface, list helpers (`Brand`, `BrandBackdrop`,
  `BrandSurface`, `brandBackground()`, `brandListBackground()`, `brandRowBackground()`).
- `CardMetrics` + `BrandCardStyle`.
- `RiskLevel.tone` + asset changes + call-site swap.
- `ArcShape` `animatableData`; arc track opacity 0.2 → 0.4 under Increase Contrast.
- `CardTitle`, `brandNavigationTitle(_:)`.
- `docs/architecture.md`: "Design system" section (rules) + audit policy in "Accessibility
  and motion".

### Out
- Applying cards, tint or rounded titles to any screen (steps 3–8).
- Hero redesign, status glyph `toneCutOut`, calendar marks (steps 5, 6).
- Removing glass, `dpSecondaryText`, `DPColors`, `DPLargeTitle` (later steps / step 11).
- Bar-control audit exemption helper (step 4).
- Increase Contrast colour variants for accent / risk (not prototyped; open question).

## Global constraints

- Simulator only (iPhone 18 Pro, iOS 27.2) through Xcode MCP; never the physical device.
  `XcodeListWorkspaces` → `workspaceIdentifier` first; `XcodeListRunDestinations` before
  every test call.
- Apple docs via Xcode MCP `DocumentationSearch` before each API use; record source and
  availability in `execution.md`. APIs to look up: `GroupBoxStyle`, `Color.mix(with:by:in:)`,
  `View.containerBackground(_:for:)` / `ContainerBackgroundPlacement.navigation`,
  `scrollContentBackground(_:)`, `listRowBackground(_:)`, `ToolbarItemPlacement.largeTitle`,
  `Animatable.animatableData`, `Color.resolve(in:)`, `ColorSchemeContrast`, asset catalog
  colour appearances.
- Swift 6 strict concurrency, zero warnings. `ArcShape` stays `nonisolated`.
- Files under 300 lines; one concept per file; previews for every new view.
- New tests: Swift Testing, in `drinkpulseTests/DesignSystem/`.

## Review focus

1. **Contrast regressions on the old UI** — the blue accent and darker Light risk tones sit on
   glass cards; expected: no audit finding that is not in the baseline. Pinned by running the
   7 ungated audit classes (Task 5).
2. **Off-main colour resolution** — Swift Charts resolves colours off the main actor; expected:
   no isolation trap when paging Insights. Pinned by asset colours (no closure) and by
   `InsightsUITests` in the scoped run.
3. **Dark mode values** — a wrong appearance entry in an asset is invisible in Light tests;
   pinned by resolving every tone and the accent in both schemes (Task 1, Task 2).
4. **Arc animation from 0** — the arc's fill is hidden at `pct == 0`; expected: first log
   animates from empty, not a jump. Pinned by the `animatableData` test plus the device check.
5. **Increase Contrast** — tint and dark card mix must drop to 0; pinned by the fraction tests.

---

### Task 1: One risk palette

**Files:**
- Modify: `drinkpulse/Assets.xcassets/RiskLow.colorset/Contents.json`,
  `RiskModerate.colorset`, `RiskHigh.colorset` (Light = table values; Dark unchanged)
- Delete: `drinkpulse/Assets.xcassets/RiskText{Low,Moderate,High}.colorset`
- Rename/modify: `drinkpulse/DesignSystem/RiskLevel+Color.swift` → `RiskLevel+Tone.swift`
- Modify: `drinkpulse/DesignSystem/DPSemanticColors.swift` (keep only `dpSecondaryText`)
- Modify call sites: `Features/Dashboard/DashboardView.swift:126`,
  `Dashboard/Components/DashboardHeroCard.swift:49,65,93`,
  `Dashboard/Components/ConsumptionOverviewCard.swift:49`,
  `Insights/Components/WeekdayBarChart.swift:77`, `GuidelineComparisonCard.swift:49`,
  `InsightsHeroCard.swift:116`, `HealthMetricsCard.swift:22,65,73`,
  `AlcoholAreaChart.swift:38,47,65`, `History/Components/EditNotesSection.swift:26`
- Test: `drinkpulseTests/DesignSystem/RiskToneTests.swift`, helper
  `drinkpulseTests/DesignSystem/ContrastRatio.swift`

**Interfaces:**
- Produces: `extension RiskLevel { var tone: Color }`; test helper
  `func contrastRatio(_ a: Color.Resolved, _ b: Color.Resolved) -> Double` (WCAG 2.x relative
  luminance) and `func resolved(_ color: Color, _ scheme: ColorScheme) -> Color.Resolved`
  (`EnvironmentValues` with `colorScheme` set).

- [ ] **Step 1: Write the failing tests**
  - `test_tone_light_matchesPalette` / `test_tone_dark_matchesPalette` — parameterised over the
    three levels; resolved RGB equals the table within 0.005.
  - `test_tone_light_meetsNonTextContrastOnWhiteCard` — every level ≥ 4.5:1 against
    `#FFFFFF` (Light tones double as text).
  - `test_tone_dark_meetsContrastOnDarkCard` — every level ≥ 4.5:1 against the Dark card
    (`secondarySystemGroupedBackground` Dark `#1C1C1E` mixed 7 % with `#3F86E8`).
- [ ] **Step 2: Run** `RiskToneTests` via `RunSomeTests` — expected FAIL (`tone` undefined).
- [ ] **Step 3: Implement** `tone` (switch over the three `Color("Risk…")`), update the three
  assets, delete the `RiskText*` sets and `dpRiskText*` / `dpRisk*` statics, swap call sites
  (`.color` / `.chartColor` / `.textColor` / `Color.dpRisk*` → `.tone` /
  `RiskLevel.<case>.tone`).
- [ ] **Step 4: Run** `RiskToneTests`, `RiskLevelTests` — PASS; build zero warnings.
- [ ] **Step 5: Commit** `[plan-0042] one risk palette: RiskLevel.tone`.

### Task 2: Frost palette, tint and card surface

**Files:**
- Modify: `drinkpulse/Assets.xcassets/AccentColor.colorset/Contents.json` (add Dark appearance)
- Create: `drinkpulse/DesignSystem/Brand.swift` (replaces `DPBrand.swift`, deleted)
- Create: `drinkpulse/DesignSystem/BrandBackground.swift`
- Modify call sites of `Color.dpAccent`: `Settings/Components/WeeklySummarySection.swift:105`,
  `ReminderSection.swift:127`, `HealthSection.swift:140`, `Shell/RootShellView.swift:21`
- Test: `drinkpulseTests/DesignSystem/BrandTests.swift`

**Interfaces:**
- Produces:
  - `enum Brand { static let accent: Color; static func ink(for: ColorScheme) -> Color;
    static func heroMesh(for: ColorScheme) -> [Color]; static func tintFraction(scheme:
    ColorScheme, contrast: ColorSchemeContrast) -> Double; static func surfaceFraction(scheme:
    ColorScheme, contrast: ColorSchemeContrast) -> Double }`
  - `struct BrandBackdrop: View`, `struct BrandSurface: View`
  - `extension View { func brandBackground() -> some View; func brandListBackground() -> some
    View; func brandRowBackground() -> some View }` (bodies as the prototype's
    `BrandBackground.swift`, reading the two fraction functions).
- Values (prototype, FINDINGS 5c–5d): ink Light `#0C1B3A`, Dark white; mesh = the prototype's
  nine Light / nine Dark hex stops; tint 0.06 Light / 0.18 Dark / 0 under `.increased`;
  surface 0.07 Dark / 0 Light / 0 under `.increased`.

- [ ] **Step 1: Write the failing tests**
  - `test_accent_resolvesFrost_inBothSchemes` (`#2F6CC2` / `#3F86E8`, ±0.005).
  - `test_accent_light_meetsTextContrastOnWhite` (≥ 4.5:1).
  - `test_tintFraction` parameterised: (light, standard) 0.06; (dark, standard) 0.18;
    (light, increased) 0; (dark, increased) 0.
  - `test_surfaceFraction` parameterised: (dark, standard) 0.07; others 0.
  - `test_ink_light_isNavy_andMeetsContrastOnEveryLightMeshStop` (≥ 7:1, FINDINGS 5);
    `test_ink_dark_isWhite_andMeetsContrastOnEveryDarkMeshStop` (≥ 4.5:1).
  - `test_heroMesh_hasNineStops_inBothSchemes`.
- [ ] **Step 2: Run** `BrandTests` — FAIL.
- [ ] **Step 3: Implement** `Brand.swift`, `BrandBackground.swift` (previews: a GroupBox on
  `brandBackground()` and a `List` on `brandListBackground()`, Light + Dark), accent asset,
  call-site swap, delete `DPBrand.swift`.
- [ ] **Step 4: Run** `BrandTests` — PASS; build zero warnings.
- [ ] **Step 5: Commit** `[plan-0042] Frost palette, tint and card surface`.

### Task 3: Card style and rounded typography

**Files:**
- Create: `drinkpulse/DesignSystem/BrandCardStyle.swift` (`CardMetrics` + `BrandCardStyle`)
- Create: `drinkpulse/DesignSystem/BrandTypography.swift` (`CardTitle`,
  `brandNavigationTitle(_:)`)
- Test: `drinkpulseTests/DesignSystem/CardMetricsTests.swift`

**Interfaces:**
- Consumes: `BrandSurface` (Task 2).
- Produces: `enum CardMetrics { static let cornerRadius: CGFloat = 24; static let padding:
  CGFloat = 16 }`; `struct BrandCardStyle: GroupBoxStyle`; `struct CardTitle: View {
  init(_ text: LocalizedStringKey) }` (`.system(.headline, design: .rounded)`);
  `extension View { func brandNavigationTitle(_ title: LocalizedStringKey) -> some View }`
  (`navigationTitle` + `ToolbarItem(placement: .largeTitle)` rounded bold `.largeTitle`).
  Figures use `.fontDesign(.rounded)` + `.monospacedDigit()` inline; no helper (rule in
  architecture.md).

- [ ] **Step 1: Write the failing test** `test_cardMetrics_matchListSectionCorner` —
  `cornerRadius == 24`, `padding == 16` (pins the owner's value; comment cites FINDINGS
  round 11 and the "re-check after each major iOS release" note).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** both files from the prototype, with previews (cards Light / Dark,
  AX5; a `NavigationStack` with `brandNavigationTitle`).
- [ ] **Step 4: Run** — PASS; `RenderPreview` both files, Light and Dark.
- [ ] **Step 5: Commit** `[plan-0042] BrandCardStyle, CardMetrics, rounded typography`.

### Task 4: Animatable arc

**Files:**
- Modify: `drinkpulse/DesignSystem/DPArcProgress.swift` (`ArcShape` → `internal`, `var to`,
  `animatableData`; track opacity via a static function)
- Test: `drinkpulseTests/DesignSystem/ArcShapeTests.swift`

**Interfaces:**
- Produces: `nonisolated struct ArcShape: Shape { var from: Double; var to: Double; var
  animatableData: Double }` (animates `to`); `static func DPArcProgress.trackOpacity(_
  contrast: ColorSchemeContrast) -> Double` (0.2 standard, 0.4 increased).

- [ ] **Step 1: Write the failing tests**
  - `test_animatableData_readsAndWritesTo` — set 0.7 on `ArcShape(from: 0, to: 0.3)` →
    `to == 0.7`, `animatableData == 0.7`.
  - `test_path_changesWithAnimatableData` — path bounding rect for `to = 0.3` differs from
    `to = 0.7` in a 100×100 rect.
  - `test_trackOpacity` — 0.2 / 0.4.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement**; arc colour stays the caller's (`RiskLevel.tone` after Task 1).
- [ ] **Step 4: Run** `ArcShapeTests`, `DashboardUITests` — PASS.
- [ ] **Step 5: Commit** `[plan-0042] ArcShape animatableData, contrast track`.

### Task 5: Gates, audit check, docs

**Files:**
- Modify: `docs/architecture.md` (new "Design system" section after "Folder layout"; audit
  policy appended to "Accessibility and motion")
- Modify: `docs/plans/0042-design-tokens/execution.md` (create), `docs/plans/INDEX.md`,
  `docs/plans/0040-native-ui-port/plan.md` (freeze per its "Documentation" rule), `docs/DEVLOG.md`,
  `.claude/context/current-focus.md`, `.claude/context/open-questions.md`, `.planning/ROADMAP.md`
  if it lists the port; README / PROJECT.md only if they name the ember accent or glass cards
  as current design (grep first).

- [ ] **Step 1:** Write "Design system" in `docs/architecture.md`: system components first;
  no Liquid Glass on content (HIG Materials), glass only in bars/controls; cards = `GroupBox`
  + `BrandCardStyle`, `CardMetrics.cornerRadius` for hero and every card; Frost accent
  (`AccentColor`, `Brand.accent`) only for primary action, selection and amount charts, never
  risk; one risk palette `RiskLevel.tone` for every risk mark and text, never colour alone;
  tint on every screen (`brandBackground()` / `brandListBackground()` +
  `brandRowBackground()`, sheets too), Increase Contrast removes it; icons keep natural
  colours, one colour per concept; rounded SF on figures, large titles, card titles only;
  appearance-dependent colours are asset sets or `@Sendable` providers. Audit policy (plan 0040
  round 21): bar-control `dynamicType` / `textClipped` exemption per call by identifier key
  (helper arrives in step 4), segmented controls in content get an AX-size alternative, audit
  rebuilt per ported screen, old-UI failures not fixed.
- [ ] **Step 2: Build** zero warnings (`BuildProject`, then `GetBuildLog` warnings).
- [ ] **Step 3: Scoped tests** — `RiskToneTests`, `BrandTests`, `CardMetricsTests`,
  `ArcShapeTests`, `RiskLevelTests`, `DPMotionTests`, `DashboardViewModelTests*`,
  `DashboardUITests`, `InsightsUITests`, and the 7 ungated audit classes. Expected: all green
  except the 4 baseline audit failures, with the same element keys as the baseline (a key that
  changes text only through the new colours counts as baseline; any new element or audit type
  is a regression → fix in this task).
- [ ] **Step 4: Coverage** — `DesignSystem/` new files at 100 % of testable lines (views
  excluded).
- [ ] **Step 5: File size** find command; privacy review (no logging added).
- [ ] **Step 6: Docs close-out** — execution.md, retrospective.md, INDEX (completed), DEVLOG,
  current-focus (next: step 3 Settings, plan 0043), open-questions; commit
  `[plan-0042] docs: design rules and audit policy, close plan`.
- [ ] **Step 7:** `git switch ui-revamp && git merge --no-ff port/0042-design-tokens`; ask the
  owner about push.

## Device check (owner)

- Today: log a drink from 0 → the arc sweeps from empty (not a jump); Reduce Motion on → no
  sweep.
- Light and Dark: the accent (`+`, tab selection, toggles) is Frost blue; risk colours read
  as before in Dark and darker in Light.

## Open questions

- [x] UI test for this step: the change is colour only, which XCUITest cannot read. The 7
  audit classes (contrast check) are the UI gate for this step, plus `DashboardUITests` /
  `InsightsUITests` as regression runs; no new UI test. Accepted by the owner, 2026-11-20.
- [x] Increase Contrast variants for `AccentColor` and the risk sets: not in the prototype.
  Later (step 11 or a separate small plan), after a device check under Increase Contrast
  (owner, 2026-11-20).
- [x] D0042-3: hero ink and mesh are added now (owner, 2026-11-20).

## Tests required

`RiskToneTests`, `BrandTests`, `CardMetricsTests`, `ArcShapeTests` (new, Swift Testing,
`drinkpulseTests/DesignSystem/`); existing `RiskLevelTests`, Dashboard and Insights unit and
UI tests; 7 ungated audit classes against the baseline.
