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
