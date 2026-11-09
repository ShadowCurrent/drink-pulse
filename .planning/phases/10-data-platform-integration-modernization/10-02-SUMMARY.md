---
phase: 10-data-platform-integration-modernization
plan: "02"
subsystem: notifications
tags: [notifications, ui-test-seam, tap-routing, swift-testing, xcuitest]
requires: []
provides:
  - NotificationActionHandler.route(identifier:defaults:) static async tap router
  - UITestNotificationCenter.deliverTap(identifier:)
  - UITestSeed.armWarmWeeklySummaryTap (-dp_uitest_warm_weekly_tap, gated on -dp_uitest)
  - Warm weekly-summary tap UI test and NotificationActionHandlerTests unit suite
affects: [10-12 real-device cold and warm tap checks]
tech-stack:
  added: []
  patterns: [extract-delegate-body-into-testable-static-seam, launch-argument-gated one-shot UI-test hook]
key-files:
  created:
    - drinkpulseTests/Services/NotificationActionHandlerTests.swift
  modified:
    - drinkpulse/Services/NotificationActionHandler.swift
    - drinkpulse/Services/UITestNotificationCenter.swift
    - drinkpulse/UITestSeed.swift
    - drinkpulse/Features/Shell/RootShellView.swift
    - drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift
key-decisions:
  - "Warm tap enters through UITestNotificationCenter.deliverTap -> NotificationActionHandler.route, never a direct call from RootShellView (D-14)."
  - "No isolation keyword was added: the project default actor isolation is MainActor, so route and deliverTap compiled unchanged (D-12)."
requirements-completed: [INT-01]
duration: long (wall clock dominated by machine load and a reboot)
completed: 2026-11-09
status: complete
commits: 3
plan_head_before: 4fc01253466793723cb617539e8503c1c03abc4d
plan_head_after: ec451156033124f7ad17eed0428a60cda4fa0d49
actuals:
  tokens: 9000
  tasks: 2
  commits: 3
---

# Phase 10 Plan 02: Warm weekly-summary tap routing Summary

Weekly-summary tap delivered while the app is backgrounded now routes to the Insights tab with automated proof, through a testable `NotificationActionHandler.route` seam fed by `UITestNotificationCenter.deliverTap` and a launch-argument-gated one-shot hook in `RootShellView`.

## What was built

- **Task 1 (tracer):** `route(identifier:defaults:)` extracted verbatim in behavior from the delegate `didReceive` callback, which is now a one-line hand-off (`await Self.route(...)`). `UITestNotificationCenter.deliverTap(identifier:)` awaits `route`. `UITestSeed.armWarmWeeklySummaryTap` returns false unless `isActive` and `-dp_uitest_warm_weekly_tap YES` are both present. `RootShellView` holds `warmTapArmed` and `hasEnteredBackground`; on return to active after a background it disarms, creates a `UITestNotificationCenter` (only after both guards pass) and delivers the weekly-summary tap. `RootShellView.swift` is 167 lines.
- **Task 2:** `NotificationActionHandlerTests` (Swift Testing, `@MainActor`, `.serialized`): reminder id, weekly id, unknown id, and the persisted identifier constants. Uses a fresh UUID-named `UserDefaults` suite per test and counting NotificationCenter observers.

## TDD evidence

- **RED (Task 1 warm UI test, commit 5c02c77):** `test_weeklySummaryTap_opensInsightsTab_onWarmLaunch` was written and run before any hook existed. The cold test passed; the warm test failed at `WeeklySummaryTapUITests.swift:39`, the final `navigationBars["Insights"].waitForExistence` assertion. Semantic assessment: target test executed, got through the launch, Home, background and `activate()` steps, and failed on the planned assertion for the intended reason (no tap delivered). Log: `build/p10-02-red.log`.
- **GREEN (commit 249de68):** both `WeeklySummaryTapUITests` tests pass; `Executed 2 tests, with 0 failures`.
- **Task 2 RED (deviation, see below):** `route` already existed from Task 1, so the new unit tests are characterization tests and cannot be RED by construction. Instead a mutation check proved they can fail: changing the weekly branch to write `pendingAddDrink` made `route_weeklySummaryIdentifier_setsOpenInsightsFlagAndPostsWeeklyTapOnce` fail (2 expectations: `openInsightsFlag == true`, `addDrinkFlag == nil`; run exit 65). The mutation was reverted before commit.

