---
phase: 05-insights-chart-scrubbing
plan: 04
subsystem: ui
tags: [swiftui, swift-charts, insights, accessibility, design-system]

# Dependency graph
requires:
  - phase: 05-insights-chart-scrubbing
    provides: chartXSelection drag-to-scrub on AlcoholAreaChart/WeekdayBarChart (05-01/05-02), flicker/clip fix via yDomainUpperBound + Reduce Motion gating (05-03)
provides:
  - PointMark-anchored scrub annotation on both Insights charts, so the marker's screen height tracks the touched datum's actual value
  - DPGlass.swift dpChartCalloutBackground() — opaque-Color chart-callout background, since Liquid Glass/materials do not composite inside a Swift Charts .annotation
  - Legible date+value (AlcoholAreaChart) and weekday+value (WeekdayBarChart) scrub callouts on an opaque background
affects: [insights-chart-scrubbing, design-system]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Swift Charts scrub annotation must anchor to a PointMark placed at the selected datum's (x, y) — never to an unbounded RuleMark, which spans the full plot height by default and pins .annotation(.top) to a constant screen Y"
    - "Chart .annotation content must use an opaque Color background (dpChartCalloutBackground()), never .glassEffect/.regularMaterial/.dpGlassCard — both render as zero pixels / an opaque black rectangle inside a Swift Charts annotation (Apple DTS: 'Liquid Glass is not a part of Swift Charts')"

key-files:
  created: []
  modified:
    - drinkpulse/DesignSystem/DPGlass.swift
    - drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift
    - drinkpulse/Features/Insights/Components/WeekdayBarChart.swift

key-decisions:
  - "New DPChartCalloutBackgroundModifier kept fully separate from DPGlassModifier/dpGlassCard(_:) — an explicit, documented exception to the app's Liquid Glass design language, scoped to chart scrub callouts only, so a future pass does not silently reintroduce the glass chip"
  - "AlcoholAreaChart keeps a bounded RuleMark (yStart 0 → datum value) as a drop-line, since the area/line has no other height cue at the selected X; WeekdayBarChart drops the RuleMark entirely since the BarMark itself already spans 0 → value and would be redundant"
  - "calloutView(date:grams:) now takes grams directly from the PointMark's own datum instead of re-looking it up via data.first(where:) — removes an unnecessary optional"

requirements-completed: [CHART-01, CHART-04]

coverage:
  - id: D1
    description: "AlcoholAreaChart scrub marker height tracks the touched datum's actual value (near-zero vs. peak visibly differ) — G-05-4"
    requirement: CHART-01
    verification:
      - kind: e2e
        ref: "drinkpulseUITests/InsightsScrubUITests#test_scrubbingAreaChart_showsCallout"
        status: pass
    human_judgment: true
    rationale: "Swift Charts annotation screen-position/height is not visible to the accessibility tree (InsightsScrubUITests' own code comment confirms this), so no automated assertion can see whether the marker's height differs between a low-value and peak point. The UI test only proves the callout element exists and the hero headline updates; the plan's own <human-check> block requires on-device confirmation across Week/Month/Year/AllTime before G-05-4 is considered resolved."
  - id: D2
    description: "AlcoholAreaChart scrub callout renders fully legible text with BOTH date and value on an opaque, non-glass background — G-05-5"
    requirement: CHART-01
    verification:
      - kind: e2e
        ref: "drinkpulseUITests/InsightsScrubUITests#test_scrubbingAreaChart_showsCallout"
        status: pass
    human_judgment: true
    rationale: "Annotation content (including legibility/pixel visibility) is outside the accessibility tree and this project has no visual-diff harness for Swift Charts annotations (confirmed by the debug session and by InsightsScrubUITests' own comment). On-device confirmation across all four periods, most critically Month, is required per the plan's <human-check> block."
  - id: D3
    description: "WeekdayBarChart scrub marker sits at each held bar's own top, tracking bar height across at least two bars of different height — G-05-4"
    requirement: CHART-01
    verification:
      - kind: e2e
        ref: "drinkpulseUITests/InsightsScrubUITests#test_scrubbingWeekdayChart_showsCallout"
        status: pass
    human_judgment: true
    rationale: "Same rationale as D1 — marker screen position is not assertable via the accessibility tree; requires the plan's on-device <human-check>."
  - id: D4
    description: "WeekdayBarChart scrub callout renders fully legible weekday+value text on an opaque, non-glass background — G-05-5"
    requirement: CHART-01
    verification:
      - kind: e2e
        ref: "drinkpulseUITests/InsightsScrubUITests#test_scrubbingWeekdayChart_showsCallout"
        status: pass
    human_judgment: true
    rationale: "Same rationale as D2 — callout legibility is not assertable via the accessibility tree; requires the plan's on-device <human-check>."
  - id: D5
    description: "Reduce Motion still gates both charts' callout transition and animation together (no regression to CHART-04, fixed by 05-03)"
    requirement: CHART-04
    verification:
      - kind: unit
        ref: "Source review: reduceMotion ternary on .transition(...) and .animation(...) carried over verbatim in both calloutView(...) methods"
        status: pass
    human_judgment: false

# Metrics
duration: 25min
completed: 2026-07-31
status: complete
---

# Phase 05 Plan 04: Insights Chart Scrub Marker/Callout Fix Summary

