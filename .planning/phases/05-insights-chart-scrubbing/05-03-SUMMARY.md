---
phase: 05-insights-chart-scrubbing
plan: 03
subsystem: ui
tags: [swift-charts, chartXSelection, swiftui, accessibility, reduceMotion, gap-closure]

# Dependency graph
requires:
  - "05-01-PLAN.md's chartXSelection + RuleMark + .annotation glass-chip callout on AlcoholAreaChart/WeekdayBarChart"
provides:
  - "AlcoholAreaChart/WeekdayBarChart data-derived .chartYScale headroom (yDomainUpperBound = peak * 1.6) so a .top-positioned scrub annotation clears overflowResolution's clamp"
  - "Scrub selection .animation(value:) rescoped from the whole Chart(...) view to just calloutView's own modifier chain, fixing annotation/RuleMark desync during rapid chartXSelection updates"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "yDomainUpperBound = max(data.map(\\.grams/displayValue).max() ?? 0 * 1.6, 1) — reserves ~38% vertical headroom above the live data max, replacing .automatic(includesZero: true) with an explicit 0...upperBound domain, so overflowResolution: y: .fit(to: .chart) never has to squeeze a .top annotation into the mark's own peak fill"
    - ".animation(reduceMotion ? nil : .spring(...), value: selection) belongs on the annotation's own content view (calloutView), not on the whole Chart(...) — a chart-wide .animation(value:) desyncs the SwiftUI-rendered annotation from the natively-rendered RuleMark during rapid selection updates"

key-files:
  created: []
  modified:
    - drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift
    - drinkpulse/Features/Insights/Components/WeekdayBarChart.swift

key-decisions:
  - "Used the same 1.6x headroom multiplier (peak * 1.6, floored at 1) on both charts per D-04's 'identical treatment' requirement and the plan's own acceptance criteria — no per-chart tuning."
  - "WeekdayBarChart's visible Y-axis (unlike AlcoholAreaChart's hidden axis) now extends further above the tallest bar as a direct, expected side effect of the wider domain — flagged explicitly in the plan's Task 2 action item as something to confirm reads as intentional in the human-check, not a defect to work around."
  - "Left both callout views' content (Text template, font, padding, .dpGlassCard(.chip)) completely untouched — this plan only rewires where the y-domain and animation are applied, matching the plan's explicit scope boundary (DPGlass.swift's low-contrast-against-gradient concern was flagged as a secondary, unconfirmed contributor in the debug session and is out of this plan's files_modified)."

requirements-completed: [CHART-01, CHART-04]

