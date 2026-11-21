# 0046 — Port step 6: Today and Insights

**Status**: draft
**Size**: large
**Created**: 2026-11-21
**Programme**: [0040 — Native UI port](../0040-native-ui-port/plan.md), step 6
**Branch**: `port/0046-today-insights` (from `ui-revamp` at `cda7694`; `main` `c1b4bec` is already
merged)

> Execution: superpowers `executing-plans`, inline, one session where possible (owner workflow,
> plan 0040 "Workflow"). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Today and Insights become card screens built from system components on the Frost
tint: no Liquid Glass on content, `GroupBox` + `BrandCardStyle` cards, a branded hero with the
risk-coloured arc and the `toneCutOut` status glyph, `Gauge` limit rows, Swift Charts with the
daily-limit rule and slot identity, an Insights empty state, a period "Today" button and a
VoiceOver announcement on period change, and the `VOICE.md` copy for both screens.

**Architecture:** Views change in place; view models stay stateless w.r.t. persistence
(ADR-0004) and keep every calculation. New logic is presentation-only and lives in pure,
tested helpers: risk status label and symbol (`RiskLevel+Status`), chart slot identity
(`ChartPoint.slot`), the period announcement string. Pieces used by both screens (metric tile,
tile pair, limit gauge row, empty state) move to `DesignSystem/`. Folder and type names stay
(`Features/Dashboard`, `DashboardView`); only the user-facing name becomes "Today". No Domain,
persistence, service or schema change. No calculation change (plan 0040 step 10 owns
`drinkFreeDays` / `longestSoberStreak` and the heavy-day threshold).

**Tech stack:** SwiftUI `GroupBox` / `GroupBoxStyle`, `Gauge` + `.linearCapacity`,
`ViewThatFits`, `LazyVGrid` with `GridItem(.adaptive(minimum:))` + `@ScaledMetric`,
`MeshGradient`, `contentTransition(.numericText(value:))` /
`.numericText(countsDown:)` / `.symbolEffect(.replace)`, `symbolEffect(.bounce, value:)`,
`navigationSubtitle(_:)`, `ToolbarItem(placement: .largeTitle)`, `ContentUnavailableView`,
`Picker` `.segmented` / `.menu`; Swift Charts `Chart(_:id:content:)`, `AreaMark`, `LineMark`,
`BarMark`, `RuleMark`, `chartXSelection(value:)`, `AxisMarks(values: .automatic(desiredCount:))`,
`.stride(by:count:)`; Accessibility `AccessibilityNotification.Announcement`; Swift Testing;
XCUITest.

**Spec:** plan 0040 ("Decisions carried into the port": UI structure, Visual design, Charts and
motion, empty states; step 6; "Accessibility audit policy"); prototype
`~/Developer/drinkpulse-native-proto/DrinkPulseNativeProto/DrinkPulseNativeProto/`
(`Dashboard/DashboardView.swift`, `HeroGauge.swift`, `TodaySummaryRow.swift`, `WeekChart.swift`;
`Insights/InsightsView.swift`, `InsightsHeroCard.swift`, `InsightsCards.swift`;
`Components/CardComponents.swift`, `NoDrinksYetView.swift`, `Motion.swift`); FINDINGS "What
replaced what", rounds 2 (cards, period navigator, chart scrubbing), 8 (arc), 9 (glyph
`toneCutOut`), 10 / 12 (rounded type, copy decisions), 11 (card corner), 13 (micro-moments), 14
(motion, slot identity), 15 (AX5 / Increase Contrast, card titles), 16 (charts), 17 (empty
states), 21 (Insights period → menu at AX sizes); RESUME "Decisions already made" and "Port
notes"; `VOICE.md` rows for `dashboard.*`, `insights.*`.

## Summary

Today and Insights are the last screens that put Liquid Glass (`dpGlassCard`) on content and
hand-draw their controls: capsule badges with shape branches, `GeometryReader` progress bars, a
hand-built period navigator with a "NOW" pill and a tappable centre label, risk-coloured trend
badges, chart callout bubbles. The prototype rebuilt both screens with system components and the
owner accepted every round. This step ports them on the app's real view models and real risk
levels, keeps every number the screens show today, and applies the screens' `VOICE.md` copy.

## Context

- Current files (read 2026-11-21): `DashboardView.swift` (greeting header + `RiskBadge` from
  `effectiveRiskLevel`, inline title "Home"), `DashboardView+Previews.swift`,
  `Components/DashboardHeroCard.swift` (glass, `DPAdaptiveStack`, AX value branch, risk capsule),
  `DashboardChipRow.swift` + `DPChip.swift`, `ConsumptionOverviewCard.swift` (`IntakePeriodRow`,
  `GeometryReader` bar, `DPMotionProbe("overviewBar")`), `ThisWeekCard.swift` (calendar-week
  bars, % annotations, Y axis hidden), `StreakCard.swift`, `GuidelineAlertCard.swift` (shown
  when `riskLevel == .exceeded`, i.e. rolling 7-day grams over the weekly limit);
  `InsightsView.swift`, `Components/InsightsScopeNavigator.swift`, `InsightsHeroCard.swift`
  (`TrendBadge` red / green), `AlcoholAreaChart.swift` (categorical `String` keys, caution-tone
  area, callout), `AlcoholAreaChart+Previews.swift`, `+Accessibility.swift`,
  `HealthMetricsCard.swift`, `WeekdayBarChart.swift` (risk-coloured bars, callout),
  `+Accessibility.swift`, `GuidelineComparisonCard.swift`; `DashboardViewModel.swift`,
  `InsightsViewModel.swift` (+ `Charts`, `Formatting`, `HealthMetrics`), `InsightsChartModels.swift`.
- `DesignSystem` already has the plan 0042 pieces: `BrandCardStyle` + `CardMetrics`,
  `brandBackground()`, `BrandSurface`, `CardTitle`, `brandNavigationTitle(_:)`, `Brand.heroMesh`
  / `ink`, `RiskLevel.tone` (asset colours, `nonisolated`), `DPArcProgress` with
  `animatableData` and the `heroArc` motion probe, `withMotion`, `DPMotion`.
