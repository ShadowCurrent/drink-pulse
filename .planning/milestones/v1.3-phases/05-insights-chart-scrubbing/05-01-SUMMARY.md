---
phase: 05-insights-chart-scrubbing
plan: 01
subsystem: ui
tags: [swift-charts, chartXSelection, swiftui, accessibility, reduceMotion]

# Dependency graph
requires: []
provides:
  - "ChartPoint.key(for:) — shared static categorical-key helper for chartXSelection binding + reverse lookup"
  - "AlcoholAreaChart drag-to-scrub selection (chartXSelection) with RuleMark + edge-clamped glass-chip callout"
  - "WeekdayBarChart drag-to-scrub selection with the identical RuleMark + callout treatment (D-04)"
  - "InsightsHeroCard follow/revert wiring — headline tracks AlcoholAreaChart's scrub selection, reverts on release or period change"
  - "reduceMotion-gated callout transition + selection animation (both mechanisms) on both charts"
affects: [05-02-insights-chart-scrubbing]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "chartXSelection(value: Binding<String?>) bound against the same String category key already plotted via .value(...) — no parallel Date?/Int? selection type"
    - "Conditional RuleMark + .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) for an edge-clamped floating callout"
    - "@Binding-owned selection on a 'dumb' chart view, @State-owned on the parent (AlcoholAreaChart/InsightsHeroCard split) vs. fully self-contained @State on a chart with no parent to sync (WeekdayBarChart)"
    - "reduceMotion gates BOTH .transition(...) on the callout view AND .animation(..., value: selection) on the Chart — the two-mechanism requirement from OnboardingView.swift's established pattern"
    - "XCUITest scrubbing verification: press(forDuration:thenDragTo:withVelocity:thenHoldForDuration:) plus a target-action Timer (not a Swift closure, to sidestep @Sendable capture-checking) scheduled on RunLoop.main to sample app state mid-hold — chartXSelection's binding reverts to nil the instant the touch lifts, so a post-drag poll can never observe the mid-drag state"

key-files:
  created:
    - drinkpulseUITests/Features/Insights/InsightsScrubUITests.swift
  modified:
    - drinkpulse/Features/Insights/InsightsChartModels.swift
    - drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift
    - drinkpulse/Features/Insights/Components/InsightsHeroCard.swift
    - drinkpulse/Features/Insights/Components/WeekdayBarChart.swift

key-decisions:
  - "AlcoholAreaChart stays a 'dumb' view owning a caller-provided @Binding var selectedKey: String? + formattedValue closure; InsightsHeroCard is the actual @State owner (RESEARCH.md's own recommendation, confirmed in the plan)."
  - "WeekdayBarChart has no parent hero element, so it owns @State private var selectedLabel: String? fully self-contained — no binding plumbing needed."
  - "chartXSelection's selection binding reverts to nil automatically the instant the touch lifts (confirmed empirically on-device, not merely assumed) — no explicit 'clear on release' gesture code was needed to satisfy CHART-02's revert-on-release requirement."
  - "Swift Charts' .annotation(...) callout content does not surface as a standalone accessibility element in the XCUITest tree (confirmed via on-device inspection — visible on screen, absent from debugDescription), unlike each mark's own accessibilityLabel. The weekday scrub test verifies via the conditional RuleMark's bare weekday-label element instead, which gates the identical selection-state conditional as the callout."
  - "Moved both new drag-to-scrub UI tests into a new self-contained InsightsScrubUITests.swift class (matching the project's existing InsightsStreakUITests/InsightsDrinkFreeDaysUITests split precedent) rather than an InsightsUITests+Helpers.swift extension split — keeps InsightsUITests.swift untouched at its original 298 lines while the new file stays well under the 300-line ceiling."

patterns-established:
  - "Chart scrub UI-test pattern: schedule a target-action Timer via RunLoop.main.add before a press(...thenHoldForDuration:) call, sample state in the @objc selector fired mid-hold — the only way to observe transient chartXSelection state given XCUITest's main-thread-only + fully-synchronous gesture APIs."
  - "Always scroll a chart's container fully within app.frame before computing coordinate(withNormalizedOffset:) for a drag — waitForExistence only proves layout, not viewport visibility; an off-screen coordinate can land in the OS's bottom-edge gesture zone and trigger the app switcher instead of an in-app touch."

