---
phase: 11-ios-27-release-verification
plan: 14
subsystem: accessibility
tags: [reduce-motion, swiftui, xcuitest, swift-testing, owner-checkpoint, gap-closure]
requires: [11-13]
provides:
  - DPMotion decision seam (isReduced, animation) used by the Home overview bars, the History calendar detail and the Home arc
  - gated UI-test route -dp_uitest_reduce_motion YES and a one point probe (DPMotionProbe) per site
  - unit tests and one pair of UI tests per site
  - owner re-run of CHK-04, CHK-05, CHK-06 and T12 recorded in the checklist and in the C014 and C015 briefs
affects: [11-15, 11-24]
tech-stack:
  added: []
  patterns: ["one decision seam (DPMotion) fed by accessibilityReduceMotion plus a UI-test-only forced flag", "non-text probe element under -dp_uitest to report a view's decision to XCUITest"]
key-files:
  created:
    - drinkpulse/DesignSystem/DPMotion.swift
    - drinkpulse/DesignSystem/DPMotionProbe.swift
    - drinkpulseTests/DesignSystem/DPMotionTests.swift
    - drinkpulseUITests/Features/Dashboard/ReduceMotionDashboardUITests.swift
    - drinkpulseUITests/Features/History/ReduceMotionHistoryUITests.swift
  modified:
    - drinkpulse/UITestSeed.swift
    - drinkpulse/Features/Dashboard/Components/ConsumptionOverviewCard.swift
    - drinkpulse/Features/History/Components/HistoryCalendarView.swift
    - drinkpulse/DesignSystem/DPArcProgress.swift
    - .planning/phases/11-ios-27-release-verification/11-A11Y-CHECKLIST.md
    - .planning/phases/11-ios-27-release-verification/11-DECISION-C014.md
    - .planning/phases/11-ios-27-release-verification/11-DECISION-C015.md
key-decisions:
  - "D11-23 realized: all three sites read Reduce Motion through DPMotion; accessibilityReduceMotion is get-only, so UI tests force the state through a gated seam flag, never through the environment"
  - "CHK-03 re-run is recorded as open, not pass: the owner reported no discriminating difference (the callout has no visible animation in either state)"
  - "The arc animation defect observation is recorded as OBS-D and is not fixed here (out of plan scope)"
patterns-established:
  - "Probe overlays are attached after the host's accessibilityElement modifier so .combine or .ignore cannot merge them away"
requirements-completed: []  # VER-03 and VER-01 are not completed by this plan; plan 11-24 and the phase reconciliation own requirement status
status: complete
commits: 4
plan_head_before: 955877d493104d608b94e0eab7d1bd127b504de7
plan_head_after: f1468b907b2669e13f713cffe43d417306b50b4e
actuals:
  tokens: 5900
  tasks: 4
  commits: 4
duration: multi-session, owner checkpoint included
completed: 2026-11-16
---

# Phase 11 Plan 14: Reduce Motion gate for three animation sites Summary

The Home overview bars, the History calendar detail animation and the Home arc now take their animation from one tested seam (`DPMotion`) that returns nil when Reduce Motion is on, with a launch-argument route and probe for UI tests, and the owner re-run on a simulator clone passed CHK-04, CHK-05 and CHK-06.

## Accomplishments

- **Task 1 (tracer, commits e5b9040, 5cc5f23):** `DPMotion` (`isReduced(system:forced:)`, `animation(_:reduceMotion:forced:)`), gated `-dp_uitest_reduce_motion YES` in `UITestSeed` (requires `-dp_uitest`), `DPMotionProbe` (identifier `dp_motion.<site>`, label `reduced` or `animated`, rendered only under `UITestSeed.isActive`), the overview bars through the seam, `DPMotionTests` (7 Swift Testing tests) and `ReduceMotionDashboardUITests`.
- **Task 2 (commit fc0a7f7):** the History calendar detail and the Home arc through the same seam, `ReduceMotionHistoryUITests`, a heroArc pair in `ReduceMotionDashboardUITests`, and the owner clone.
- **Task 3 (owner checkpoint, no commit):** owner re-run on the simulator clone, recorded below.
- **Task 4 (commit f1468b9):** re-run blocks under CHK-03 to CHK-06, an Outcome (plan 11-14) section in the C014 and C015 briefs, OBS-D in the checklist, clone deleted.

## Owner re-run (Task 3)

| Item | Owner result | Recorded |
| ---- | ------------ | -------- |
| CHK-05 (overview bars) | pass: jump with Reduce Motion on, animate with it off | pass |
| CHK-04 (Home arc) | pass: no animation with Reduce Motion on; caveat that the arc may have no animation at all or one too fast to see | pass, with OBS-D |
| CHK-06 (History calendar detail) | pass | pass |
| T12 / CHK-03 (Insights callout) | difference: no; the callout appears and disappears abruptly in both states | open (not pass) |

The original result lines of the checklist are unchanged (11 `result:` lines). The CHK-03 re-run is open because the owner did not call it pass and saw no before and after difference; the original owner pass with the same caveat stays as written.

## Apple API record

Consulted through Xcode MCP DocumentationSearch (the previous agent, before coding):