coverage:
  - id: D1
    description: "Dragging near AlcoholAreaChart's peak value shows the callout floating fully visible above the RuleMark with clear vertical clearance from the AreaMark's fill, never embedded/clipped (G-05-2, CHART-01)"
    requirement: "CHART-01"
    verification:
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/Insights/InsightsUITests (all 7 tests, regression guard only)"
        status: pass
    human_judgment: true
    rationale: "No automated visual-diff harness exists for Swift Charts annotation positioning in this project (05-RESEARCH.md's Validation Architecture). The plan's Task 1 <human-check> (hold at peak, fast drag, release, Reduce Motion ON/OFF) is the actual verification for G-05-2 and has not yet been performed on-device as part of this execution — it is the one remaining step before this gap can be marked resolved."
  - id: D2
    description: "During a fast continuous drag across AlcoholAreaChart, the callout tracks the live touch with no stale/stray lingering and disappears promptly on release (G-05-2)"
    requirement: "CHART-01"
    verification:
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/Insights/InsightsUITests (regression guard only — annotation content is not in the accessibility tree, per the debug session's own finding)"
        status: pass
    human_judgment: true
    rationale: "Same rationale as D1 — the annotation/RuleMark desync fix (rescoped .animation) cannot be asserted via XCUITest; on-device confirmation is outstanding."
  - id: D3
    description: "Dragging near WeekdayBarChart's tallest bar on week/month/year/all-time shows the identical fully-visible, non-flickering callout treatment as AlcoholAreaChart, including at the first/last bars (G-05-3, CHART-01)"
    requirement: "CHART-01"
    verification:
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/Insights/InsightsUITests (regression guard only)"
        status: pass
    human_judgment: true
    rationale: "Same no-visual-diff-harness rationale as D1/D2. The plan's Task 2 <human-check> across all four period scopes, including confirming the now-slightly-taller Y-axis reads as intentional, is outstanding."
  - id: D4
    description: "Reduce Motion continues to gate both the callout transition AND the rescoped animation together, zero motion when ON — re-verifying 05-UAT.md's skipped Reduce Motion check on this same code path (CHART-04, no regression)"
    requirement: "CHART-04"
    verification: []
    human_judgment: true
    rationale: "SwiftUI transition/animation behavior under Reduce Motion has no automated verification path in this project (matches 05-01-SUMMARY.md's D4 precedent). The exact same `reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)` ternary was preserved verbatim on both charts' rescoped `.animation` call (only its attachment point moved) and both charts' `.transition` calls were left untouched — code-level confirmation only; on-device Reduce Motion ON/OFF re-check is outstanding per both tasks' human-check blocks."

duration: ~35min (incl. full regression suite run)
completed: 2026-07-30
status: complete
---

# Phase 05 Plan 03: Insights Chart Scrubbing Gap Closure (Callout Flicker/Clip) Summary

**Closed UAT gaps G-05-2 and G-05-3 by giving both Insights charts' scrub callout real vertical headroom (`.chartYScale(domain: 0...yDomainUpperBound)`) and rescoping their selection `.animation` from the whole `Chart` view onto just the callout's own modifier chain — the two root-cause mechanisms confirmed in `.planning/debug/insights-chart-scrub-callout-flicker-clip.md`.**

## Performance

- **Duration:** ~35 min, including a full-project regression suite run (659 tests)
- **Base commit:** `3af1e2f` (docs(05): gap closure plan for scrub callout flicker/clip)
- **Completed:** 2026-07-30
- **Tasks:** 2 (Task 1: AlcoholAreaChart; Task 2: WeekdayBarChart — identical fix, applied per-chart)
- **Files modified:** 2 (both production Swift files named in the plan; no test files touched — this gap closure fixes rendering behavior not exercised by the existing accessibility-tree-based UI tests)

## Accomplishments

- `AlcoholAreaChart` gains a private `yDomainUpperBound` computed property (`max(data.map(\.grams).max() ?? 0 * 1.6, 1)`) and switches `.chartYScale(domain:)` from `.automatic(includesZero: true)` to `0...yDomainUpperBound`, reserving ~38% headroom above the plotted peak so `overflowResolution: y: .fit(to: .chart)` no longer squeezes the `.top` annotation into the `AreaMark`'s own fill.
- `AlcoholAreaChart`'s chart-wide `.animation(reduceMotion ? nil : .spring(...), value: selectedKey)` moved off `Chart(...)` onto `calloutView(date:)`'s own modifier chain (same ternary, same `value:`), fixing the annotation/RuleMark desync confirmed via the debug session's fast-drag and post-release diagnostics.
- `WeekdayBarChart` gets the byte-for-byte identical fix (`yDomainUpperBound` from `bars.map(displayValue).max()`, same `.chartYScale`/`.animation` rescoping), per D-04's "identical treatment across both charts" requirement.
- Both charts' `.frame(height:)` values (100pt / 160pt, per 05-UI-SPEC.md) are unchanged — headroom comes exclusively from the y-domain, not a taller frame.
- Both charts' `reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)` ternary is preserved verbatim on the relocated `.animation` call, and each callout's existing `.transition(reduceMotion ? .identity : .opacity.combined(with: .scale(...)))` is untouched — CHART-04's two-gate Reduce Motion requirement stays intact.
- Full-project regression suite (659 tests: unit + all 71 UI tests, including `InsightsUITests`' 7 tests) passes with zero failures; `xcodebuild build` is clean with zero warnings on both files.

## Task Commits

Each task was committed atomically:

1. **Task 1: AlcoholAreaChart callout clearance + animation rescoping (G-05-2)** - `ea58d02` (fix)
2. **Task 2: WeekdayBarChart identical fix (G-05-3)** - `f3db949` (fix)

## Files Created/Modified

- `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift` - Adds `yDomainUpperBound`; `.chartYScale(domain: 0...yDomainUpperBound)`; `.animation(...)` moved from `Chart(...)` to `calloutView(date:)`. 161 lines (was 154).
- `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift` - Adds `yDomainUpperBound`; `.chartYScale(domain: 0...yDomainUpperBound)`; `.animation(...)` moved from `Chart(...)` to `calloutView(bar:)`. 97 lines (was 89).

## Decisions Made

- Both `yDomainUpperBound` implementations use the identical `max(peak * 1.6, 1)` formula — the `1` floor guards against a degenerate zero/empty-collection result producing an invalid `Comparable` range (matches the plan's own threat register T-05-07 disposition).
- No change to either callout's content, styling, or `.dpGlassCard(.chip)` usage — the debug session's secondary, unconfirmed hypothesis about `DPGlass.swift`'s low contrast against `AreaMark`'s gradient was explicitly out of this plan's scope (shared by `DrinkTypeTile.swift` outside Insights, not in `files_modified`). If the on-device human-check below still finds the chip hard to read after this fix, that's a new, narrower gap to raise separately.

## Deviations from Plan

None — plan executed exactly as written. Both tasks matched their action items, acceptance criteria, and file-size ceilings with no auto-fixes needed.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Outstanding On-Device Verification (required before G-05-2/G-05-3 are resolved)

This project has no automated visual-diff harness for Swift Charts annotations (05-RESEARCH.md's Validation Architecture), so the `<human-check>` blocks in both tasks are the actual verification for these gaps — not yet performed as part of this execution:

1. **AlcoholAreaChart (Task 1):** hold near the chart's peak (callout should float fully above the fill, no overlap); fast continuous drag (no stray/stale callout); release (prompt disappearance, not outliving the RuleMark); repeat with Reduce Motion ON then OFF.
2. **WeekdayBarChart (Task 2):** same checks across week/month/year/all-time scopes, including first ("Mon") and last ("Sun") bars; also confirm the now-slightly-taller Y-axis above the tallest bar reads as intentional, not broken.

Per this project's `workflow.human_verify_mode: end-of-phase` configuration, these are captured in the `coverage:` block above with `human_judgment: true` for `verify-work`/UAT routing rather than a mid-flight checkpoint, matching 05-01-SUMMARY.md's precedent.

## Next Phase Readiness

- This was the final plan for Phase 05 (insights-chart-scrubbing) — a gap-closure plan against 05-01/05-02's UAT round. Once the on-device human-checks above are confirmed, G-05-2 and G-05-3 can be closed and the phase considered fully resolved.
- No new production surface was introduced; both `yDomainUpperBound` properties are pure, in-memory-data-derived display values (threat register T-05-06/T-05-07, both `accept`, low severity) — no new threat flags to carry forward.

---
*Phase: 05-insights-chart-scrubbing*
*Completed: 2026-07-30*

## Self-Check: PASSED

- `AlcoholAreaChart.swift` and `WeekdayBarChart.swift` confirmed present on disk with the expected `yDomainUpperBound` properties and relocated `.animation` calls.
- Both task commits (`ea58d02`, `f3db949`) confirmed present in `git log --oneline`.
- `xcodebuild build` clean, zero warnings, after both tasks.
- Targeted `InsightsUITests` (7 tests) green after each task.
- Full-project `xcodebuild test` (659 tests: all unit tests + all 71 UI tests across every feature) passed with 0 failures, confirmed via the resulting `.xcresult` bundle's summary (`"result" : "Passed"`, `"failedTests" : 0`, `"passedTests" : 659`).
- Both files stay under the 300-line ceiling (161 / 97 lines).
