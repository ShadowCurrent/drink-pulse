---
phase: 05-insights-chart-scrubbing
plan: 02
subsystem: ui
tags: [swift-charts, accessibility, AXChartDescriptorRepresentable, voiceover, swiftui]

# Dependency graph
requires:
  - phase: 05-insights-chart-scrubbing
    provides: "05-01's chartXSelection drag-to-scrub wiring (formattedValue closure on AlcoholAreaChart, unitDivisor/unitLabel on WeekdayBarChart) — this plan's descriptors reuse those exact formatting paths"
provides:
  - "AlcoholAreaChartAXDescriptor — AXChartDescriptorRepresentable conformance reusing AlcoholAreaChart's existing formattedValue closure"
  - "WeekdayBarChartAXDescriptor — AXChartDescriptorRepresentable conformance reusing WeekdayBarChart's existing unitDivisor/unitLabel/displayValue(_:) formatting path"
  - ".accessibilityChartDescriptor(_:) attached to both charts, independent of the chartXSelection drag gesture"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "AXChartDescriptorRepresentable conformance lives in its own <ChartName>+Accessibility.swift extension file, closure/value-based (never holding a ViewModel reference) so it stays previewable/testable in isolation"
    - "AXChartDescriptorRepresentable and its supporting types (AXChartDescriptor, AXCategoricalDataAxisDescriptor, AXNumericDataAxisDescriptor, AXDataSeriesDescriptor, AXDataPoint) require `import SwiftUI` — the protocol itself is declared in SwiftUICore/SwiftUI, not merely `import Accessibility` (RESEARCH.md's Pattern 3 code example under-specified this; `import Accessibility` alone gives the descriptor value types but not AXChartDescriptorRepresentable)"
    - "AXDataPoint's y-value has no public Swift readback API in this SDK (AXDataPointValue.number is NS_REFINED_FOR_SWIFT with no Swift-overlay wrapper shipped) — tests read it back via Key-Value Coding (`(point.yValue as AnyObject?)?.value(forKey: \"number\")`) against the underlying Objective-C property"
    - "AXNumericDataAxisDescriptor's value-description closure must be NaN/infinite-safe: when constructed with a zero-width range (empty-data edge case), the framework probes the closure with an internally-computed default gridline value that can be NaN, so a closure doing `Int($0)` crashes even though production code never calls the closure directly for the empty case"

key-files:
  created:
    - drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift
    - drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift
    - drinkpulseTests/Features/Insights/AlcoholAreaChartAXDescriptorTests.swift
    - drinkpulseTests/Features/Insights/WeekdayBarChartAXDescriptorTests.swift
  modified:
    - drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift
    - drinkpulse/Features/Insights/Components/WeekdayBarChart.swift

key-decisions:
  - "AXChartDescriptorRepresentable structs stay closure/value-based (formattedValue: (Double) -> String for the area chart; unitDivisor/unitLabel for the bar chart) with no InsightsViewModel dependency — per RESEARCH.md Open Question 3's resolution, keeping both descriptors constructible with plain fixtures in unit tests."
  - "WeekdayBarChartAXDescriptor's value-description closure reuses the identical String(format: \"%.1f\", ...) + unitLabel formatting already used by WeekdayBarChart's existing per-bar accessibilityLabel — not vm.formattedValue — since WeekdayBarChart has no view-model reference (D-09/PATTERNS.md's 'dumb view' constraint)."
  - "AlcoholAreaChartAXDescriptor's per-point x-category uses the full month name (.dateTime.month(.wide).day(), e.g. 'July 24') distinct from the visual callout's abbreviated-month string (.month(.abbreviated)) — matching D-08's example phrasing while keeping the audio-only description slightly more verbose for VoiceOver."

patterns-established:
  - "+Accessibility.swift extension-file split for AXChartDescriptorRepresentable conformances, one per chart, kept under the file-size ceiling (46 and 52 lines respectively)."
  - "AXDataPoint y-value KVC readback helper (rawY(_:)) for unit-testing descriptor construction — reusable pattern for any future AXChartDescriptorRepresentable test in this project."

requirements-completed: [CHART-03]

