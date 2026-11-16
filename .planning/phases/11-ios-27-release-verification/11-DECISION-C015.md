# C015 - HistoryCalendarView detail area animates with Reduce Motion on

**Status:** owner decision recorded 2026-11-16; fix in plan 11-14
**Source:** owner checklist item CHK-06 (`11-A11Y-CHECKLIST.md`), plan 11-07, run on the iOS 27.2 simulator (not a device).
**Result:** fail (confirmed behavior; the item stays open).

## Current behavior

Code location: `drinkpulse/Features/History/Components/HistoryCalendarView.swift` line 61 applies `.animation(.easeInOut(duration: 0.25), value: selectedDay)` to the calendar card. It does not read the Reduce Motion environment value.

What the owner saw: when a day changes, the detail area always animates slightly, with Reduce Motion on and with Reduce Motion off. It never changes in a jump. With Reduce Motion on, the expected behavior in the checklist is no animation.

Context: one of the three D11-17 sites that are not gated by Reduce Motion. Decision brief C005 allows a point fix only for a concretely measured violation. This owner observation is that measurement. Note for the owner: other History code (`HistoryView.swift`) already avoids animation under Reduce Motion, per the C005 current-behavior section.

## Source-backed decision table

**Availability:** the APIs below are available at the iOS 27.0 deployment target. The documentation extracts returned by Xcode MCP DocumentationSearch carry no older-availability line, so no older-version claim is made here.

| Topic | Evidence |
| --- | --- |
| Official source | SwiftUI `EnvironmentValues.accessibilityReduceMotion` (`/documentation/SwiftUI/EnvironmentValues/accessibilityReduceMotion`) and `View.animation(_:value:)`, where a `nil` animation means the view does not animate (`/documentation/SwiftUI/View/animation(_:value:)`), read through Xcode MCP DocumentationSearch on 2026-11-16. |
| Option retain | Keep the animation as is. Cost: motion remains with Reduce Motion on. |
| Option change | Gate the animation on the Reduce Motion value in this view. Cost: one view and a regression proof; the existing History UI tests do not drive Reduce Motion. |
| Option defer | Record and carry the defect to a later phase. |
| Recommendation | None in Phase 11 by plan rule; the owner chooses retain, change or defer. |
| Data, accessibility, lifecycle risk | No data or schema change. Accessibility risk is the open defect itself. |

## Recommendation and proposed scope

No fix in Phase 11. If the owner chooses change, a separate scope would cover only this animation site, with a focused regression proof, ideally bundled with C014 because the pattern is the same.

## Owner decision record

decision: change
decision date: 2026-11-16
exact scope: gate the detail-area animation in HistoryCalendarView.swift on accessibilityReduceMotion (same pattern, same change as C014), one UI test, owner re-check of CHK-06
owner reason: chosen in /gsd-plan-phase 11 --gaps session

## Outcome (plan 11-14)

Outcome (plan 11-14): fix commit fc0a7f7 (History calendar detail animation gated through the DPMotion seam introduced in e5b9040). Covering tests: DPMotionTests (7 unit tests) and ReduceMotionHistoryUITests (calendar card reports reduced with the override and the day detail still appears; reports animated without it). Limit: a UI test cannot observe an animation frame, so these tests prove the forced route and the shared decision, not the motion. Owner re-run on the simulator 2026-11-16: CHK-06 pass (detail area appears without animation with Reduce Motion on, animates with it off).