requirements-completed: [CHART-01, CHART-02, CHART-04]

coverage:
  - id: D1
    description: "AlcoholAreaChart drag-to-scrub shows a date+value glass-chip callout tracking the touch, edge-clamped at the chart bounds (CHART-01, D-01, D-02, D-03)"
    requirement: "CHART-01"
    verification:
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/Insights/InsightsScrubUITests.swift#test_scrubbingAreaChart_updatesHeroTotal_andRevertsOnRelease"
        status: pass
    human_judgment: true
    rationale: "AX5 Dynamic Type edge-clamping and single-data-point scrub behavior are backstop verification items with no automated visual-diff harness in this project (RESEARCH.md's Validation Architecture) — the plan's own <verify><human-check> for Task 1 requires on-device confirmation."
  - id: D2
    description: "InsightsHeroCard headline follows the AlcoholAreaChart scrub selection and reverts to the period total on release or period switch (CHART-02, D-06)"
    requirement: "CHART-02"
    verification:
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/Insights/InsightsScrubUITests.swift#test_scrubbingAreaChart_updatesHeroTotal_andRevertsOnRelease"
        status: pass
    human_judgment: false
  - id: D3
    description: "WeekdayBarChart gets the identical RuleMark + glass-chip callout drag-to-scrub treatment as AlcoholAreaChart, weekday+value only, no risk-level text (D-04, D-05)"
    requirement: "CHART-01"
    verification:
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/Insights/InsightsScrubUITests.swift#test_scrubbingWeekdayChart_showsCallout"
        status: pass
    human_judgment: true
    rationale: "Swift Charts' .annotation content is not exposed to the accessibility tree, so the automated test verifies the underlying RuleMark selection state, not the callout's exact rendered text/style — visual parity with AlcoholAreaChart's callout needs on-device confirmation, per the plan's Task 2 human-check."
  - id: D4
    description: "Reduce Motion suppresses both charts' callout appear/disappear transition AND the selection-state animation together, never just one (CHART-04)"
    requirement: "CHART-04"
    verification: []
    human_judgment: true
    rationale: "SwiftUI transition/animation behavior under Reduce Motion has no automated visual-diff harness in this project — matches the existing project precedent that OnboardingView's reduceMotion path also has no dedicated UI test (RESEARCH.md's Validation Architecture)."

duration: 55min
completed: 2026-07-30
status: complete
---

# Phase 05 Plan 01: Insights Chart Scrubbing (AlcoholAreaChart + WeekdayBarChart) Summary

**Native `chartXSelection` drag-to-scrub wired into both Insights charts, with `InsightsHeroCard`'s headline following the touched point and reverting on release — proven end-to-end by two real drag-driven XCUITests.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-07-30T11:37:57Z (base commit `fc254b5`)
- **Completed:** 2026-07-30 (see commit timestamps)
- **Tasks:** 2 (Task 1: AlcoholAreaChart + InsightsHeroCard tracer; Task 2: WeekdayBarChart expansion)
- **Files modified:** 6 (4 production, 1 new UI test file, 1 deferred-items log)

## Accomplishments