coverage:
  - id: D1
    description: "AlcoholAreaChart carries a full AXChartDescriptorRepresentable (AlcoholAreaChartAXDescriptor) attached via .accessibilityChartDescriptor(_:), reusing the exact formattedValue closure already wired in by 05-01 so the audio graph and visual callout never diverge (CHART-03, D-08)"
    requirement: "CHART-03"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Features/Insights/AlcoholAreaChartAXDescriptorTests.swift#makeChartDescriptor_dataPointCountMatchesInput, makeChartDescriptor_yValuesMatchRawGrams_neverRounded, makeChartDescriptor_usesInjectedFormattedValueClosure_notInlineFormatting, makeChartDescriptor_emptyData_zeroDataPoints_noCrash"
        status: pass
    human_judgment: true
    rationale: "The plan's own <verify><human-check> for Task 1 requires an on-device/Simulator VoiceOver Audio Graph rotor check — RESEARCH.md's Environment Availability table flags this as 'not probed by research', and the unit tests only prove descriptor construction, not that VoiceOver actually surfaces and narrates it correctly end-to-end."
  - id: D2
    description: "WeekdayBarChart carries a full AXChartDescriptorRepresentable (WeekdayBarChartAXDescriptor) attached via .accessibilityChartDescriptor(_:), additive to (not replacing) its existing per-bar accessibilityLabel, reusing the identical unitDivisor/unitLabel formatting path (CHART-03, D-09)"
    requirement: "CHART-03"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Features/Insights/WeekdayBarChartAXDescriptorTests.swift#makeChartDescriptor_dataPointCountMatchesSevenBars, makeChartDescriptor_yValuesAreDivisorAdjusted_neverRawAverageGrams, makeChartDescriptor_categoryOrderMatchesBarLabelsInOrder, makeChartDescriptor_emptyBars_zeroDataPoints_noCrash"
        status: pass
    human_judgment: true
    rationale: "Same rationale as D1 — the plan's Task 2 <verify><human-check> requires an on-device VoiceOver Audio Graph confirmation that the descriptor is genuinely additive (not a no-op) beyond the pre-existing per-bar labels."

duration: 40min
completed: 2026-07-30
status: complete
---

# Phase 05 Plan 02: Insights Chart Scrubbing — VoiceOver Audio Graph (AlcoholAreaChart + WeekdayBarChart) Summary

**Both Insights charts gain a full `AXChartDescriptorRepresentable` conformance wired via `.accessibilityChartDescriptor(_:)`, giving VoiceOver users a drag-gesture-independent audio-graph path to every plotted point, formatted through the exact same closures already driving each chart's visual callout.**

## Performance

- **Duration:** ~40 min
- **Started:** 2026-07-30 (base commit `1057e78`, wave 2 of phase 05)
- **Completed:** 2026-07-30 (see commit timestamps)
- **Tasks:** 2 (Task 1: AlcoholAreaChart descriptor; Task 2: WeekdayBarChart descriptor)
- **Files modified:** 6 (4 new: 2 production `+Accessibility.swift`, 2 test files; 2 modified chart views)

## Accomplishments

- `AlcoholAreaChartAXDescriptor` (new `AlcoholAreaChart+Accessibility.swift`) implements `AXChartDescriptorRepresentable`, building an `AXCategoricalDataAxisDescriptor` x-axis (full month + day per point), an `AXNumericDataAxisDescriptor` y-axis whose value-description closure calls the injected `formattedValue` — the same closure instance 05-01 already threaded into `AlcoholAreaChart` for its visual callout — and an `AXDataSeriesDescriptor` with one data point per `ChartPoint`. Attached via `.accessibilityChartDescriptor(...)` on `AlcoholAreaChart`'s `Chart(...)` view.
- `WeekdayBarChartAXDescriptor` (new `WeekdayBarChart+Accessibility.swift`) mirrors the same shape for `WeekdayBarChart`, using `bars.map(\.label)` as the categorical x-axis order and `bars[i].averageGrams / unitDivisor` (divisor-adjusted, never raw grams) as each y-value — reusing the identical `String(format: "%.1f", ...) + unitLabel` formatting already used by this chart's existing per-bar `accessibilityLabel`, since `WeekdayBarChart` has no view-model reference to call `vm.formattedValue` through.
- Both descriptors are closure/value-based structs with zero `InsightsViewModel`/`ModelContext` dependency, so both are constructible and testable from plain fixtures.
- Two new unit test files (`AlcoholAreaChartAXDescriptorTests.swift`, `WeekdayBarChartAXDescriptorTests.swift`, 4 tests each, 8 total) prove: point-count parity with the input array, exact (never-rounded) y-values, that the injected formatting closure is actually invoked (not a duplicated inline format), correct categorical ordering, and a crash-free empty-array edge case for both charts.

## Task Commits

Each task was committed atomically:

1. **Task 1: AlcoholAreaChart VoiceOver audio graph descriptor (CHART-03, D-08)** - `d78bb14` (feat)
2. **Task 2: WeekdayBarChart VoiceOver audio graph descriptor (CHART-03, D-09)** - `a504a6b` (feat)

## Files Created/Modified