- `RiskLevel.from(pct:)`: `< 0.5` safe, `<= 1.0` caution, `> 1` exceeded. The prototype's
  75 % / 100 % status thresholds are placeholders (plan 0040); labels change, thresholds do not
  (`VOICE.md` owner decision).
- `dpSecondaryText` (asset `SecondaryText`) is still used by History and Settings, and the
  system secondary label fails 4.5:1 for small text on a light card (plan 11-17); so it stays
  the secondary ink on cards here. No colour asset becomes unused in this step; deleting
  `DPGlass.swift` and unused tokens stays in step 11 (`DrinkTypeTile` still uses `dpGlassCard`
  until step 7).
- UI tests on these screens: `DashboardUITests`, `DashboardDynamicTypeUITests`,
  `ReduceMotionDashboardUITests`, `DashboardAccessibilityAuditUITests`,
  `DashboardOverLimitAccessibilityAuditUITests`, `InsightsUITests`, `InsightsScrubUITests`,
  `InsightsDynamicTypeUITests`, `InsightsStreakUITests`, `InsightsDrinkFreeDaysUITests`,
  `InsightsAccessibilityAuditUITests`, `ProbeAccessibilityAuditUITests` (`overviewBar` probe).
  20 UI test files look up `navigationBars["Home"]` / `tabBars.buttons["Home"]`.
- Unit tests touched: `DashboardViewModelTests` (+ `Formatting`, `Metrics`, `PctAndRisk`),
  `InsightsViewModelTests` (+ `Aggregates`, `Navigation`), `AlcoholAreaChartAXDescriptorTests`,
  `WeekdayBarChartAXDescriptorTests`, `ScreenComputePerformanceTests`.
- Open-questions entries this step touches: "Insights hero card height test fails"
  (the test is replaced, D0046-9), the Today / Insights lines of "Accessibility audit failures
  on the old UI", plan 0040 device checks (Insights announcement, rounded large title collapse,
  haptics / micro-moments).
- Apple docs checked while drafting (Xcode MCP `DocumentationSearch`, 2026-11-21):
  `Chart.init(_:id:content:)` (identity from `id`); `PlottableValue.value(_:_:unit:calendar:)`
  (date bins); `chartXSelection` (Charts selection family); `GaugeStyle.linearCapacity`
  ("fills from leading to trailing edges"; label above) and `tint(_:)` on a gauge;
  `navigationSubtitle(_:)` ("displayed with the navigation title in the navigation bar"),
  `ToolbarItemPlacement.largeTitle` / `.largeSubtitle`; `AccessibilityNotification.Announcement`
  (`post()`, optional priority); HIG Charting data › Best practices and Designing effective
  charts ("maintain continuity among multiple charts that use the same data"), HIG Gauges ›
  Best practices (labels read by VoiceOver).

## Decisions (this plan)

Owner answers (2026-11-21) are marked **owner**. Everything else follows from plan 0040,
FINDINGS or the precedent of plan 0045, and is open to review in this draft.

- **D0046-1 — The screen is called "Today" (owner).** `tab.home` keeps its key, value
  "Today"; tab label and navigation title read "Today" (`brandNavigationTitle`). Subtitle
  `navigationSubtitle` = `date · guideline` (`.weekday(.abbreviated).day().month(.abbreviated)`
  + `guidelineDisplayName`). The greeting and the header `RiskBadge` go (VOICE.md: greeting not
  reinstated); `greetingText` and the three `dashboard.greeting.*` keys are removed. UI tests:
  one constant `UITestTabs.today = "Today"` in `drinkpulseUITests/Features/Shell/UITestTabs.swift`
  replaces every `"Home"` lookup (20 files).
- **D0046-2 — Hero.** `TodayHeroCard`: `ViewThatFits(in: .horizontal) { HStack; VStack }` of
  figures + `HeroGauge`, `Brand.heroMesh` `MeshGradient` background (flattened to stop 0 under
  Increase Contrast), `Brand.ink` text, `CardMetrics.cornerRadius`, one combined accessibility
  element (label = eyebrow + value + status). Figures: eyebrow "Pure alcohol today", value
  rounded `largeTitle` bold with `numericText()`, limit copy (existing daily-limit / daily-avg
  keys), status label. Status = **today's** risk (`todayRiskLevel`), as in the prototype; the
  weekly risk stays visible in the 7-day gauge and the weekly alert card. The AX-size value
  branch stays only if the AX5 audit flags the scaled value again (record in `execution.md`).
- **D0046-3 — Arc and glyph.** `HeroGauge` = `DPArcProgress` (tone = `todayRiskLevel.tone`) with
  the percent inside (`numericText(value:)`, rounded `headline`, `Brand.ink`,
  `minimumScaleFactor(0.6)`), `@ScaledMetric(relativeTo: .largeTitle)` diameter 88 / stroke 9,
  own accessibility label "Daily limit" + percent value. Status glyph `toneCutOut`: fill =
  `RiskLevel.tone`, mark `.white` in Light / `Brand.heroMesh(for: .dark)[1]` in Dark,
  `.symbolRenderingMode(.palette)`, `.contentTransition(.symbolEffect(.replace))`. Symbols:
  safe `checkmark.circle.fill`, caution `exclamationmark.circle.fill`, exceeded
  `exclamationmark.triangle.fill` (as today). The first-run track draw is step 8.
- **D0046-4 — Tiles.** `MetricTile` + `TilePair` (`DesignSystem/`, prototype code): Calories
  (`flame.fill`, `.orange`), Drinks (`wineglass.fill`, `.pink`), Alcohol-Free Streak
  (`trophy.fill`, `.purple`, detail "Start one tomorrow" at 0, one bounce per launch when ≥ 1,
  off under Reduce Motion), Alcohol-Free This Month (`moon.fill`, `.teal`). Icons keep natural
  colours, one colour per concept (RESUME). Values `^[\(n) day](inflect: true)`.