## Verification results

| Check | Result |
|-------|--------|
| WeeklySummaryTapUITests (cold + warm) | passed, 0 failures |
| NotificationActionHandlerTests + ReminderServiceTests + WeeklySummaryServiceTests + WeeklySummaryServiceScheduleTests + WeeklySummaryCalculatorTests | `Test run with 43 tests in 5 suites passed` |
| ReminderSettingsUITests + WeeklySummarySettingsUITests + OnboardingWeeklySummaryUITests + WeeklySummaryTapUITests | `Executed 7 tests, with 0 failures` |
| Source assertions (class declaration unchanged, `route`/`Self.route`, `deliverTap` -> `NotificationActionHandler.route`, arm flag references `isActive`, RootShellView references flag, `UITestNotificationCenter`, `deliverTap`) | pass |
| `git diff --quiet fbd37fa -- drinkpulse/drinkpulseApp.swift` | exit 0 (unchanged) |
| RootShellView line count | 167 (<=300); NotificationActionHandlerTests 80 |
| Warnings for NotificationActionHandlerTests.swift | none |

## Apple documentation source and tooling route

- Documentation: Xcode MCP DocumentationSearch was not available to this subagent, so the UserNotifications SDK headers (`iPhoneOS27.2.sdk/.../UserNotifications.framework/Headers/UNNotificationResponse.h` and `UNNotification.h`) were consulted. Both mark `- (instancetype)init NS_UNAVAILABLE`, confirming a real tap cannot be constructed. No Apple API was added or changed, only the project's own seam.
- Build and test route: CLI fallback (`xcodebuild test` with `-only-testing`) for every run, because the Xcode MCP acts on the main workspace, not this worktree. The plan's `xcrun simctl clone/create` dedicated-simulator step was replaced by the orchestrator-assigned simulator (iPhone 18 Pro, iOS 27.2, `B4A1A1F8-A0E2-4186-BAFD-1A02679DD4EC`) with worktree-local `-derivedDataPath build/p10-02`; the simulator was shut down at the end. Only scoped `-only-testing` runs were executed.

## Not covered by automation

The delegate callback's one-line hand-off to `route` (`userNotificationCenter(_:didReceive:)`) is the only part not exercised by automation, because `UNNotificationResponse` cannot be constructed. It is proven only by the real-device cold and warm taps in plan 10-12.

## Deviations from Plan

**1. [Process] Task 2 has no true RED phase**
- **Found during:** Task 2
- **Issue:** `tdd="true"` expects a failing test first, but `route` was extracted in Task 1, so the tests pass immediately (unexpected green by design).
- **Fix:** Treated as characterization tests and proved they can fail with a reverted mutation check (above). No separate RED commit.
- **Commit:** ec45115

**2. [Process] Dedicated simulator not cloned**
- **Issue:** Plan asked for `LOCAL_IOS_27_UDID_P10_02` via `simctl clone/create`; the orchestrator assigned a simulator and forbade touching others.
- **Fix:** Used the assigned UDID as the plan's simulator; same isolation outcome.

**3. [Environment] Interrupted run**
- Work was interrupted by a rate limit and a machine reboot under heavy load (load average above 500 during the RED run, a 573 s UI test run). The worktree was intact; the scratchpad copy of the unit test file was lost and the file was rewritten directly in the repo. No code impact.

Total deviations: 3 (all process or environment). No isolation keyword was needed on `route` or `deliverTap`.

## Threat model

T-10-04 mitigated: the arm flag requires `isActive` in its own definition, `UITestNotificationCenter` is only instantiated after the armed and background guards pass, no data is seeded and nothing is logged. T-10-05 mitigated: `route` is pinned by unit tests, cold and warm UI tests both pass, `drinkpulseApp.swift` untouched.

## Known Stubs

None.

## Threat Flags

None.

## Commits

- 5c02c77: test(10-02): add failing warm weekly-summary tap UI test
- 249de68: feat(10-02): route weekly-summary tap through UITestNotificationCenter seam
- ec45115: test(10-02): pin NotificationActionHandler.route for both identifiers and unknown

## Living docs

Not updated by this plan (test seam only, no behavior, architecture or scope change); STATE.md and ROADMAP.md are left to the orchestrator.

## Self-Check: PASSED

All five modified files and the new test file exist; commits 5c02c77, 249de68 and ec45115 are ancestors of HEAD.