- `drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift` - New: `AlcoholAreaChartAXDescriptor` (`AXChartDescriptorRepresentable`), 46 lines
- `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift` - Adds `.accessibilityChartDescriptor(...)` reusing the existing `formattedValue` parameter
- `drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift` - New: `WeekdayBarChartAXDescriptor` (`AXChartDescriptorRepresentable`), 52 lines
- `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift` - Adds `.accessibilityChartDescriptor(...)` reusing existing `bars`/`unitDivisor`/`unitLabel`
- `drinkpulseTests/Features/Insights/AlcoholAreaChartAXDescriptorTests.swift` - New: 4 Swift Testing cases
- `drinkpulseTests/Features/Insights/WeekdayBarChartAXDescriptorTests.swift` - New: 4 Swift Testing cases

## Decisions Made

- Confirmed (contrary to RESEARCH.md's Pattern 3 code example, which only showed `import Accessibility`) that `AXChartDescriptorRepresentable` itself is declared in `SwiftUICore`/`SwiftUI`, not `Accessibility` — both new `+Accessibility.swift` files import `SwiftUI` (which re-exports the `Accessibility` descriptor value types transitively for this use case) rather than `import Accessibility` alone.
- Chose Key-Value Coding to read back `AXDataPoint`'s y-value in tests, since `AXDataPointValue.number` is `NS_REFINED_FOR_SWIFT` with no public Swift-overlay accessor shipped in this SDK (confirmed by exhaustively grepping every `.swiftinterface` in the iOS 26.5 simulator SDK — zero hits for a friendly Swift wrapper). This is the only supported way to assert exact y-values from a constructed `AXChartDescriptor` in a unit test.
- Made both charts' test `formattedValue`/value-description closures NaN/infinite-safe (`String(format: "%.0f g", grams)` instead of `"\(Int(grams)) g"`) after discovering the framework probes the y-axis closure with an internally-computed default gridline value on a zero-width range (the empty-data case) — production code (`vm.formattedValue`, and `WeekdayBarChart`'s own `%.1f` formatting) was already NaN-safe by construction, so this was purely a test-authoring fix, not a production behavior change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `import Accessibility` alone did not expose `AXChartDescriptorRepresentable`**
- **Found during:** Task 1, first build attempt (`Cannot find type 'AXChartDescriptorRepresentable' in scope`)
- **Issue:** RESEARCH.md's Pattern 3 code example and this plan's action item specified `import Accessibility` for the new `+Accessibility.swift` files. Cross-checking the actual iOS 26.5 simulator SDK's `.swiftinterface` files showed `AXChartDescriptorRepresentable` is declared in `SwiftUICore` (re-exported by `SwiftUI`), while `AXChartDescriptor`/`AXNumericDataAxisDescriptor`/etc. are declared in `Accessibility` — the protocol itself needs `import SwiftUI`, not just `import Accessibility`.
- **Fix:** Both `AlcoholAreaChart+Accessibility.swift` and `WeekdayBarChart+Accessibility.swift` import `SwiftUI` (dropping the redundant `import Charts` that wasn't needed and wasn't providing the missing type either).
- **Files modified:** `drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift`, `drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift`
- **Verification:** `xcodebuild build` succeeds with zero warnings; both descriptor structs compile and conform correctly.
- **Committed in:** `d78bb14`, `a504a6b`

**2. [Rule 3 - Blocking] `AXDataPoint`'s `.y`/`.yValue.number` has no public Swift accessor for test readback**
- **Found during:** Task 1's automated test authoring — `Value of type 'AXDataPoint' has no member 'y'`
- **Issue:** The plan's Task 1 behavior spec ("each `dataPoints[i].y` equals `data[i].grams` exactly") assumes a directly-readable `.y` property. The real SDK type only exposes `.yValue: AXDataPointValue?`, and `AXDataPointValue.number` is `NS_REFINED_FOR_SWIFT` with no Swift-overlay wrapper anywhere in the SDK (confirmed via exhaustive grep of every `.swiftinterface` file in the iOS 26.5 simulator SDK).
- **Fix:** Added a small KVC-based test helper (`rawY(_:)`) in both test files: `(point.yValue as AnyObject?)?.value(forKey: "number") as? Double` — reads the underlying Objective-C property directly, bypassing Swift's refined-name hiding. Verified working via a standalone `swift` interpreter probe before adopting it in the test suite.
- **Files modified:** `drinkpulseTests/Features/Insights/AlcoholAreaChartAXDescriptorTests.swift`, `drinkpulseTests/Features/Insights/WeekdayBarChartAXDescriptorTests.swift`
- **Verification:** All y-value assertions pass and correctly detect an intentionally-wrong value when tried manually during authoring.
- **Committed in:** `d78bb14`, `a504a6b`