- **D0046-5 — Guideline Limits card.** `LimitGaugeRow` (`DesignSystem/`): `Gauge(value:
  min(fraction, 1))` `.linearCapacity`, `.tint(RiskLevel.from(pct:).tone)`, `LabeledContent`
  label "consumed / limit unit · pct" with `numericText(countsDown:)`, "x over the limit" line
  in the risk tone when > 100 %. Optional `motionProbeSite` keeps `DPMotionProbe("overviewBar")`
  on Today's three rows only (Reduce Motion tests). Rows: Today, 7 Days, 30 Days, existing
  view-model values. Replaces `IntakePeriodRow` and its `GeometryReader` bar.
- **D0046-6 — This Week chart stays the calendar week (owner).** Card "This Week", bars from
  `weekBarData` (Mon–Sun by locale, future days placeholder). Changes: `GroupBox` + `CardTitle`,
  bars in `RiskLevel.tone`, dashed `RuleMark` at the effective daily limit with caption "Daily
  limit" (`Color.secondary`), % captions and the limit caption hidden at accessibility sizes,
  X labels every second day at AX sizes, per-bar accessibility label (weekday) + value (amount
  in the user's unit) instead of `accessibilityHidden(true)`.
- **D0046-7 — Weekly alert.** Same condition as today. `GroupBox` with `Label("Over Weekly
  Limit", systemImage: "exclamationmark.triangle.fill")` in `RiskLevel.exceeded.tone` and the
  text "You are at X% of the <guideline> weekly limit." (new key, `%@` guideline), combined
  accessibility element. No red overlay.
- **D0046-8 — Insights period controls.** `InsightsPeriodPicker` (own `View` struct, round 21
  preview note): `.segmented`, `.menu` at accessibility sizes. `InsightsPeriodNavigator`:
  `Button(_:systemImage:)` previous / next, `.labelStyle(.iconOnly)`, `.buttonStyle(.bordered)`,
  `.buttonBorderShape(.circle)`, existing enable rules (`minAllowedOffset`, current period);
  centre = `friendlyLabel` (headline) over `rangeLabel` (`dpSecondaryText`), plain text with
  `numericText(countsDown:)`. The "NOW" pill and the tappable centre go; the jump is a "Today"
  toolbar button (`.topBarLeading`, new key `insights.nav.today`) shown only off the current
  period, Calendar-app pattern (round 2). The navigator is hidden in All (prototype). Period and
  offset changes go through `withMotion`; `numbersCountDown` environment set by direction.
- **D0046-9 — Hero total and area chart.** `InsightsHeroCard` in a `GroupBox`
  (`CardTitle` "Total"): total (or the selected point) rounded `largeTitle`, then either the
  selected point's date or the neutral trend line (arrow `arrow.up.right` / `arrow.down.right` /
  `equal` + "N% vs previous <period> (prev)" in `dpSecondaryText`; no red / green, round 16).
  `AlcoholAreaChart`: `Chart(points, id: \.slot)`, `x: .value(date, unit: .day | .month)`,
  accent area (`.tint.opacity(0.25)`) + line, `interpolationMethod(.monotone)`, dashed daily
  limit rule + caption for Week and Month, `chartXSelection(value: $selectedDate)` with a
  `RuleMark` at the selection (no callout), axis counts `desiredCount` 3 (Y) / 2 (X) at AX
  sizes, `nil` otherwise. `AlcoholAreaChartAXDescriptor` kept. `TrendBadge`, the categorical
  `ChartPoint.key` axis and `labelKeys` go. `test_heroCard_holdsHeight_whenSwitchingToAllTimeScope`
  is replaced by `test_allTimeScope_hidesNavigator_keepsChart` (the navigator is gone in All, so
  the old invariant no longer holds); its open-questions entry is closed.
- **D0046-10 — Health Impact grid.** `LazyVGrid(columns: [GridItem(.adaptive(minimum:
  minimumCellWidth))])` with `@ScaledMetric(relativeTo: .body) minimumCellWidth = 150` (one
  column at large sizes, no branch). `MetricCell`: `Label` (title, natural icon colour),
  value `title3` bold rounded with `numericText(countsDown:)`, optional detail. Cells and values:
  Heavy Days (`vm.bingeEpisodes`, detail "60 g or more in a day" — **owner**: always grams,
  logic unchanged), Alcohol Calories, Alcohol-Free Days `count/total` + percent, Longest
  Alcohol-Free Streak (`vm.longestSoberStreak`, `^[n day](inflect: true)`), Highest Day (value +
  date, "–" when none), Spend (value + per day, "–" when none). Spend keeps `eurosign.circle`.
- **D0046-11 — Weekday chart: no scrubbing (owner).** `GroupBox` + `CardTitle` "Weekday
  Patterns", `BarMark` in `Brand.accent` (amounts, not risk; round 16), per-bar accessibility
  label + value, `WeekdayBarChartAXDescriptor` kept; selection, `PointMark` and callout removed,
  so `dpChartCalloutBackground` loses its last caller and is deleted from `DPGlass.swift`.
  `WeekdayBar.riskLevel` stays (the descriptor and tests use it) unless no reader is left.
- **D0046-12 — Guideline comparison.** `GroupBox` + `CardTitle` "Guideline Comparison", one
  `LimitGaugeRow` per guideline, the user's guideline marked with " ✓" in its title; existing
  labels (`comparisonLabel`) and the "of limit" accessibility wording kept.
- **D0046-13 — Insights empty state.** No events → `NoDrinksYetView(title: "No Insights Yet",
  message: "Your totals and trends appear once you log a drink.", systemImage: "chart.bar")`
  for the whole page, bordered "Log a Drink" calling `\.addDrink`. `HistoryEmptyView` becomes
  this shared view (`DesignSystem/NoDrinksYetView.swift`); History passes its own copy. Today
  has no empty state (round 17: 0 / Within Limit is true). `insights.areaChart.empty` is removed
  once unused.
