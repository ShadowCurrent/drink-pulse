---
phase: 05-insights-chart-scrubbing
reviewed: 2026-07-30T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift
  - drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift
  - drinkpulse/Features/Insights/Components/InsightsHeroCard.swift
  - drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift
  - drinkpulse/Features/Insights/Components/WeekdayBarChart.swift
  - drinkpulse/Features/Insights/InsightsChartModels.swift
  - drinkpulseTests/Features/Insights/AlcoholAreaChartAXDescriptorTests.swift
  - drinkpulseTests/Features/Insights/WeekdayBarChartAXDescriptorTests.swift
  - drinkpulseUITests/Features/Insights/InsightsScrubUITests.swift
findings:
  critical: 2
  warning: 2
  info: 2
  total: 6
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-07-30
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed Wave 1 (`chartXSelection` drag-to-scrub with RuleMark + glass-chip
callouts, hero-headline sync) and Wave 2 (`AXChartDescriptorRepresentable`
Audio Graph support) of the Insights chart scrubbing phase.

The good news first: the explicit design goal — that the visual callout and
the VoiceOver Audio Graph must never format a value independently — is
honored. `AlcoholAreaChart` and its `AlcoholAreaChartAXDescriptor` both take
the same injected `formattedValue` closure (never hand-formatted separately),
and `WeekdayBarChart`'s three formatting call sites (`accessibilityLabel`,
scrub callout, `WeekdayBarChartAXDescriptor`) all use the identical
`String(format: "%.1f", …) + unitLabel` expression, consistent with the
documented D-09 "dumb view" decision to not thread `vm.formattedValue`
through this component. No PII/health-data logging, no force-unwraps, and no
files over the 300-line ceiling were found.

However, both new chart components share a structural bug in how the
scrub `RuleMark` + callout are attached to the `Chart` builder: the
selection condition is placed inside the *per-data-point* content closure
but does not actually depend on that data point, so the `RuleMark` and its
annotation are emitted once **per data point** rather than once total. This
is 100%-reproducible on every scrub gesture and is not caught by the
existing UI tests (which only assert *existence*, not *count*, of the
callout/RuleMark element). This is classified Critical because it is a
functional defect in the exact feature this phase implements, not an edge
case.

There are also two accessibility-audio-graph divergence issues and two
minor maintainability/DRY items — see below.

## Critical Issues

### CR-01: Scrub RuleMark + callout duplicated once per data point in `AlcoholAreaChart`

**File:** `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift:49-58`
**Issue:**
`Chart(data) { point in … }` is Swift Charts' *per-element* content
builder — the trailing closure runs once for every item in `data`, and
whatever marks it emits during that invocation are added to the plot for
that element. The `RuleMark`/annotation block:

```swift
if let selectedKey, let date = dateByKey[selectedKey] {
    RuleMark(x: .value(String(localized: "insights.chart.axis.date"), selectedKey))
        .foregroundStyle(Color.secondary.opacity(0.3))
        .annotation(...) { calloutView(date: date) }
}
```

does not reference the closure's own `point` parameter at all — it
re-resolves the selected point independently via `dateByKey[selectedKey]`.
Because the condition is identical on every iteration, as soon as
`selectedKey != nil` (i.e. during every scrub drag) this block evaluates
to `true` on **all** iterations of `data`, not just the one matching
point. For a week view (7 points) that's 7 stacked, fully overlapping
`RuleMark`s and 7 stacked glass-chip callout views rendered at the exact
same position every time a user scrubs; for month/year/allTime views the
duplication scales with the point count. This also injects N duplicate
default-accessibility elements into the VoiceOver swipe order at the same
location (confirmed by `InsightsScrubUITests.sampleWeekdayCalloutDuringHold`,
which already relies on `.firstMatch` rather than asserting a count —
the existing UI tests do not catch this).

**Fix:** Gate the block on the *current* iteration's point instead of
re-deriving the selection independently, so the mark is emitted exactly
once across the whole builder invocation:

```swift
Chart(data) { point in
    AreaMark(...)
    LineMark(...)

    if selectedKey == ChartPoint.key(for: point.date) {
        RuleMark(x: .value(String(localized: "insights.chart.axis.date"), ChartPoint.key(for: point.date)))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .annotation(
                position: .top,
                overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
            ) {
                calloutView(date: point.date)
            }
    }
}
```

### CR-02: Scrub RuleMark + callout duplicated once per bar in `WeekdayBarChart`

**File:** `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift:19-38`
**Issue:** Identical root cause to CR-01. `Chart(bars) { bar in … }` runs
once per bar; the selection block re-binds its own `bar` via
`bars.first(where: { $0.label == selectedLabel })`, shadowing the outer
`bar` parameter, and never references the outer `bar` in its guard
condition:

```swift
if let selectedLabel, let bar = bars.first(where: { $0.label == selectedLabel }) {
    RuleMark(x: .value(String(localized: "insights.chart.axis.weekday"), selectedLabel))
        ...
}
```

With 7 weekday bars, every scrub renders 7 identical, fully-overlapping
`RuleMark`s and 7 stacked callout chips at the same x position — this is
what `InsightsScrubUITests.test_scrubbingWeekdayChart_showsCallout`
actually exercises, but the test only checks `.firstMatch.exists`, so the
7x duplication passes silently today.

**Fix:** Gate on the current iteration's `bar` directly (no re-lookup
needed):

```swift
Chart(bars) { bar in
    BarMark(...)
        .foregroundStyle(color(for: bar.riskLevel))
        .cornerRadius(4)
        .accessibilityLabel("\(bar.label): \(String(format: "%.1f", displayValue(bar))) \(unitLabel)")

    if selectedLabel == bar.label {
        RuleMark(x: .value(String(localized: "insights.chart.axis.weekday"), bar.label))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .annotation(
                position: .top,
                overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
            ) {
                calloutView(bar: bar)
            }
    }
}
```

