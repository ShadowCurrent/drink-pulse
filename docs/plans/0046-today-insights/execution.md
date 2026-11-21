# 0046 — Execution journal

Append-only. Dated entries.

## 2026-11-21 — Setup

- Branch `port/0046-today-insights`, main checkout, Xcode MCP workspace `drinkpulse.xcodeproj`,
  destination iPhone 18 Pro simulator (iOS 27.2).
- Executor: superpowers `executing-plans`, inline.
- Reading source files uses read-only shell `cat` / `grep` (no `xcodebuild` / `xcrun`); edits,
  builds and tests go through Xcode MCP.
- String Catalog: `StringCatalogEdit` requires a translation skill that is not installed in this
  session, so `Localizable.xcstrings` values are set with a small JSON script that keeps Xcode's
  format (round trip checked byte-identical before the first edit).

## 2026-11-21 — Task 1: pure presentation logic

Docs (Xcode MCP `DocumentationSearch`):
- `Chart.init(_:id:content:)` — "Creates a chart composed of a series of marks", identity from
  the `id` key path (Charts).
- `LocalizedStringResource` / `String(localized:)` interpolation (Foundation).
- HIG Charts › Enhancing the accessibility of a chart; Best practices: "Help people notice
  important changes in a chart … highlight the changes in other ways, too, to ensure that
  VoiceOver users and people who turn off animations know about them" (basis for D0046-14).

Done:
- `DesignSystem/RiskLevel+Status.swift`: `statusTitle` (from `dashboard.risk.*`, values now
  Within Limit / Close to Limit / Over Limit), `statusSymbol`.
- `ChartPoint` gains `slot` (id = slot); `seriesData` numbers the week / month days and the
  sorted month buckets.
- `InsightsViewModel+Announcement.swift`: `periodAnnouncement`, `spokenTotal(_:)`; keys
  `insights.announce.grams` / `.standardDrinks` / `.units`.
- Tests: `RiskLevelStatusTests`, `InsightsViewModelTests+Announcement`,
  `InsightsViewModelTests+Slots` (new file: `+Aggregates` is already 335 lines).

Deviations:
- Year slots: the current year keeps only the months up to now (existing test
  `seriesData_currentYearHasMonthsUpToNow`), so `test_seriesSlots_year_areZeroToEleven` uses the
  previous year. No change to the series range.
- `greetingText` is removed in Task 3 with the view that reads it (the build needs it until then).
- `ChartPoint.key(for:)` kept until Task 5 removes the categorical chart.

Result: `RunSomeTests` RiskLevelStatusTests, InsightsViewModelTests, AlcoholAreaChartAXDescriptorTests,
DashboardViewModelTests — 153 / 153 passed (RED first: build failed on the missing members).

## 2026-11-21 — Task 2: shared card components

Docs (Xcode MCP `DocumentationSearch`):
- `GaugeStyle.linearCapacity` — "a bar that fills from leading to trailing edges … The `label`
  appears above the gauge"; `Gauge` note: "the accessibility system does use the label content";
  `tint(_:)` example on a `.linearCapacity` gauge (SwiftUI).
- `ContentUnavailableView.init(label:description:actions:)`; `LabeledContent.init(content:label:)`;
  `ViewThatFits` ("selects the first child whose ideal size on the constrained axes fits").

Done:
- `DesignSystem/LimitGaugeRow.swift` (`fraction(consumed:limit:)` = 0 when limit ≤ 0; optional
  `motionProbeSite`), `MetricTile.swift`, `TilePair.swift`, `NoDrinksYetView.swift`
  (`empty.logADrink` identifier), `NumbersCountDown.swift` (`@Entry numbersCountDown`, needed by
  the gauge and later Insights).
- History uses `NoDrinksYetView`; `HistoryEmptyView.swift` deleted; `history.logADrink` →
  `common.logADrink`.

Deviations:
- The gauge percent keeps the old truncation (`Int(fraction * 100)`) instead of the prototype's
  rounded `.percent` format, so no displayed number changes.