- **D0046-14 — Period announcement.** On every change of `(period, activeOffset)` Insights posts
  `AccessibilityNotification.Announcement(vm.periodAnnouncement)`: "<friendly label>, <range>,
  <total spoken>". Spoken total uses new keys with the unit written out
  (`insights.announce.grams` "%@ grams of pure alcohol", `.standardDrinks` "%@ standard
  drinks", `.units` "%@ units"), picked like `AlcoholUnit.unitLabel(for:)` picks its label.
  HIG Charts: changes must not be conveyed by motion alone.
- **D0046-15 — Copy (owner: fold the Today / Insights rows of `VOICE.md` here).** Keys keep
  their names, values change: `dashboard.risk.safe/caution/exceeded` → Within Limit / Close to
  Limit / Over Limit; `dashboard.hero.eyebrow` → "Pure alcohol today";
  `dashboard.streak.current` → "Alcohol-Free Streak"; `.soberThisMonth` → "Alcohol-Free This
  Month"; `.zeroState` → "Start one tomorrow"; `dashboard.overview.title` → "Guideline Limits";
  `dashboard.alert.title` → "Over Weekly Limit"; `dashboard.overview.overLimit` → "%@ over the
  limit"; `insights.metric.bingeEpisodes` → "Heavy Days"; `.drinkFreeDays` → "Alcohol-Free
  Days"; `.soberStreak` → "Longest Alcohol-Free Streak"; `.heaviestDay` → "Highest Day";
  `insights.metric.riskLevel` / `.risk.*` → "Limit Status" / Within / Close to / Over Limit
  (only if still referenced; otherwise removed). New keys: `dashboard.alert.body`,
  `dashboard.limit.caption` ("Daily limit"), `insights.metric.heavyDays.detail`,
  `insights.empty.title`, `insights.empty.description`, `insights.nav.today`,
  `insights.announce.*`, `common.logADrink` (History's `history.logADrink` merges into it).
  Removed when unused: `dashboard.greeting.*`, `insights.nav.now`, `insights.trend.unchanged`,
  `insights.areaChart.empty`. Other strings stay for step 9.
- **D0046-16 — Test gate.** Scoped `RunSomeTests` per task. Plan 0040 schedules full suites at
  steps 5, 8 and 11, but AGENTS.md "Quality gates" escalates to a full run when 3+ test classes
  are affected; the "Today" rename alone touches 20 UI test files. So Task 8 runs the full
  suite. The owner may waive it in favour of scoped batches; record the choice.

## Scope

### In
- Today: hero, tiles, Guideline Limits card, This Week chart, weekly alert, title / subtitle,
  tint, previews (Light, Dark, AX5, over limit, empty).
- Insights: period picker + navigator + "Today" button, hero + area chart, Health Impact,
  weekday chart, guideline comparison, empty state, announcement, motion.
- Shared `MetricTile`, `TilePair`, `LimitGaugeRow`, `NoDrinksYetView`, `RiskLevel+Status`.
- Copy per D0046-15; "Home" → "Today" in UI tests.
- Audit classes for Today, Today over limit and Insights green on the new UI (round 21 policy).
- `docs/architecture.md` DesignSystem and screen sections; full suite at the end (D0046-16
  below).

### Out
- First-run entrance (`firstRunReveal`, arc track draw, onboarding cover) — step 8.
- `drinkFreeDays` / `longestSoberStreak` from the first logged drink; heavy-day threshold —
  step 10 (calculation change, owner hand-verifies).
- Add / Edit Drink, `DrinkTypeTile` glass — step 7. Deleting `DPGlass.swift`, `DPColors`
  entries, `DPAdaptiveStack`, `SecondaryText` — step 11.
- Renaming `Features/Dashboard` or `Dashboard*` types (internal names; no user-facing effect).

## Global constraints

- **Xcode MCP for everything it covers** (main checkout, no worktree; memory "Xcode MCP
  first"). Session start: `XcodeListWorkspaces` → entry whose `workspacePath` ends with
  `drinkpulse.xcodeproj` → its `workspaceIdentifier` on every call that accepts it;
  `XcodeListRunDestinations` before every test call (iPhone 18 Pro, iOS 27.2 simulator; never
  the physical device).
  - Build: `BuildProject`, then `GetBuildLog` — zero warnings.
  - Tests: `RunSomeTests` with named classes, at most about 10 classes per call; `GetTestList`
    to confirm new tests exist and ran. `RunAllTests` only in Task 8.
  - Code: `XcodeRead`, `XcodeGrep`, `XcodeGlob`, `XcodeUpdate` / `XcodeWrite`, `XcodeMV`,
    `XcodeRM`, `XcodeRefreshCodeIssuesInFile` after each edited file. Strings:
    `StringCatalogRead` / `StringCatalogEdit`. Visual: `RenderPreview` (Light, Dark, AX5).
  - **No CLI `xcodebuild` / `xcrun` without the owner's approval**, even for a named MCP gap.
    Known gap: no coverage report in MCP → ask the owner (Task 8).
- **Apple docs first:** `DocumentationSearch` (API and HIG) before each API use or design
  call; developer.apple.com only if MCP lacks the page. Record query, symbol and availability
  in `execution.md`. Each task's Step 0 lists its lookups.
- **No calculation change.** View-model numbers stay as they are; any wrong-looking value found
  while porting gets an `execution.md` note and an open question, not a fix (AGENTS.md
  "Calculations"; plan 0040 step 10).
- Swift 6 strict concurrency, zero warnings; colours used in `Chart` marks are asset colours or
  `nonisolated` (no main-actor `UIColor` provider, FINDINGS crash note); files under 300 lines;
  previews for every view (Light, Dark, AX5, empty / over limit) with in-memory data.
- No schema change. If one appears, stop (new schema version, AGENTS.md).
- No PII in logs; no `print`; no `try?` without a comment (the streak bounce `Task.sleep` gets
  one: cancellation is the only error and is ignorable).
- New unit tests: Swift Testing, mirrored folders (`drinkpulseTests/DesignSystem/`,
  `drinkpulseTests/Features/Dashboard/`, `drinkpulseTests/Features/Insights/`). UI tests in
  `drinkpulseUITests/Features/Dashboard/`, `…/Insights/`; system UI never matched by a localized
  label (simulator locale is Polish).

## Review focus

1. **Over the daily limit but under the weekly limit, and the reverse** — the hero status shows
   today's level, the alert card shows only on the weekly condition. Pinned in Task 1
   (`RiskLevel+Status` mapping) and Task 3 (UI test on an over-weekly dataset: alert visible,
   hero status matches today's level).
2. **Profile with no daily limit** (`dailyLimitGrams == 0`, daily-avg copy) — arc, gauge row
  and chart rule must not divide by zero or draw a rule at 0. Pinned in Task 2 (`LimitGaugeRow`
  fraction 0 when limit 0; This Week rule omitted when the effective limit is 0) and a preview.
3. **Insights on a period with no drinks but events elsewhere** — no empty state (that is only
   for no events at all), zero totals, flat chart, trend "0 %" or "equal". Pinned in Task 6
   (UI test: navigate to the oldest empty week of the `multiday` dataset or a unit test on
   `seriesData` slots for an empty range).
4. **Switching period while a point is selected** — selection cleared, hero shows the new
   total, slots line up (Week 7 → Month 28–31 → Year 12). Pinned in Task 5 (slot unit tests;
   `selectedDate` reset on period change).
5. **AX5 and Increase Contrast** — tiles stack, grid drops to one column, hero stacks, chart
   annotations drop; tint off under Increase Contrast. Pinned in Task 7 (audit classes AX5 and
   dark variants, `DashboardDynamicTypeUITests`, `InsightsDynamicTypeUITests`).

---

### Task 1: Pure presentation logic

**Files:**
- Create: `drinkpulse/DesignSystem/RiskLevel+Status.swift`
- Modify: `drinkpulse/Features/Insights/InsightsChartModels.swift` (`ChartPoint.slot`),
  `InsightsViewModel+Charts.swift` (slots), new `InsightsViewModel+Announcement.swift`,
  `DashboardViewModel.swift` (remove `greetingText`; remove `effectiveRiskLevel` if Task 3
  leaves no reader — do it there)
- Test: `drinkpulseTests/DesignSystem/RiskLevelStatusTests.swift`,
  `drinkpulseTests/Features/Insights/InsightsViewModelTests+Announcement.swift`,
  `InsightsViewModelTests+Aggregates.swift` (slots); delete greeting tests in
  `DashboardViewModelTests+Formatting.swift`

**Interfaces:**
- Produces:
  - `extension RiskLevel { nonisolated var statusTitle: String; nonisolated var statusSymbol:
    String }` — titles from `dashboard.risk.*`, symbols per D0046-3.
  - `struct ChartPoint: Identifiable { let slot: Int; let date: Date; let grams: Double;
    var id: Int { slot } }` — slot = index in the period, 0-based.
  - `InsightsViewModel.periodAnnouncement: String` (D0046-14).

- [ ] **Step 0: Docs** — `DocumentationSearch`: `Chart.init(_:id:content:)`,
  `Identifiable`, `String(localized:)` with arguments; HIG Charts › Enhancing the
  accessibility of a chart.
- [ ] **Step 1: Write the failing tests**
  - `test_statusTitle_mapsEveryLevel` (safe "Within Limit", caution "Close to Limit", exceeded
    "Over Limit") and `test_statusSymbol_mapsEveryLevel`.
  - `test_seriesSlots_week_areZeroToSix`, `test_seriesSlots_month_matchDayCount` (Feb of a
    leap year → 0…28), `test_seriesSlots_year_areZeroToEleven`,
    `test_seriesSlots_emptyRange_stillHaveSlots` (Review focus 3, 4).
  - `test_periodAnnouncement_grams_spellsOutUnit` ("This week, <range>, 19.7 grams of pure
    alcohol"), `test_periodAnnouncement_ukUnits`, `test_periodAnnouncement_standardDrinks`,
    `test_periodAnnouncement_allTime`.
- [ ] **Step 2: Run** `RiskLevelStatusTests`, `InsightsViewModelTests` (all extensions),
  `AlcoholAreaChartAXDescriptorTests` via `RunSomeTests` — FAIL (undefined).
- [ ] **Step 3: Implement**; string keys via `StringCatalogEdit`; fix call sites of
  `ChartPoint.init` (previews, descriptor tests, `ScreenComputePerformanceTests`).
- [ ] **Step 4: Run** the same classes plus `DashboardViewModelTests` — PASS.
- [ ] **Step 5: Commit** `[plan-0046] risk status, chart slots, period announcement`.

### Task 2: Shared card components

**Files:**
- Create: `drinkpulse/DesignSystem/MetricTile.swift`, `TilePair.swift`, `LimitGaugeRow.swift`,
  `NoDrinksYetView.swift`
- Modify: `drinkpulse/Features/History/HistoryView.swift` (use `NoDrinksYetView`)
- Delete: `drinkpulse/Features/History/Components/HistoryEmptyView.swift`
- Strings: `common.logADrink` ("Log a Drink") replaces `history.logADrink`
- Test: `drinkpulseTests/DesignSystem/LimitGaugeRowTests.swift`

**Interfaces:**
- Consumes: `RiskLevel.tone`, `CardTitle`, `DPMotionProbe`.
- Produces:
  - `struct MetricTile: View { init(title: String, systemImage: String, tint: Color, value:
    LocalizedStringKey, detail: String? = nil, celebrates: Bool = false) }`
  - `struct TilePair<First: View, Second: View>: View` (prototype code)
  - `struct LimitGaugeRow: View { init(title: String, consumedGrams: Double, limitGrams: Double,
    format: (Double) -> String, unitLabel: String, motionProbeSite: String? = nil) }` with
    `nonisolated static func fraction(consumed: Double, limit: Double) -> Double` (0 when
    limit ≤ 0)
  - `struct NoDrinksYetView: View { init(title: String, message: String, systemImage: String) }`
    — identifiers `empty.logADrink` on the button.

- [ ] **Step 0: Docs** — `DocumentationSearch`: `Gauge`, `GaugeStyle.linearCapacity`,
  `tint(_:)`, `LabeledContent`, `ViewThatFits`, `GroupBox`, `symbolEffect(_:options:value:)`
  (bounce), `ContentUnavailableView(label:description:actions:)`; HIG Gauges, Boxes.
- [ ] **Step 1: Write the failing tests** — `test_fraction_isZero_whenLimitIsZero`,
  `test_fraction_exceedsOne_whenOverLimit` (Review focus 2).
- [ ] **Step 2: Run** `LimitGaugeRowTests` — FAIL.
- [ ] **Step 3: Implement**; `RenderPreview` each (Light, Dark, AX5); History empty state
  unchanged visually.
- [ ] **Step 4: Run** `LimitGaugeRowTests`, `HistoryDaySectionsUITests` (empty-state test) — PASS.
- [ ] **Step 5: Commit** `[plan-0046] shared metric tile, limit gauge row, empty state`.

### Task 3: Today screen

**Files:**
- Create: `drinkpulse/Features/Dashboard/Components/TodayHeroCard.swift`, `HeroGauge.swift`,
  `HeroStatusLabel.swift`
- Modify: `DashboardView.swift`, `DashboardView+Previews.swift` (add daily-avg profile and
  over-weekly previews), `Components/ThisWeekCard.swift`, `Components/GuidelineAlertCard.swift`,
  `DashboardViewModel.swift` (remove `effectiveRiskLevel` and its tests in
  `DashboardViewModelTests+PctAndRisk.swift` once `RiskBadge` is gone)
- Move: `Components/ConsumptionOverviewCard.swift` → `Components/GuidelineLimitsCard.swift`
  (`XcodeMV`, then rewrite on `LimitGaugeRow`)
- Delete: `DashboardHeroCard.swift`, `DashboardChipRow.swift`, `DPChip.swift`, `StreakCard.swift`
- Strings: D0046-15 `dashboard.*`, `tab.home` value "Today"
- Tests: `DashboardUITests` (rewrite for the new labels), new
  `drinkpulseUITests/Features/Dashboard/TodayStatusUITests.swift`;
  `ReduceMotionDashboardUITests` keeps `heroArc` / `overviewBar` sites

**Interfaces:**
- Consumes: Task 1 `statusTitle` / `statusSymbol`; Task 2 components; `DPArcProgress`,
  `Brand.heroMesh` / `ink`, `brandBackground()`, `brandNavigationTitle(_:)`,
  `AddDrinkToolbarItem`.
- Produces: identifiers `today.hero`, `today.status`, `today.alert` (stable test keys).

- [ ] **Step 0: Docs** — `DocumentationSearch`: `MeshGradient`, `navigationSubtitle(_:)`,
  `ToolbarItemPlacement.largeTitle`, `contentTransition(_:)` + `numericText(value:)`,
  `symbolRenderingMode(.palette)`, `SymbolEffect` replace, `ScaledMetric`, `RuleMark`,
  `AxisMarks(values: .stride(by:count:))`, `colorSchemeContrast`; HIG Branding, Color ›
  Inclusive color, SF Symbols › Animations, Motion.
- [ ] **Step 1: Write the failing UI tests** (default seed: one 2.0 std beer = 20 g, WHO 20 g)
  - `test_hero_showsPureAlcoholToday_andCloseToLimit` — `today.hero` label contains "Pure
    alcohol today", "2.0", "std", "Close to Limit" (100 % is caution).
  - `test_tiles_showDrinksAndAlcoholFreeTiles` — "Drinks" tile value "1"; "Alcohol-Free Streak"
    and "Alcohol-Free This Month" present.
  - `test_guidelineLimits_showsThreeRows` — "Guideline Limits" header; rows Today / 7 Days /
    30 Days.
  - `test_overWeeklyLimit_showsAlert_andHeroKeepsTodaysStatus` — dataset with heavy earlier days
    and nothing today (add `overweekly` to `UITestSeed` if no dataset fits; test-only, no PII):
    `today.alert` contains "Over Weekly Limit"; `today.status` "Within Limit" (Review focus 1).
  - `test_title_isToday_withSubtitle` — `navigationBars["Today"]` exists.
  - Keep `test_loggingDrink_updatesVisibleDrinkCount` and the progress-update test on the new
    labels.
- [ ] **Step 2: Run** `DashboardUITests`, `TodayStatusUITests` — FAIL.
- [ ] **Step 3: Implement** D0046-1 … D0046-7; `XcodeGrep` `dpGlassCard|DPAdaptiveStack|
  greetingText|RiskBadge` in `Features/Dashboard` → no hits; `BuildProject` clean;
  `RenderPreview` Today (Light, Dark, AX5, over limit, daily-avg profile, empty).
- [ ] **Step 4: Run** `DashboardUITests`, `TodayStatusUITests`, `ReduceMotionDashboardUITests`,
  `DashboardDynamicTypeUITests`, `ProbeAccessibilityAuditUITests`, `DashboardViewModelTests` —
  PASS.
- [ ] **Step 5: Commit** `[plan-0046] Today screen on native cards`.

### Task 4: "Home" → "Today" in UI tests

**Files:**
- Create: `drinkpulseUITests/Features/Shell/UITestTabs.swift`
  (`enum UITestTabs { static let today = "Today" }`)
- Modify: the 20 files from `XcodeGrep` `navigationBars\["Home"\]|buttons\["Home"\]` in
  `drinkpulseUITests` (list them in `execution.md`)

- [ ] **Step 1:** Replace every lookup with `UITestTabs.today`; `XcodeGrep` → no `"Home"` left
  in `drinkpulseUITests`.
- [ ] **Step 2: Run** the edited classes in batches of about 10 (`RunSomeTests`) — PASS, or only
  failures already named in open-questions (report them by name).
- [ ] **Step 3: Commit** `[plan-0046] UI tests: Home tab is now Today`.

### Task 5: Insights hero and area chart

**Files:**
- Modify: `Components/InsightsHeroCard.swift`, `AlcoholAreaChart.swift`,
  `AlcoholAreaChart+Previews.swift`, `AlcoholAreaChart+Accessibility.swift` (slot points)
- Tests: `InsightsScrubUITests` (area scrub keeps "hero total changes and reverts"; remove
  `test_scrubbingWeekdayChart_showsCallout` — owner D0046-11), `InsightsAccessibilityAuditUITests`
  (`test_insights_standard_markLabelMatchesCallout` → `…_markLabelMatchesSelectedDate`: the
  scrubbed mark's accessibility date equals the date line under the hero total),
  `AlcoholAreaChartAXDescriptorTests`

**Interfaces:**
- Consumes: `ChartPoint.slot` (Task 1), `CardTitle`, `effectiveDailyLimitGrams`.
- Produces: `@State selectedDate: Date?` in `InsightsHeroCard`, reset on `vm.period` and
  `vm.activeOffset` change (Review focus 4).

- [ ] **Step 0: Docs** — `DocumentationSearch`: `chartXSelection(value:)`,
  `PlottableValue.value(_:_:unit:calendar:)`, `AreaMark`, `LineMark`,
  `interpolationMethod(_:)`, `AxisMarkValues.automatic(desiredCount:roundLowerBound:roundUpperBound:)`,
  `accessibilityChartDescriptor(_:)`; Swift Charts "Customizing axes"; HIG Charts › Color,
  Charting data (continuity).
- [ ] **Step 1: Update the failing tests** — scrub test asserts the hero total changes and the
  date line appears; audit mark-label test as above — run — FAIL.
- [ ] **Step 2: Implement** D0046-9; `XcodeGrep` `TrendBadge|ChartPoint.key|labelKeys|
  dpChartCalloutBackground` in `Features/Insights` → no hits; `RenderPreview` Week, Month,
  Year, All (Light, Dark, AX5).
- [ ] **Step 3: Run** `InsightsScrubUITests`, `InsightsAccessibilityAuditUITests`
  (`markLabel…` only), `AlcoholAreaChartAXDescriptorTests`, `InsightsViewModelTests` — PASS.
- [ ] **Step 4: Commit** `[plan-0046] Insights hero and area chart with slot identity`.

### Task 6: Insights page, cards, empty state, announcement

**Files:**
- Create: `drinkpulse/Features/Insights/Components/InsightsPeriodPicker.swift`
- Move: `Components/InsightsScopeNavigator.swift` → `InsightsPeriodNavigator.swift` (`XcodeMV`)
- Modify: `InsightsView.swift` (empty state, toolbar "Today", `withMotion`, announcement,
  `numbersCountDown`, `brandBackground`, `brandNavigationTitle`), `HealthMetricsCard.swift`,
  `WeekdayBarChart.swift` (+ `Accessibility` if the bar label changes),
  `GuidelineComparisonCard.swift`, `InsightsViewModel+Formatting.swift` (selected-guideline
  flag for D0046-12 if needed)
- Delete: `dpChartCalloutBackground` from `DesignSystem/DPGlass.swift`
- Strings: D0046-15 `insights.*`
- Tests: `InsightsUITests` (labels; replace the height test per D0046-9), `InsightsStreakUITests`,
  `InsightsDrinkFreeDaysUITests` (new labels), new
  `drinkpulseUITests/Features/Insights/InsightsNavigationUITests.swift`

**Interfaces:**
- Consumes: Task 1 `periodAnnouncement`; Task 2 `LimitGaugeRow`, `NoDrinksYetView`; Task 5 hero.
- Produces: identifiers `insights.nav.previous`, `insights.nav.next`, `insights.nav.todayButton`.

- [ ] **Step 0: Docs** — `DocumentationSearch`: `Picker` + `PickerStyle.menu` / `.segmented`,
  `ButtonBorderShape.circle`, `ButtonStyle.bordered`, `labelStyle(.iconOnly)`,
  `ToolbarItemPlacement.topBarLeading`, `LazyVGrid`, `GridItem.Size.adaptive(minimum:maximum:)`,
  `AccessibilityNotification.Announcement`, `EnvironmentValues` `@Entry`; HIG Segmented controls,
  Charts › Best practices (announce changes), Toolbars.
- [ ] **Step 1: Write the failing UI tests** (`multiday` unless noted)
  - `test_todayButton_appearsOffCurrentPeriod_andReturns` — previous → "Last week" and the
    `insights.nav.todayButton` exists; tap it → "This week", button gone.
  - `test_allTimeScope_hidesNavigator_keepsChart` — segment "All" → no `insights.nav.previous`;
    "Alcohol Over Time" still present.
  - `test_emptyStore_showsNoInsightsYet_andLogADrinkOpensAddDrink` (dataset `empty`).
  - `test_healthImpact_showsHeavyDaysWithDefinition` — "Heavy Days" and "60 g or more in a
    day".
  - `test_emptyPeriod_showsZeroTotal_notEmptyState` — navigate back past the data → no "No
    Insights Yet", hero total present (Review focus 3).
  - Update `InsightsUITests`, `InsightsStreakUITests` ("Longest Alcohol-Free Streak"),
    `InsightsDrinkFreeDaysUITests` ("Alcohol-Free Days").
- [ ] **Step 2: Run** `InsightsNavigationUITests`, `InsightsUITests` — FAIL.
- [ ] **Step 3: Implement** D0046-8, D0046-10 … D0046-14; `XcodeGrep` `dpGlassCard|NowPill|
  insights.nav.now|DPAdaptiveStack` in `Features/Insights` → no hits; `BuildProject` clean;
  `RenderPreview` Insights (Light, Dark, AX5, empty, All).
- [ ] **Step 4: Run** `InsightsNavigationUITests`, `InsightsUITests`, `InsightsStreakUITests`,
  `InsightsDrinkFreeDaysUITests`, `InsightsDynamicTypeUITests`, `InsightsScrubUITests`,
  `WeekdayBarChartAXDescriptorTests`, `InsightsViewModelTests` — PASS.
- [ ] **Step 5: Commit** `[plan-0046] Insights cards, period controls, empty state, announcement`.

### Task 7: Audit classes on the new UI

**Files:**
- Modify: `DashboardAccessibilityAuditUITests.swift`,
  `DashboardOverLimitAccessibilityAuditUITests.swift`, `InsightsAccessibilityAuditUITests.swift`,
  `Features/Shell/AccessibilityAuditBarControls.swift` (new keys only if reported),
  `AccessibilityAuditUITests` Today / Insights calls if they use old-UI helpers

- [ ] **Step 0: Docs** — XCTest `performAccessibilityAudit(for:_:)`,
  `XCUIAccessibilityAuditType`; UIKit `UILargeContentViewerInteraction`.
- [ ] **Step 1: Run** the three audit classes (standard, dark, AX5, over limit) plus
  `DashboardDynamicTypeUITests`, `InsightsDynamicTypeUITests`. Record every finding in
  `execution.md`.
- [ ] **Step 2: Fix** content findings at the source (contrast → `dpSecondaryText` / `Brand`
  ink / `RiskLevel.tone`; Dynamic Type → layout, e.g. the D0046-2 AX value branch); exempt only
  bar controls (`+`, Insights "Today" button) per round 21, by identifier. The in-content period
  picker gets no exemption (`.menu` at AX sizes).
- [ ] **Step 3: Run** again — green. Remove the Today / Insights lines from open-questions
  "Accessibility audit failures on the old UI".
- [ ] **Step 4: Commit** `[plan-0046] Today and Insights audit classes green on the native UI`.

### Task 8: Gates, docs, close

**Files:**
- Modify: `docs/architecture.md` (DesignSystem: shared `MetricTile`, `TilePair`,
  `LimitGaugeRow`, `NoDrinksYetView`, `RiskLevel+Status`; chart rules — slot identity, accent
  for amounts / risk tone for limits, daily-limit rule, AX axis counts, announcement; Today /
  Insights no longer use glass), `README.md` if it names "Home" or lists these screens
  (`XcodeGrep` first), `docs/plans/0046-today-insights/execution.md`, `retrospective.md`,
  `docs/plans/INDEX.md`, `docs/DEVLOG.md`, `.claude/context/current-focus.md`,
  `.claude/context/open-questions.md`

- [ ] **Step 1: Build** zero warnings (`BuildProject`, `GetBuildLog`).
- [ ] **Step 2: Full suite** — `RunAllTests` (D0046-16). If MCP returns an incomplete bundle,
  re-run in batches of about 10 classes; record which. Expected: green except open-questions
  entries named by test.
- [ ] **Step 3: Coverage** — `RiskLevel+Status`, `LimitGaugeRow.fraction` 100 %; view models
  ≥ 90 %. MCP has no coverage report: ask the owner before the AGENTS.md CLI coverage command;
  record the answer.
- [ ] **Step 4: File size + privacy** — AGENTS.md `find` command; no new network, no PII in
  logs, no `print`.
- [ ] **Step 5: Docs close-out** — execution.md (doc sources per task), retrospective, INDEX
  (completed), DEVLOG, current-focus (next: step 7 Add / Edit Drink, plan 0047),
  open-questions (close "Insights hero card height test fails"; Today / Insights audit lines;
  add the device checks below and any new item); commit `[plan-0046] docs: close plan`.
- [ ] **Step 6:** `git switch ui-revamp && git merge --no-ff port/0046-today-insights`; ask the
  owner about push.

## Device check (owner)

- Logging a drink on Today: hero count-up, arc sweep, glyph Replace when the level changes,
  gauges fill, week bar grows, one haptic (shell); all still under Reduce Motion.
- Streak trophy bounces once per launch (≥ 1 day), not on every tab switch.
- Rounded large title "Today" / "Insights" collapses correctly on scroll; subtitle readable.
- Insights ← / → / "Today": numbers roll in the navigation direction, chart morphs (no
  cross-fade); VoiceOver hears the announcement once per change.
- Light / Dark / Increase Contrast: hero mesh, glyph cut-out, tint off under Increase Contrast.

## Open questions

- [x] D0046-1 (owner, 2026-11-21): the screen is "Today" (tab and title).
- [x] D0046-6 (owner, 2026-11-21): This Week stays the calendar week.
- [x] D0046-11 (owner, 2026-11-21): weekday chart without scrubbing.
- [x] D0046-15 (owner, 2026-11-21): Today / Insights `VOICE.md` rows applied here; heavy-day
      definition "60 g or more in a day", logic unchanged.
- [ ] D0046-16: full suite at the end of this step (AGENTS.md escalation) or scoped batches.

## Tests required

New: `RiskLevelStatusTests`, `LimitGaugeRowTests`, `InsightsViewModelTests+Announcement`, slot
tests (Swift Testing); `TodayStatusUITests`, `InsightsNavigationUITests`. Updated:
`DashboardUITests`, `ReduceMotionDashboardUITests`, `DashboardDynamicTypeUITests`, Insights UI,
scrub, streak, drink-free-days and dynamic type tests, the three audit classes, every UI test
that looked up "Home". Removed with their code: greeting tests, the weekday-callout scrub test,
the hero-height test (replaced). Gate: full suite at the end of this step (D0046-16).