- `EnvironmentValues.accessibilityReduceMotion`: `var accessibilityReduceMotion: Bool { get }`, SwiftUI, "Whether the system preference for Reduce Motion is enabled". It is get-only, so it cannot be overridden in the environment; the UI-test override therefore lives in the `DPMotion` `forced` seam flag. The documentation excerpt carried no availability string; the API is used at the iOS 27.0 deployment target.
- `UIAccessibility.isReduceMotionEnabled` (UIKit): "whether the Reduce Motion setting is in an enabled state". Used only in the UI-test skip rule for the negative controls.
- `View.animation(_:value:)`: applies the animation when the value changes; a nil animation means the view does not animate.
- `View.accessibilityIdentifier(_:)`: "Use this value for testing", not visible to the user; `View.accessibilityLabel` carries the probe state.
- `XCUIElementQuery.matching(identifier:)` (matches identifier, title, label, value or placeholder), `matching(NSPredicate)`, `descendants(matching:)`.
- `XCUIDevice`: planner finding not re-checked; no API turns Reduce Motion on.

Rationale: an environment value that is get-only forces one seam that both the animation modifier and the probe read (T-11-49), with the forced flag reachable only under `-dp_uitest` (T-11-48).

## Verification run (Xcode MCP)

- Build: 0 warnings; 0 diagnostics in the changed files.
- `DPMotionTests` 7 of 7; Reduce Motion UI tests 6 of 6 (both negative controls actually ran, device Reduce Motion off); `DashboardUITests` 5 of 5; History calendar regression tests 3 of 3. Result files `rm-t1-*.result.txt` and `rm-t2-*.result.txt` are in the out-of-git stamp directory.
- `git diff --name-only fc506f4 -- drinkpulse` lists exactly the six allowed production files (`DPArcProgress.swift`, `DPMotion.swift`, `DPMotionProbe.swift`, `ConsumptionOverviewCard.swift`, `HistoryCalendarView.swift`, `UITestSeed.swift`).
- Schema guard `git diff --quiet fbd37fa` on `Domain/Persistence/Schemas` and `MigrationPlan.swift` exits 0. No Swift file over 300 lines.
- Task 4 gate: one re-run result per CHK-03 to CHK-06, Outcome line in C014 and C015, at least 11 original `result:` lines, no `dp-phase11-a11y` device, no UUID-shaped string in the three documents: printed ok.
- Suite scope: scoped runs only (AGENTS.md scoped-run rule); no full suite and no coverage report was run in this plan.

## Test limit (honest statement)

XCUITest waits for the app to be idle, so it cannot observe an animation frame, and `XCUIDevice` has no Reduce Motion control. The UI tests prove that the forced route reaches each site and that each site reports the reduced or animated state through the same decision the animation modifier uses. The unit tests prove `DPMotion.animation` is nil when reduced. Only the owner observation proves the behavior, and it covers the system setting on the simulator, not a device.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Probe label auto-extracted into the string catalog**
- **Found during:** Task 1
- **Issue:** a literal `accessibilityLabel("reduced")` made Xcode extract "reduced" and "animated" into `Localizable.xcstrings`.
- **Fix:** typed `String` labels; the catalog diff was discarded and the catalog is untouched.
- **Commit:** 5cc5f23

### Other observations

2. `ConsumptionOverviewCard` uses a `barAnimation` computed property with a `guard hasSettledOnce`, and `DPArcProgress` an `arcAnimation` property, because the plan's grep gate forbids the old literal ternary.
3. The probes are `.overlay` views attached after the host's `.accessibilityElement(...)` modifier; inside `.combine` or `.ignore` they would be merged away.
4. `DashboardHeroCard` (`.accessibilityElement(children: .combine)`) merges the arc subtree; the combined hero element inherits the identifier `dp_motion.heroArc` with a label such as "Today's Intake: 2.0 std", so the query matched 2 elements. The heroArc test filters by label in {reduced, animated}. Cause inferred, not proven.
5. `RunSomeTests` identifiers need a `()` suffix for XCTest methods.
6. Simulator setup: the primary simulator (iPhone 18 Pro) was shut down and cloned with `simctl` (11-06 precedent); the clone was deleted in Task 4. The primary stays shut down; plans that run tests boot it again.
7. My first Task 4 commit carried AI attribution lines against AGENTS.md; I amended it before any further work (local, never pushed), so the final history has none.

## Issues and follow-ups

- **OBS-D (open, new):** with Reduce Motion off the Home arc shows no visible animation, while the overview bars animate. The owner suspects an arc defect (animation too fast or not running). Cause not established; hypothesis only. It may relate to deferred review findings WR-01 and WR-02 (the arc may not interpolate). Not fixed here (out of plan scope). It needs an owner decision or a later plan. If the arc never animates, the CHK-04 pass is true by construction.
- **T12 / CHK-03:** the Insights callout has no visible animation with Reduce Motion off or on, so that gate remains undemonstrated by a before and after difference. Recorded as open; no change made.
- **Gap G-1:** the three sites are gated, covered by unit and UI tests, and CHK-04, CHK-05 and CHK-06 are pass with T12 re-checked and recorded, so the plan's success criterion for G-1 is met; the two caveats above stay open.
- Ledger rows were not edited (plan 11-24 reconciles DL-O07 to DL-O09 and DL-O15). Requirement status (VER-03, VER-01) is not changed by this plan.

## Known Stubs

None.

## Threat Flags

None. The only new surface is the `-dp_uitest_reduce_motion` argument and the probe element, both gated on `-dp_uitest` (T-11-48); no network, auth, schema or logging change.

## Self-Check: PASSED

- Files present: DPMotion.swift, DPMotionProbe.swift, DPMotionTests.swift, ReduceMotionDashboardUITests.swift, ReduceMotionHistoryUITests.swift, the checklist and the two briefs.
- Commits e5b9040, 5cc5f23, fc0a7f7 and f1468b9 are ancestors of HEAD; `git rev-list --count` from the ledger base gives 4.