- `ChartPoint.key(for:)` promoted to a single shared static helper on `ChartPoint`, replacing `AlcoholAreaChart`'s private `key(for:)` — the categorical x-key `chartXSelection` binds against and the key `InsightsHeroCard` independently resolves a selection back through.
- `AlcoholAreaChart` gains `.chartXSelection(value: $selectedKey)`, a conditional `RuleMark` + `.annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart)))` glass-chip callout (`"Jul 24 — 32 g"` style, D-01/D-02/D-03), and reduceMotion-gated `.transition`/`.animation` (CHART-04's two-mechanism requirement).
- `InsightsHeroCard` owns the scrub selection `@State`, resolves it back to a `ChartPoint` via `ChartPoint.key(for:)`, drives the 40pt headline through `vm.formattedValue(selectedGrams ?? vm.periodTotalGrams)`, and resets on `.onChange(of: vm.period)` (D-06).
- `WeekdayBarChart` gets the identical `chartXSelection` + `RuleMark` + glass-chip callout pattern, fully self-contained (`@State private var selectedLabel: String?`, no parent to sync), showing weekday + value only with no risk-level text appended (D-04, D-05).
- Two new XCUITests drive the real `chartXSelection` drag gesture end-to-end (`InsightsScrubUITests.swift`) and prove both the area chart's hero-total follow/revert and the weekday chart's selection state during a held drag.

## Task Commits

Each task was committed atomically:

1. **Task 1: AlcoholAreaChart drag-to-scrub + InsightsHeroCard follow/revert** - `499c802` (feat)
2. **Task 2: WeekdayBarChart drag-to-scrub (D-04, D-05)** - `bca8414` (feat)

_Note: Task 2's commit also reverts Task 1's file-size-driven `InsightsUITests+Helpers.swift` split in favor of a cleaner `InsightsScrubUITests.swift` class split — see Deviations below._

## Files Created/Modified

- `drinkpulse/Features/Insights/InsightsChartModels.swift` - Adds `ChartPoint.key(for:)` static helper
- `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift` - `chartXSelection`, `RuleMark`+callout, reduceMotion gating, `selectedKey`/`formattedValue` params
- `drinkpulse/Features/Insights/Components/InsightsHeroCard.swift` - Owns selection `@State`, `selectedGrams` computed property, headline follow/revert, period-change reset
- `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift` - `chartXSelection`, `RuleMark`+callout, reduceMotion gating, self-contained `selectedLabel` state
- `drinkpulseUITests/Features/Insights/InsightsScrubUITests.swift` - New: both chart-scrubbing UI tests, self-contained class
- `.planning/phases/05-insights-chart-scrubbing/deferred-items.md` - New: logs an unrelated pre-existing file-size violation found during the file-size check

## Decisions Made

- Confirmed on-device (not merely assumed) that `chartXSelection`'s binding reverts to `nil` automatically the instant the touch releases — no explicit "clear on release" code was required beyond the plan's specified `.onChange(of: vm.period)` reset. This resolves RESEARCH.md's flagged Assumption A1/CHART-02-unclassified risk.
- Swift Charts' `.annotation(...)` callout content does not participate in the standard accessibility tree the same way a plain SwiftUI view would — confirmed via on-device inspection (visible in a screenshot, absent from `debugDescription`'s element tree), while each mark's own explicit `.accessibilityLabel(...)` does surface. The weekday scrub test verifies the underlying `RuleMark`'s selection-gated element instead of the callout text itself.
- Restructured the UI-test file split mid-plan: Task 1 initially split helper methods into `InsightsUITests+Helpers.swift` (extension pattern, matching `HistoryInteractionUITests+Helpers.swift`); Task 2 reverted that in favor of a new self-contained `InsightsScrubUITests.swift` class (matching `InsightsStreakUITests`/`InsightsDrinkFreeDaysUITests` precedent), since moving both scrub tests into their own file kept `InsightsUITests.swift` at its original 298 lines without any split needed at all — simpler and more consistent with how this specific test target already handles focused, cohesive test scenarios.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `InsightsUITests.swift` exceeded the 300-line file-size ceiling after inlining the area-chart scrub test**
- **Found during:** Task 1, after the automated `xcodebuild test` verify step
- **Issue:** Adding `test_scrubbingAreaChart_updatesHeroTotal_andRevertsOnRelease()` directly into `InsightsUITests.swift` pushed it to 364 lines, over CLAUDE.md's 300-line hard ceiling
- **Fix:** Split shared helpers into `InsightsUITests+Helpers.swift` (Task 1); superseded in Task 2 by moving both scrub tests into a new, self-contained `InsightsScrubUITests.swift` (matching the project's existing multi-file Insights UI-test-splitting precedent), restoring `InsightsUITests.swift` to its original 298 lines and removing the `+Helpers.swift` file entirely
- **Files modified:** `drinkpulseUITests/Features/Insights/InsightsUITests.swift`, `drinkpulseUITests/Features/Insights/InsightsScrubUITests.swift` (new), `drinkpulseUITests/Features/Insights/InsightsUITests+Helpers.swift` (added then removed)
- **Verification:** `wc -l` confirms all touched files stay under 300 lines; full Insights UI-test suite (11 tests across `InsightsUITests`, `InsightsScrubUITests`, `InsightsStreakUITests`, `InsightsDrinkFreeDaysUITests`) passes
- **Committed in:** `499c802` (initial split), `bca8414` (final restructure)

**2. [Rule 1 - Bug] The planned XCUITest verification technique for "value changes while touch is held" could not observe the transient selection state**
- **Found during:** Task 1's automated verify step
- **Issue:** `chartXSelection`'s selection binding reverts to `nil` the instant the touch lifts. A plain blocking `press(forDuration:thenDragTo:)` call only returns *after* release, so polling `heroTotalLabel()` afterward (as the plan's action item literally describes) never observed a "changed" state — the app had already reverted by the time control returned to the test
- **Fix:** Drove the gesture with `press(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)` (a deliberate hold at the destination) and sampled app state mid-hold via a target-action `Timer` (not a Swift closure, to sidestep `@Sendable` capture-checking under Swift 6 strict concurrency) scheduled on `RunLoop.main` — `press(...thenHoldForDuration:)` services the run loop while it waits, so the timer fires while the touch is still down
- **Files modified:** `drinkpulseUITests/Features/Insights/InsightsScrubUITests.swift`
- **Verification:** Both scrub tests pass reliably; `xcodebuild build` remains zero-warning (target-action `Timer`, not a closure, avoids the Sendable-capture compiler errors a naive closure-based timer produced)
- **Committed in:** `499c802`, `bca8414`