**3. [Rule 1 - Bug] Test's own `Int($0)` value-description closure crashed on the empty-data case**
- **Found during:** Task 1's automated test run — `Fatal error: Double value cannot be converted to Int because it is either infinite or NaN`, inside `makeChartDescriptor_emptyData_zeroDataPoints_noCrash()`
- **Issue:** With `data: []`, `AXNumericDataAxisDescriptor`'s range collapses to `0...0`. The framework internally probes the value-description closure with a computed default-gridline value on construction, and for a zero-width range that computation can be NaN. The test's closure (`{ "\(Int($0)) g" }`) crashed converting NaN to `Int`. This is a test-authoring bug, not a production issue — the real `vm.formattedValue` used in `AlcoholAreaChart` was already NaN-safe (uses `String(format:)`, never a bare `Int(_:)`).
- **Fix:** Replaced the test's throwaway closure with a `safeFormattedValue(_:)` helper using `String(format: "%.0f g", grams)`, matching how production code is actually written.
- **Files modified:** `drinkpulseTests/Features/Insights/AlcoholAreaChartAXDescriptorTests.swift`
- **Verification:** `makeChartDescriptor_emptyData_zeroDataPoints_noCrash()` passes; all 4 tests in the file pass.
- **Committed in:** `d78bb14`

---

**Total deviations:** 3 auto-fixed (2 Rule 3 blocking-issue fixes in framework API usage, 1 Rule 1 bug in test-closure NaN-safety)
**Impact on plan:** All three were necessary to get the plan's specified behavior actually compiling and passing — none change the plan's production-code intent (both descriptors match the plan's action items: closure/value-based shape, reusing existing formatting paths, `.accessibilityChartDescriptor(...)` attachment). No scope creep into unrelated features.

## Issues Encountered

- The iOS 26.5 SDK's `Accessibility.framework` Swift interface ships `AXDataPointValue.number`/`.category` as `NS_REFINED_FOR_SWIFT` with no accompanying Swift-friendly overlay (unlike `AXNumericDataAxisDescriptor.range`, `AXChartDescriptor.xAxis`, etc., which do have friendly overlays in the same `Accessibility.swiftmodule` interface). This appears to be a genuine SDK documentation/API-completeness gap rather than anything specific to this project — confirmed by grepping every `.swiftinterface` in the SDK for `AXDataPointValue` (zero hits outside the base declaration). KVC is the pragmatic workaround for test code; production code never needs to read these values back (they're write-only, consumed internally by VoiceOver).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Both Insights charts now have complete `CHART-03` coverage: `chartXSelection` drag-to-scrub (05-01) and a fully independent `AXChartDescriptorRepresentable` audio-graph path (05-02) — satisfying "scrubbing is not the only path to the values" by construction.
- Outstanding human-check items for this plan (VoiceOver Audio Graph rotor confirmation on both charts, per the plan's Task 1/Task 2 `<verify><human-check>` blocks) are captured in the `coverage:` block above with `human_judgment: true`, routed to end-of-phase UAT per this project's `workflow.human_verify_mode: end-of-phase` configuration — no mid-flight checkpoint was needed or emitted.
- Combined with 05-01, phase 05 (Insights Chart Scrubbing) has now delivered all four requirements (CHART-01 through CHART-04); phase-level verification/UAT is the next step.

---
*Phase: 05-insights-chart-scrubbing*
*Completed: 2026-07-30*

## Self-Check: PASSED

- All created/modified files confirmed present on disk (`AlcoholAreaChart+Accessibility.swift`, `WeekdayBarChart+Accessibility.swift`, `AlcoholAreaChart.swift`, `WeekdayBarChart.swift`, `AlcoholAreaChartAXDescriptorTests.swift`, `WeekdayBarChartAXDescriptorTests.swift`).
- Both task commits (`d78bb14`, `a504a6b`) confirmed present in `git log`.
- `xcodebuild build` clean, zero warnings, after both tasks.
- Targeted test suite (`AlcoholAreaChartAXDescriptorTests` 4/4, `WeekdayBarChartAXDescriptorTests` 4/4, `InsightsViewModelTests`, `InsightsUITests` 7/7, `InsightsScrubUITests` 2/2) green.
- No files over 300 lines (`find drinkpulse -name "*.swift" | xargs wc -l | awk '$1 > 300'` — no output).
- Full-project `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` (no `-only-testing` filter) ran to completion: all 581 unit tests (42 Swift Testing suites) and all 71 UI tests passed, 0 failures, 0 unexpected — full suite green as required by this plan's `<verification>` section.
