# C014 - ConsumptionOverviewCard progress bar animates with Reduce Motion on

**Status:** owner decision recorded 2026-11-16; fix in plan 11-14
**Source:** owner checklist item CHK-05 (`11-A11Y-CHECKLIST.md`), plan 11-07, run on the iOS 27.2 simulator (not a device).
**Result:** fail (confirmed behavior; the item stays open).

## Current behavior

Code location: `drinkpulse/Features/Dashboard/Components/ConsumptionOverviewCard.swift` line 110 applies `.animation(hasSettledOnce ? .easeOut(duration: 0.5) : nil, value: pctClamped)` to the percentage bar. The condition checks only whether the bar has already settled once. It does not read the Reduce Motion environment value.

What the owner saw: the progress bar on Home animates every time the consumption value changes, with Reduce Motion on and with Reduce Motion off. It never changes in a jump. With Reduce Motion on, the expected behavior in the checklist is no animation.

Context: the bar is one of the three animation sites that D11-17 put on the checklist because they are not gated by Reduce Motion. Decision brief C005 (Phase 08, approved with bounded scope) allows a point fix only for a concretely measured violation. This owner observation is that measurement.

## Source-backed decision table

**Availability:** the APIs below are available at the iOS 27.0 deployment target. The documentation extracts returned by Xcode MCP DocumentationSearch carry no older-availability line, so no older-version claim is made here.

| Topic | Evidence |
| --- | --- |
| Official source | SwiftUI `EnvironmentValues.accessibilityReduceMotion` ("Whether the system preference for Reduce Motion is enabled", `/documentation/SwiftUI/EnvironmentValues/accessibilityReduceMotion`) and `View.animation(_:value:)` ("If `animation` is `nil`, the view doesn't animate", `/documentation/SwiftUI/View/animation(_:value:)`), both read through Xcode MCP DocumentationSearch on 2026-11-16. |
| Option retain | Keep the animation as is. Cost: the bar moves with Reduce Motion on, which contradicts the accessibility intent recorded in C005. |
| Option change | Gate the animation on the Reduce Motion value in this view, the same pattern the chart callouts already use (`reduceMotion ? nil : ...`). Cost: one view, one regression test that needs a Reduce Motion route (none exists today). |
| Option defer | Record and carry the defect to a later phase. Cost: the defect stays shipped. |
| Recommendation | None in Phase 11 by plan rule; the owner chooses retain, change or defer. |
| Data, accessibility, lifecycle risk | No data or schema change. Accessibility risk is the open defect itself. |

## Recommendation and proposed scope

No fix in Phase 11. If the owner chooses change, a separate scope would cover only this animation site, with a focused regression proof. This brief is grouped with C015 and the D11-17 site CHK-04 (open, see the ledger) so one change covers the same pattern.

## Owner decision record

decision: change
decision date: 2026-11-16
exact scope: gate the percentage-bar animation in ConsumptionOverviewCard.swift on accessibilityReduceMotion with the existing reduceMotion ? nil : animation pattern from WeekdayBarChart and AlcoholAreaChart, and in the same change gate DPArcProgress.swift (the CHK-04 site); needs a gated launch-argument route to force Reduce Motion in UI tests (never in production paths) and at least one UI test per site; the owner then re-runs CHK-04, CHK-05 and CHK-06 with Reduce Motion on and off and re-checks T12 (Insights callout gate, CHK-03)
owner reason: chosen in /gsd-plan-phase 11 --gaps session

## Outcome (plan 11-14)

Outcome (plan 11-14): fix commits e5b9040 (overview bars through the DPMotion seam, gated launch argument, probe, tests), 5cc5f23 (probe state word kept out of the string catalog) and fc0a7f7 (Home arc gated through the same seam). Covering tests: DPMotionTests (7 unit tests, DPMotion.animation is nil when reduced) and ReduceMotionDashboardUITests (overview bars report reduced with the override and animated without it; the same pair for the Home arc). Limit: a UI test cannot observe an animation frame, so these tests prove the forced route and the shared decision, not the motion. Owner re-run on the simulator 2026-11-16: CHK-05 pass (bars jump with Reduce Motion on, animate with it off); CHK-04 pass (no arc animation with Reduce Motion on). Open observation OBS-D: with Reduce Motion off the arc shows no visible animation (cause not established, not fixed in plan 11-14).