- The gauge row is one accessibility element: label = title, value = "x of y unit, n percent"
  (the old row's wording, now as value).
- Preview render of `LimitGaugeRow` checked (Light); Dark / AX5 renders checked on the Today
  screen in Task 3.

Result: `RunSomeTests` LimitGaugeRowTests (3), HistoryDaySectionsUITests/test_emptyHistory_logADrink_opensAddDrink — 4 / 4 passed (RED first: `LimitGaugeRow` not in scope).

## 2026-11-21 — Task 3: Today screen

Docs (Xcode MCP `DocumentationSearch`): `navigationSubtitle(_:)` ("On iOS and iPadOS, the subtitle
is displayed with the navigation title in the navigation bar"). `MeshGradient`, `ToolbarItemPlacement
.largeTitle`, `contentTransition` / `numericText`, `symbolRenderingMode(.palette)`, symbol Replace,
`RuleMark`, `AxisMarks(values: .stride(by:count:))`, `colorSchemeContrast` and the HIG pages listed
in the plan were checked while drafting the plan (plan "Context", 2026-11-21) and not re-queried.

Done:
- `TodayHeroCard` (mesh, ink, `ViewThatFits`, combined element `today.hero`, label = eyebrow,
  value, today's status), `HeroGauge` (`DPArcProgress` + percent, `@ScaledMetric` 88 / 9),
  `HeroStatusLabel` (`toneCutOut` palette glyph, Replace, identifier `today.status`).
- `ConsumptionOverviewCard.swift` moved (`XcodeMV`) to `GuidelineLimitsCard.swift`, rewritten on
  `LimitGaugeRow` (Today rows keep the `overviewBar` probe).
- `ThisWeekCard`: `GroupBox` + `CardTitle`, date x-axis (every second day at AX sizes), risk-tone
  bars, dashed daily-limit rule only when the effective limit > 0, per-bar label + value.
- `GuidelineAlertCard`: `GroupBox` + `Label` in the exceeded tone, `dashboard.alert.body`,
  identifier `today.alert`.
- `DashboardView`: `brandBackground`, `brandNavigationTitle("tab.home")` ("Today"),
  `navigationSubtitle` date · guideline, tiles (`MetricTile` / `TilePair`), no greeting or
  `RiskBadge`. Deleted `DashboardHeroCard`, `DashboardChipRow`, `DPChip`, `StreakCard`;
  `greetingText`, `effectiveRiskLevel` and their tests removed.
- `DPArcProgress` accessibility: label "Daily limit" (`dashboard.hero.gaugeLabel`, new key),
  value = rounded, uncapped percent (`percentText`, also the visible percent).
- Test seed: dataset `overweekly` (two heavy days 1 and 2 days ago, nothing today; test-only,
  no PII) in `UITestSeed+Fixtures.swift`.
- Strings (D0046-15): `tab.home` Today, `dashboard.hero.eyebrow`, `dashboard.streak.*`,
  `dashboard.overview.title` / `.overLimit`, `dashboard.alert.title` / `.body`,
  `dashboard.limit.caption`; `dashboard.greeting.*` removed.

Deviations:
- `today.status` cannot be read on its own: it sits inside the hero's one combined element
  (D0046-2). `TodayStatusUITests` reads the status from `today.hero`'s label instead.
- Hero figures do not count up on the initial load (gated like `DPArcProgress`); found in the
  AX5 preview render, where the snapshot caught the value mid-transition from 0. The first-run
  entrance stays step 8.
- The hero arc percent is rounded, the gauge row percent truncated (114 % vs 113 % in the Dark
  render). Both are the pre-existing rules of the old hero and old rows; unchanged (no
  displayed-number change). Open question added.
- The AX-size value branch (D0046-2) is not carried over; it returns only if the Task 7 AX5 audit
  flags the hero value.
- `UITestTabs.swift` is created here (Task 3 tests need it), not in Task 4.
- The Task 3 step 4 classes that look up "Home" (`ReduceMotionDashboardUITests`,
  `DashboardDynamicTypeUITests`, `ProbeAccessibilityAuditUITests`) run after the Task 4 rename.

Renders (`RenderPreview`): Today Light, Dark, Over limit AX5 — layout as the prototype.
- AX5: `LimitGaugeRow` truncated its value ("10.0 st…") inside the gauge label (the gauge style
  keeps its label to one line). Fix: title / value moved above the gauge in a `ViewThatFits`
  (side by side, else stacked and wrapping); the gauge itself gets an empty label (the row's
  accessibility element carries label and value).

Result (Task 3): `RunSomeTests` DashboardUITests 6 / 6, TodayStatusUITests 1 / 1,
ReduceMotionDashboardUITests 4 / 4, ProbeAccessibilityAuditUITests 2 / 2, DashboardViewModelTests
green, `DashboardDynamicTypeUITests.test_home_atAX5_keepsPrimaryElementsReachable` green after the
tile labels were updated. Open: `test_home_atAX5_hasNoClippedOrFixedSizeText` — `textClipped`,
element `none#type=nil`, scroll pages 2–3; carried to Task 7 (audit fixes) by the plan.
Tooling note: `RunSomeTests` / `GetTestList` still listed the deleted `greetingText` /
`effectiveRiskLevel` tests as "Passed" from a stale test index; `XcodeGrep` confirms they are gone
from source and the build is clean.

## 2026-11-21 — Task 4: "Home" → "Today" in UI tests

Files changed (`"Home"` → `UITestTabs.today`; two enum raw values `case home = "Today"`):
AddDrink — `AddDrinkAccessibilityAuditUITests`, `AddDrinkDynamicTypeUITests`, `AddDrinkFlowUITests`,
`AddDrinkPickerFilterUITests`, `CurrencyUITests`, `CustomNameAutocompleteUITests`,
`VolumeServingUITests`; Dashboard — `DashboardAccessibilityAuditUITests`,
`DashboardDynamicTypeUITests`, `DashboardOverLimitAccessibilityAuditUITests`,
`ReduceMotionDashboardUITests` (`DashboardUITests` rewritten in Task 3); Onboarding —
`OnboardingFlowUITests`, `OnboardingHealthStepUITests`, `OnboardingWeeklySummaryUITests`; Shell —
`AccessibilityAuditUITests`, `LaunchHandoffUITests`, `OnboardingAuthorityUITests`,
`ProbeAccessibilityAuditUITests`, `ShellNavigationUITests`, `SheetDismissTabSwitchUITests`,
`StartupErrorUITests`. 21 files (plan said 20) + `DashboardUITests`.

Runs: batch 1 (AddDrinkFlow, PickerFilter, Currency, CustomNameAutocomplete, VolumeServing,
AddDrinkDynamicType, LaunchHandoff, StartupError, OnboardingAuthority) 21 / 22 — failed
`AddDrinkFlowUITests.test_originatingSettingsTab_save_persistsAndReturnsToSettings` ("Add Drink
button should be visible"): Settings has had no `+` since plan 0044. Owner (2026-11-21): the `+`
stays out of Settings. The test now runs the same originating-tab save from Insights
(`test_originatingInsightsTab_save_persistsAndReturnsToInsights`, passed); the absence on Settings
stays pinned by `ShellNavigationUITests.test_addDrinkButton_absentOnSettings`.
Batch 2 (OnboardingFlow, OnboardingHealthStep, OnboardingWeeklySummary, SheetDismissTabSwitch,
ShellNavigation, AccessibilityAudit, AddDrinkAccessibilityAudit) 14 passed, 18 skipped (gated
`AccessibilityAuditUITests` and the two scheme-skipped harness tests), 0 failed. Dashboard audit
classes run in Task 7.

## 2026-11-21 — Task 5: Insights hero and area chart

Docs: `chartXSelection` and `PlottableValue.value(_:_:unit:calendar:)` were checked while
drafting (plan "Context"); a `DocumentationSearch` for `chartXSelection` in this session returned
only unrelated Charts symbols.

Done:
- `AlcoholAreaChart`: `Chart { ForEach(data, id: \.slot) }`, date x-values with `unit: .day` /
  `.month`, accent area (`.tint.opacity(0.25)`) + line, `.monotone`, dashed daily-limit rule +
  caption for Week / Month (none when the limit is 0), `chartXSelection(value:)` with a
  `RuleMark` at the selection, axis `desiredCount` 3 (Y) / 2 (X) at AX sizes. The y axis is shown
  and reads in the user's unit (`unitDivisor`); the descriptor still reports raw grams.
  Mark accessibility label = the same date text the hero shows (`dateText(_:period:)`).
- `InsightsHeroCard`: `GroupBox` + `CardTitle` "Total", total or selected value, selected date
  (`insights.hero.selectedDate`) or the neutral trend line (`insights.hero.vsPrev` →
  "%1$@ vs previous %2$@ (%3$@)"); selection cleared on period and offset change.
- Removed: `TrendBadge`, `ChartPoint.key`, `labelKeys`, the in-chart empty text; keys
  `insights.trend.unchanged`, `insights.areaChart.empty`.
- Tests: scrub test also asserts the date line during the hold; the weekday-callout scrub test
  is removed (owner, D0046-11); the audit mark test is now
  `test_insights_standard_markLabelMatchesSelectedDate` and ignores the "Daily limit" rule element
  when counting day marks.

Deviation: the RED run was not separate — the simulator was busy with the Task 4 batches; RED was
established structurally (`XcodeGrep`: `insights.hero.selectedDate` absent from app source) and
the GREEN run followed the build.

Result: `RunSomeTests` InsightsScrubUITests 1 / 1, markLabelMatchesSelectedDate 1 / 1,
AlcoholAreaChartAXDescriptorTests 4 / 4, InsightsViewModelTests green (79 / 79 in the run).
Render: hero card Light.

## 2026-11-21 — Task 6: Insights page, cards, empty state, announcement

Docs: `AccessibilityNotification.Announcement` (`post()`), `ButtonBorderShape.circle`,
`ToolbarItemPlacement.topBarLeading`, `GridItem.Size.adaptive(minimum:maximum:)`, `@Entry` and
HIG Segmented controls / Charts › Best practices / Toolbars were checked while drafting (plan
"Context"); the Best-practices quote for announcing changes was re-read in Task 1.

Done:
- `InsightsPeriodPicker` (own `View`, `.segmented` / `.menu` at AX sizes);
  `InsightsScopeNavigator.swift` moved (`XcodeMV`) to `InsightsPeriodNavigator.swift`: bordered
  circle icon-only buttons (`insights.nav.previous` / `.next`, existing enable rules), centre
  `friendlyLabel` over `rangeLabel` with `numericText(countsDown:)`; no "NOW" pill, no tappable
  centre; hidden in All.
- `InsightsView`: `NoDrinksYetView` when there are no events at all, `brandBackground`,
  `brandNavigationTitle("tab.insights")`, toolbar "Today" (`insights.nav.todayButton`, only off
  the current period), period / offset changes through `withMotion`, `numbersCountDown` by
  direction, `AccessibilityNotification.Announcement(vm.periodAnnouncement)` on every
  `(period, offset)` change. Previews moved to `InsightsView+Previews.swift` (Light, Dark, AX5,
  Empty).
- `HealthMetricsCard`: `GroupBox`, adaptive `LazyVGrid` (`@ScaledMetric` minimum 150), cells with
  natural-colour icons; Heavy Days detail "60 g or more in a day"; longest streak with inflected
  "day(s)"; cell accessibility label "title: value" (UI tests parse it), detail as value.
- `WeekdayBarChart`: `GroupBox`, accent bars, per-bar label + value, descriptor kept; selection,
  `PointMark` and callout removed. `dpChartCalloutBackground` deleted from `DPGlass.swift`.
  `WeekdayBar.riskLevel` stays (descriptor tests use it).
- `GuidelineComparisonCard`: `GroupBox` + one `LimitGaugeRow` per guideline, " ✓" on the user's
  guideline; new `InsightsViewModel.formattedNumber(_:)` (presentation only, tested).
- Strings (D0046-15): `insights.metric.*` values, `insights.metric.heavyDays.detail`,
  `insights.empty.*`, `insights.nav.today`; removed `insights.metric.riskLevel`,
  `insights.nav.now`, `insights.nav.jumpToNow`, `insights.guideline.ofLimit` (no readers).
- Tests: new `InsightsNavigationUITests` (5); `InsightsUITests` height test removed (replaced by
  `test_allTimeScope_hidesNavigator_keepsChart`), comparison test asserts gauge rows;
  `InsightsStreakUITests` / `InsightsDrinkFreeDaysUITests` on the new labels.

Deviations:
- Guideline comparison rows use the shared `LimitGaugeRow` wording ("x of y unit, n percent")
  instead of the old "n% of limit" label (D0046-12 said keep it): one wording for every limit
  gauge on Today and Insights.
- Weekday y-domain headroom 1.6 → 1.2 (the old headroom made space for the removed callout).

Result: `RunSomeTests` InsightsNavigationUITests 5 / 5 (RED first: 2 / 2 failed on the missing
navigator identifier and empty state), InsightsUITests 6 / 6, InsightsStreakUITests 1 / 1,
InsightsDrinkFreeDaysUITests 1 / 1, InsightsDynamicTypeUITests 2 / 2, InsightsScrubUITests 1 / 1,
WeekdayBarChartAXDescriptorTests 4 / 4, InsightsViewModelTests green.

## 2026-11-21 — Task 7: audit classes on the new UI

Docs: XCTest `performAccessibilityAudit(for:_:)` / `XCUIAccessibilityAuditType` and the audit
helpers in `AccessibilityAuditSupport.swift` (owner decisions D11-29 … D11-31) — checked while
drafting; not re-queried.

First run (Dashboard / DashboardOverLimit / Insights audit classes + DashboardDynamicType):
4 / 10 passed. Findings:
- `dynamicType` on almost every text of the hero, the tiles, the gauge rows (Today) and the
  Health Impact cells (Insights), standard and dark; `textClipped` on the gauge values and the
  hero value; AX5 `textClipped` (element-less) on scroll pages 2–5.
- `contrast` on `today.status` (dark over limit); element-less `contrast` on Insights (4
  standard, 1 dark); `hitRegion` on the area-chart day marks (dark / standard).
- `DashboardOverLimitAccessibilityAuditUITests` still looked for "High Risk".

Cause found by bisection (one change per run of `test_home_standard`):
- Not `numericText` (removed from `MetricTile`: still flagged); not the merged accessibility
  element (removed: still flagged).
- `ViewThatFits`: replacing it in `TilePair` with a Dynamic Type branch removed every tile
  finding. The audit evidently measures the alternative that is not shown. Same fix in
  `TodayHeroCard` (HStack / VStack at AX sizes) and `LimitGaugeRow` (`LabeledContent`, stacked
  at AX sizes, no `lineLimit`); `HealthMetricsCard` `LazyVGrid(.adaptive)` → two-column `Grid`,
  one column at AX sizes (the old card had the same finding, open-questions baseline).
- Insights element-less `contrast`: not the chart axes, not the navigator centre, not the
  bordered buttons (each bisected away with no change); the count moved only when the page
  content shifted relative to the tab bar. Treated under the existing owner decision D11-31
  (`ignoreTabBarElementlessContrast`, as History) for Insights standard / dark and Today dark
  over limit; each ignored issue is still recorded as a warning by the helper.
- Chart axis labels (area and weekday) use `dpSecondaryText` (default grey is under 4.5:1 on the
  card); kept although not the element-less cause.
- `today.status` contrast and the day-mark `hitRegion` findings did not recur after the layout
  fixes.
- Over-limit test reads the hero label ("Over Limit") instead of "High Risk".

Result: `RunSomeTests` DashboardAccessibilityAuditUITests 3 / 3,
DashboardOverLimitAccessibilityAuditUITests 1 / 1, InsightsAccessibilityAuditUITests 4 / 4,
DashboardDynamicTypeUITests 2 / 2, InsightsDynamicTypeUITests 2 / 2.

Deviation: D0046-4 / D0046-10 asked for `ViewThatFits` / an adaptive grid "without a branch"; the
audit result overrules it (Dynamic Type branches, as the app used before).

## 2026-11-21 — Task 8: gates, docs, close

- Build (`BuildProject`, build for testing): succeeded, `GetBuildLog` severity warning: 0.
- Scoped re-run (D0046-16): batch A (RiskLevelStatus, LimitGaugeRow, AlcoholAreaChartAXDescriptor,
  WeekdayBarChartAXDescriptor, ArcShape, DashboardUITests, TodayStatus, ReduceMotionDashboard,
  ProbeAccessibilityAudit, History empty state) 35 / 35; batch B (InsightsUITests,
  InsightsNavigation, InsightsScrub, InsightsStreak, InsightsDrinkFreeDays,
  InsightsViewModelTests, DashboardViewModelTests) 162 / 162; batch C (OnboardingFlow,
  LaunchHandoff, ShellNavigation, AddDrinkFlow, OnboardingAuthority) 21 / 21; audit + Dynamic Type
  classes 12 / 12 in Task 7 on the final layout code. The other Task 4 rename-only classes ran
  green in Task 4 and touch no code Task 7 changed.
- Coverage: not measured — MCP has no coverage report; the AGENTS.md CLI command needs the owner's
  approval (asked at the end of the session).
- File size: no Swift file over 300 lines. Privacy: no new network, `print`, or logging; the one
  new `try?` (`Task.sleep` in `MetricTile`) carries its comment.
- Docs: `docs/architecture.md` (shared components, the `ViewThatFits` rule, chart rules, Today /
  Insights), `README.md` (Today / Insights features), `retrospective.md`, `INDEX.md` (completed,
  next 0047), `DEVLOG.md`, `current-focus.md`, `open-questions.md` (hero-height entry closed, Today /
  Insights audit lines removed, "Plan 0046 open items" added, plan 0044 gate entry updated).
- Final review: self-review of the branch diff (no reviewer subagent in this session); no
  Critical / Important finding.