**Moved both Insights charts' scrub annotation from an unbounded RuleMark onto a PointMark at the selected datum, and replaced the invisible Liquid-Glass callout background with a new opaque-Color `dpChartCalloutBackground()` modifier — closing UAT gaps G-05-4 (constant marker height) and G-05-5 (illegible callout).**

## Performance

- **Duration:** 25 min
- **Started:** 2026-07-31T05:08:37Z
- **Completed:** 2026-07-31T05:33:13Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- `AlcoholAreaChart`: selected-datum annotation now anchors to a `PointMark(x:, y: point.grams)` instead of an unbounded `RuleMark`; the `RuleMark` is bounded (`yStart: 0`, `yEnd: point.grams`) as a drop-line, and `calloutView` takes `grams` directly from the datum instead of re-looking it up.
- `WeekdayBarChart`: identical treatment — selected-bar annotation anchors to a `PointMark(x:, y: displayValue(bar))`; the `RuleMark` is removed entirely (the `BarMark` itself already spans 0→value, so a drop-line would be redundant).
- `DPGlass.swift`: added `dpChartCalloutBackground()` — a new, separate `ViewModifier` applying an opaque `Color(.secondarySystemGroupedBackground)` fill, hairline stroke, and soft shadow — with a doc comment recording why Liquid Glass/materials must never be used as a chart-callout background again (Apple DTS: "Liquid Glass is not a part of Swift Charts"; `.regularMaterial` probed and found to render as an opaque black rectangle in the same context). Existing `dpGlassCard(_:)`/`DPGlassModifier`/`DPGlassSize` are unchanged.
- Both callouts now render on `dpChartCalloutBackground()` instead of `.dpGlassCard(.chip)`, with `.fixedSize()` added to match the debug session's on-device-verified probe recipe.
- `yDomainUpperBound` headroom (05-03) and the `reduceMotion` gating on both callouts' `.transition`/`.animation` are preserved verbatim on both charts.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix AlcoholAreaChart's marker height + invisible callout (G-05-4, G-05-5)** - `213cc43` (feat)
2. **Task 2: Apply the identical marker/callout fix to WeekdayBarChart (G-05-4, G-05-5, D-04)** - `2b8a001` (feat)

**Plan metadata:** SUMMARY.md commit (this plan) — see final commit in this worktree.

## Files Created/Modified

- `drinkpulse/DesignSystem/DPGlass.swift` - Added `dpChartCalloutBackground()` View extension + `DPChartCalloutBackgroundModifier`, plus a preview example; existing glass API unchanged.
- `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift` - Bounded `RuleMark`, added `PointMark` carrying `.annotation`, `calloutView(date:grams:)` takes `grams` directly, swapped to `dpChartCalloutBackground()`.
- `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift` - Removed `RuleMark`, added `PointMark` carrying `.annotation` styled with the bar's own risk color, swapped to `dpChartCalloutBackground()`.

## Decisions Made

- Kept the new callout-background modifier structurally separate from `DPGlassModifier`/`dpGlassCard(_:)` per the plan's explicit prohibition — this is a scoped, documented exception to the app's Liquid Glass design language, not a general-purpose alternative.
- `AlcoholAreaChart` keeps a bounded `RuleMark` (drop-line from baseline to the point) since the area/line chart has no other visual cue for "this X, this height" at the selected point; `WeekdayBarChart` drops the `RuleMark` entirely since the `BarMark`'s own fill already is that cue — this matches the plan's explicit "or remove entirely" option and avoids a redundant overlay on top of the bar.
- `PointMark` styling: `AlcoholAreaChart` uses `Color.dpRiskModerate` (matching the line/area's existing color); `WeekdayBarChart` reuses the existing `color(for:)` risk-level helper so the marker matches its own bar's color, keeping both markers visually consistent with their charts' existing color language.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Human-Verification Items (not blocking, not stubs)

Both tasks' `<verify>` blocks include a `<human-check>` requiring on-device confirmation, because this project has no automated visual-diff harness for Swift Charts annotations (confirmed by the debug session and by `InsightsScrubUITests`' own code comment that annotation content does not surface in the accessibility tree). All automated gates pass:

- `xcodebuild build` — zero warnings, both tasks.
- `xcodebuild test -only-testing:drinkpulseUITests/InsightsScrubUITests` — 2/2 passed, both tasks.
- Full suite (`xcodebuild test`) — 659/659 passed, 0 failures, after both tasks.
- File size: `AlcoholAreaChart.swift` 175 lines, `WeekdayBarChart.swift` 112 lines, `DPGlass.swift` 82 lines — all well under the 300-line ceiling.

The plan's on-device human-checks (marker height tracking the datum's value at every held point across Week/Month/Year/AllTime, and callout legibility of both X and Y values, most critically re-checked in Month) still need explicit human sign-off before G-05-4/G-05-5 are considered fully resolved per the plan's own verification section — this is expected per the plan's design (`type="auto"` tasks with an embedded `<human-check>`, not a `checkpoint:*` task type), and is the natural next step for `/gsd-verify-work` or a manual on-device pass.

## Next Phase Readiness

- Both Insights charts' scrub interaction now has a data-driven marker height and a legible, opaque callout background at the source-code level, verified by build + regression UI tests.
- No blockers for merging this wave; the plan's on-device human-checks are the only outstanding verification step, consistent with how this plan was authored (no `checkpoint:*` task types — both tasks are `type="auto"`).

---
*Phase: 05-insights-chart-scrubbing*
*Completed: 2026-07-31*