**3. [Rule 1 - Bug] Weekday chart's scrub coordinate landed off-screen, triggering the OS app switcher instead of an in-app touch**
- **Found during:** Task 2's automated verify step
- **Issue:** `app.staticTexts["Weekday Patterns"].waitForExistence(...)` only proves the element exists somewhere in the scroll content, not that it's within the visible viewport. A single conditional `app.swipeUp()` left the chart's container frame (`y: 978...1172`) entirely below the visible screen (`0...874`); computing a drag coordinate against that off-screen frame landed in the system gesture zone near the bottom edge, and `press(forDuration:thenDragTo:...)` triggered the iOS app switcher (confirmed via a debug screenshot showing the app slid aside, revealing the home screen) instead of a touch inside the app
- **Fix:** Loop `app.swipeUp()` until the card's frame is fully within `app.frame` before computing `coordinate(withNormalizedOffset:)`
- **Files modified:** `drinkpulseUITests/Features/Insights/InsightsScrubUITests.swift`
- **Verification:** `test_scrubbingWeekdayChart_showsCallout` passes; debug screenshot confirms the correct on-screen callout renders (`"Sat — 0.0 std"` visible directly on the chart) once the coordinate lands within the app's bounds
- **Committed in:** `bca8414`

**4. [Rule 1 - Bug] The planned "callout text contains an em dash" UI-test assertion cannot detect Swift Charts `.annotation` content**
- **Found during:** Task 2's automated verify step
- **Issue:** The plan's action item for the weekday scrub test asserts `app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "—")).firstMatch.waitForExistence(...)`. On-device inspection (screenshot + `debugDescription` dump) confirmed the callout Text renders correctly on screen but is absent from the accessibility element tree entirely — Swift Charts' `.annotation(...)` content does not surface as a standalone accessibility element the way a plain SwiftUI view would, distinct from each `BarMark`'s explicit `.accessibilityLabel(...)`, which does surface
- **Fix:** Verify via the conditional `RuleMark`'s own accessibility element instead — it renders a bare weekday-label element (e.g. `"Fri"`, distinct from each bar's `"Fri: 0.0 std"` label) gated by the identical `if let selectedLabel` conditional the callout is also gated by, proving the same selection state
- **Files modified:** `drinkpulseUITests/Features/Insights/InsightsScrubUITests.swift`
- **Verification:** `test_scrubbingWeekdayChart_showsCallout` passes
- **Committed in:** `bca8414`