## Warnings

### WR-01: Accessibility Audio Graph category labels lose the year and become ambiguous for multi-year data

**File:** `drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift:19,33`
**Issue:** `AlcoholAreaChartAXDescriptor` is constructed without `period`
(`AlcoholAreaChart.swift:75` only passes `data` and `formattedValue`), and
unconditionally formats every x category as
`.dateTime.month(.wide).day()`:

```swift
categoryOrder: data.map { $0.date.formatted(.dateTime.month(.wide).day()) }
...
dataPoints: data.map { .init(x: $0.date.formatted(.dateTime.month(.wide).day()), y: $0.grams) }
```

For `.week`/`.month` this merely diverges cosmetically from the visual
x-axis (which uses weekday/day+month formats per `xAxisFormat`), but for
`.allTime`, `InsightsViewModel.seriesData` buckets by calendar month across
potentially several years (`monthlyBuckets`, all bucket keys are the 1st
of a month), so two points a year apart both format to the literal same
string, e.g. `"January 1"` for both January-2025 and January-2026. The
audio-graph category order and each data point's `x` label become
non-unique/ambiguous for any user with more than one year of history —
degrading exactly the VoiceOver feature this wave adds, with no way for a
listener to tell which year's January they're on.

**Fix:** Always include the year in the descriptor's category label
(independent of `period`, so no new parameter is required), or better,
thread `period` through and reuse the same format used for the visible
x-axis so the audio graph and the visible chart never disagree:

```swift
categoryOrder: data.map { $0.date.formatted(.dateTime.year().month(.wide).day()) }
```

### WR-02: `Dictionary(uniqueKeysWithValues:)` is a latent crash if `data` ever contains two points on the same date

**File:** `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift:105-107`
**Issue:**

```swift
private var dateByKey: [String: Date] {
    Dictionary(uniqueKeysWithValues: data.map { (ChartPoint.key(for: $0.date), $0.date) })
}
```

`Dictionary(uniqueKeysWithValues:)` traps at runtime if any two elements
of `data` produce the same key (same `date`, since `ChartPoint.key` is a
pure function of `date`). Today this is safe only because both call
sites in `InsightsViewModel+Charts.swift` happen to guarantee unique dates
(`activeDays.map` for week/month, and a `[Date: Double]` dictionary keyed
by month-start for year/allTime). `AlcoholAreaChart` is explicitly
documented as a reusable "pure chart view... embed inside `InsightsHeroCard`
or any container" with no validation on `data`, so this uniqueness
invariant is enforced nowhere near the type that depends on it — any
future caller (or a refactor of `seriesData`) that supplies two points for
the same date will crash the Insights screen. This is the same category of
risk the project's "no force-unwraps in production code" rule exists to
prevent, just via `Dictionary(uniqueKeysWithValues:)` instead of `!`.

**Fix:** Use a non-trapping construction with an explicit last-wins (or
first-wins) policy:

```swift
private var dateByKey: [String: Date] {
    Dictionary(data.map { (ChartPoint.key(for: $0.date), $0.date) }, uniquingKeysWith: { _, new in new })
}
```

## Info

### IN-01: Divisor-guard and value-formatting expressions triplicated instead of centralized

**File:** `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift:66-67,73`, `drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift:20,33`
**Issue:** The "safe divisor" guard `unitDivisor > 0 ? unitDivisor : 1.0`
is written out independently in `WeekdayBarChart.displayValue(_:)` and
again as `WeekdayBarChartAXDescriptor.safeDivisor`. Likewise, the value
string `String(format: "%.1f", …) + " " + unitLabel` is written
independently three times: the per-bar `accessibilityLabel`, `calloutView`,
and the descriptor's `valueDescriptionProvider`. All three currently agree,
but nothing enforces that going forward — a future precision or divisor
change is one edit away from silently diverging one of these three sites
from the others (the exact drift class this phase's own design doc calls
out as a risk for `AlcoholAreaChart`).
**Fix:** Extract a single `WeekdayBar.displayValue(divisor:)` (or a shared
free function) and a single formatting helper (e.g.
`func formattedUnitValue(_ value: Double, unitLabel: String) -> String`)
that all three call sites — and the descriptor — call through.

### IN-02: `WeekdayBarChart` has no explicit selection reset on period/data change, unlike `AlcoholAreaChart`

**File:** `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift:12`, `drinkpulse/Features/Insights/Components/InsightsHeroCard.swift:21`
**Issue:** `InsightsHeroCard` explicitly clears `AlcoholAreaChart`'s
selection on period change (`.onChange(of: vm.period) { selectedKey = nil }`),
but `WeekdayBarChart` owns its `selectedLabel` as private `@State` with no
equivalent reset when its `bars` input changes (e.g. on a period switch in
`InsightsView`). In practice `chartXSelection` is documented elsewhere in
this phase's own UI test comments as clearing its binding as soon as the
touch lifts, so this is unlikely to be observable in normal single-touch
use — but the two sibling components now handle the same concern
inconsistently, which is worth aligning for defense-in-depth (e.g. a stale
selection surviving a multi-touch edge case would show a `RuleMark` for
"Fri" against the *new* period's data with no indication anything changed).
**Fix:** Either document why `WeekdayBarChart` doesn't need the reset, or
add the same `.onChange(of: bars) { selectedLabel = nil }` safeguard used
by its sibling.

---

_Reviewed: 2026-07-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
