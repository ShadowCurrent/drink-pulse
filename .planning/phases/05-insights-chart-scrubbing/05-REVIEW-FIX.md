---
phase: 05-insights-chart-scrubbing
fixed_at: 2026-07-30T14:04:04Z
review_path: .planning/phases/05-insights-chart-scrubbing/05-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 05: Code Review Fix Report

**Fixed at:** 2026-07-30T14:04:04Z
**Source review:** .planning/phases/05-insights-chart-scrubbing/05-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (critical_warning scope — 2 Critical, 2 Warning; the 2 Info findings were out of scope)
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: Scrub RuleMark + callout duplicated once per data point in `AlcoholAreaChart`

**Files modified:** `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift`
**Commit:** `254ae6a`
**Applied fix:** Replaced the independent re-derivation `if let selectedKey, let date = dateByKey[selectedKey]`
inside the per-point `Chart(data) { point in ... }` closure with a guard on the closure's own
iteration element: `if selectedKey == ChartPoint.key(for: point.date)`. The `RuleMark`/annotation
now references `point.date` directly instead of re-resolving through `dateByKey`, so it is emitted
exactly once per `Chart` builder invocation instead of once per data point.

### CR-02: Scrub RuleMark + callout duplicated once per bar in `WeekdayBarChart`

**Files modified:** `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift`
**Commit:** `2630a34`
**Applied fix:** Replaced `if let selectedLabel, let bar = bars.first(where: { $0.label == selectedLabel })`
(which shadowed the outer `bar` and never referenced it) with `if selectedLabel == bar.label`, gating
directly on the closure's own iteration element with no re-lookup needed.

### WR-01: Accessibility Audio Graph category labels lose the year and become ambiguous for multi-year data

**Files modified:** `drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift`
**Commit:** `71e8934`
**Applied fix:** Changed both the `categoryOrder` and `dataPoints` `x` formatting in
`AlcoholAreaChartAXDescriptor.makeChartDescriptor()` from `.dateTime.month(.wide).day()` to
`.dateTime.year().month(.wide).day()`, so the audio-graph category labels are always unique across
years (relevant for `.allTime`, which buckets by calendar month across potentially multiple years).
No new parameter/threading of `period` was needed per the review's suggested minimal fix.

### WR-02: `Dictionary(uniqueKeysWithValues:)` is a latent crash if `data` ever contains two points on the same date

**Files modified:** `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift`
**Commit:** `e18c407`
**Applied fix:** Replaced the trapping `Dictionary(uniqueKeysWithValues:)` in `AlcoholAreaChart.dateByKey`
with the non-trapping `Dictionary(_:uniquingKeysWith:)` using a last-wins policy
(`{ _, new in new }`), removing the crash risk for any future caller that supplies two points on the
same date, while preserving current behavior for all existing call sites (which already guarantee
uniqueness).

## Skipped Issues

None — all in-scope findings were fixed.

## Verification

- `xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`:
  **BUILD SUCCEEDED**, zero warnings attributable to modified code (only the pre-existing, unrelated
  `appintentsmetadataprocessor` "no AppIntents.framework dependency found" notice, present regardless
  of these changes).
- `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
  scoped to the affected targets:
  - `drinkpulseTests/AlcoholAreaChartAXDescriptorTests` — 4 tests passed.
  - `drinkpulseTests/WeekdayBarChartAXDescriptorTests` — 4 tests passed.
  - `drinkpulseUITests/InsightsScrubUITests` — 2 tests passed
    (`test_scrubbingAreaChart_updatesHeroTotal_andRevertsOnRelease`,
    `test_scrubbingWeekdayChart_showsCallout`).
  - Total: 10 tests, 0 failures.

Note: the existing UI tests only assert `.firstMatch.exists` for the RuleMark/callout element (per
the review's own observation), so they do not add a regression-proof assertion on element *count*
for CR-01/CR-02. The fixes were verified by inspection against Swift Charts' per-element content
builder semantics and confirmed not to regress the existing suite; adding a count-based assertion
was out of scope for this fix pass (no such finding/fix was specified in REVIEW.md) but would be a
reasonable follow-up.

## Logic-bug flag

None of the four fixes are logic-correctness changes requiring separate human sign-off beyond normal
review — CR-01/CR-02 are structural closure-scoping corrections (well-understood Swift Charts
semantics, confirmed by existing passing UI tests), and WR-01/WR-02 are direct application of the
fix suggested in REVIEW.md with no ambiguity in intent.

---

_Fixed: 2026-07-30T14:04:04Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