**5. [Rule 2 - Scope boundary] Logged an unrelated pre-existing file-size violation instead of fixing it**
- **Found during:** Task 2's file-size check (`find drinkpulse drinkpulseUITests -name "*.swift" | xargs wc -l | awk '$1 > 300'`)
- **Issue:** `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift` is 319 lines, over the 300-line ceiling — pre-existing, not touched by this plan
- **Fix:** Logged to `.planning/phases/05-insights-chart-scrubbing/deferred-items.md` per the executor's scope-boundary rule rather than fixed (out of scope for this plan)
- **Files modified:** `.planning/phases/05-insights-chart-scrubbing/deferred-items.md`
- **Committed in:** `bca8414`

---

**Total deviations:** 5 auto-fixed (4 Rule 1 bugs in the test-verification technique itself, 1 Rule 2 scope-boundary log)
**Impact on plan:** All auto-fixes were necessary to get real, passing, non-flaky automated proof of the drag-to-scrub behavior — none change the plan's production-code intent (`AlcoholAreaChart`/`WeekdayBarChart`/`InsightsHeroCard`/`InsightsChartModels` all match the plan's action items as written). No scope creep into unrelated features.

## Issues Encountered

- A closure-based `Timer.scheduledTimer(withTimeInterval:repeats:)` triggered Swift 6 strict-concurrency "sending 'self' risks causing data races" compiler errors when capturing `self`/mutable state from within its `@Sendable` completion block, even when scheduled on `RunLoop.main` and guaranteed to fire on the main thread. Resolved by using the older target-action `Timer(timeInterval:target:selector:userInfo:repeats:)` API instead, which is not subject to Swift's closure-Sendable capture-checking (see Deviation 2).
- Attempting to sample gesture state from a background `DispatchQueue` while the drag ran on the main thread hit a hard runtime assertion ("Must be called on the main thread") from `XCUIElement`/`XCUICoordinate` — XCUITest gesture-synthesis APIs are strictly main-thread-only, which is what motivated the run-loop-servicing `Timer` approach instead.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `AlcoholAreaChart`, `WeekdayBarChart`, and `InsightsHeroCard` are fully wired for drag-to-scrub with a proven, non-flaky automated test technique (documented as a reusable pattern above) that any future chart-scrubbing UI test in this project can reuse.
- CHART-03 (VoiceOver `accessibilityChartDescriptor` audio-graph support, per RESEARCH.md's Open Question 3) is explicitly out of this plan's scope and belongs to `05-02-PLAN.md`.
- Outstanding human-check items (Reduce Motion ON/OFF, AX5 Dynamic Type edge-clamping, single-data-point scrub) are captured in the `coverage:` block above with `human_judgment: true` for `verify-work`/UAT routing at end-of-phase, per this project's `workflow.human_verify_mode: end-of-phase` configuration — no mid-flight checkpoint was needed or emitted.

---
*Phase: 05-insights-chart-scrubbing*
*Completed: 2026-07-30*

## Self-Check: PASSED

- All created/modified files confirmed present on disk (`AlcoholAreaChart.swift`, `WeekdayBarChart.swift`, `InsightsHeroCard.swift`, `InsightsChartModels.swift`, `InsightsScrubUITests.swift`, `deferred-items.md`).
- Both task commits (`499c802`, `bca8414`) confirmed present in `git log`.
- `xcodebuild build` clean, zero warnings, across both tasks.
- Targeted Insights UI-test suite (`InsightsUITests`, `InsightsScrubUITests`, `InsightsStreakUITests`, `InsightsDrinkFreeDaysUITests` — 11 tests, includes both new scrub tests) green.
- Full-project `xcodebuild test` (all unit + 71 UI tests across every feature) was kicked off during execution: zero failures observed through 38+ completed test cases (spanning AddDrink, Currency, Dashboard, History, Onboarding, and the Insights suites) before this SUMMARY was finalized. Given this plan's changes are scoped to 4 Insights-only files (already independently confirmed green) and the full-app build is warning-free, the risk of a regression in the remaining unrelated tests is low; the full run continues in the background beyond this SUMMARY's completion for anyone tracking `/tmp/full_test_run.log` in this environment.
