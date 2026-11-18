---
phase: 10-data-platform-integration-modernization
plan: "06"
subsystem: services
tags: [swift-testing, usernotifications, concurrency, known-issue, decision-brief]

requires:
  - phase: 08-ios-27-baseline-api-inventory
    provides: D-09 to D-11 owner brief gate and the 08-DECISION-C011 brief format
provides:
  - SlowNotificationCenter test double (first add suspends until release)
  - ReminderServiceCancellationTests and WeeklySummaryServiceCancellationTests with F3 known-issue pins and controls
  - 10-DECISION-F3.md brief with the owner decision recorded (fix-service-epoch, O1 approved)
affects: [10-09 notification F3 fix application]

actuals:
  tasks: 4
  commits: 3
plan_head_before: 4fc01253466793723cb617539e8503c1c03abc4d
plan_head_after: 6e8f97122516a902e19d921d556a83260e4592f7

tech-stack:
  added: []
  patterns:
    - "Deterministic suspending notification center (OSAllocatedUnfairLock-guarded) to pin cancel-during-add races"

key-files:
  created:
    - drinkpulseTests/Services/SlowNotificationCenter.swift
    - drinkpulseTests/Services/ReminderServiceCancellationTests.swift
    - drinkpulseTests/Services/WeeklySummaryServiceCancellationTests.swift
    - .planning/phases/10-data-platform-integration-modernization/10-DECISION-F3.md
  modified: []

key-decisions:
  - "F3 owner decision (2026-11-09): S1 and S2 lifecycle epoch in ReminderService and WeeklySummaryService applied by plan 10-09; S3 ReminderSection guard not applied; O1 NotificationActionHandler plain Sendable approved"

requirements-completed: []

coverage:
  - id: D1
    description: "Reminder cancel-during-schedule race pinned (known issue) with completed-schedule and schedule-cancel-schedule controls"
    requirement: INT-01
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/ReminderServiceCancellationTests.swift#cancel_whileScheduleSuspendedInAdd_leavesNoPendingRequest, cancel_afterScheduleCompleted_leavesNoPendingRequest, scheduleCancelSchedule_leavesExactlyOnePendingRequest"
        status: pass
    human_judgment: false
  - id: D2
    description: "Weekly scene-active-versus-opt-out race pinned (known issue, research assumption A4 confirmed) with controls"
    requirement: INT-01
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceCancellationTests.swift#optOut_whileSceneActiveRescheduleSuspendedInAdd_leavesNoPendingRequest, cancel_afterScheduleCompleted_leavesNoPendingRequest, scheduleIfEnabled_whenOptedOut_addsNothingAndNeverEntersAdd"
        status: pass
    human_judgment: false
  - id: D3
    description: "F3 owner decision brief with the owner's recorded decision"
    requirement: MOD-03
    verification:
      - kind: other
        ref: "Task 4 python record check: 'F3 decision recorded: fix-service-epoch+handler-sendable'"
        status: pass
    human_judgment: true
---

# Phase 10 Plan 06: Notification cancel-while-scheduling race (F3) Summary

**Both notification services' cancel-during-`add` races are pinned with deterministic known-issue tests and passing controls. The owner chose service-level epoch fixes and plain `Sendable` on `NotificationActionHandler`, recorded for plan 10-09.**

## Performance

- **Tasks:** 4 of 4 (Task 3 was the owner checkpoint)
- **Files:** 4 created, no production file modified

## Accomplishments

- **Test double:** `SlowNotificationCenter` suspends the first `add` until `release()` is called. It replaces requests by identifier and exposes `addEntered` and `operationLog`. It is guarded by `OSAllocatedUnfairLock`.
- **Reminder pin:** `cancel_whileScheduleSuspendedInAdd_leavesNoPendingRequest` passes by recording its known issue. With the wrapper removed, it fails with `Expectation failed: pending.isEmpty`.
- **Weekly pin:** `optOut_whileSceneActiveRescheduleSuspendedInAdd_leavesNoPendingRequest` passes by recording its known issue. This confirms research assumption A4, that the weekly service shares the race.
- **Controls:** all control tests pass unwrapped.
- **Test runs:** Task 1 passed 15 tests in 2 suites, with 1 known issue. Task 2 passed 13 tests in 3 suites, with 2 known issues. The new files produce no warnings. The `git diff --quiet fbd37fa` guards exit 0, so no production notification code changed.

## Task Commits

1. **Task 1: reminder race pin, suspending center and control.** `acf7a50` (test)
2. **Task 2: weekly race pin and F3 brief.** `05e15be` (test and docs)
3. **Task 3: owner decision.** This was a checkpoint, so it has no commit. The owner answered `fix-service-epoch` and approved O1.
4. **Task 4: record the owner decision.** `6e8f971` (docs)

## Decisions Made

- **F3 outcome:** `fix-service-epoch` plus the O1 approval marker, dated 2026-11-09.
  - S1 is applied.
  - S2 is applied.
  - S3 is not applied.
  - O1 is approved.
- **Where the answer came from:** The orchestrator collected the owner's answer directly, through its own owner prompt. The original executor refused to record a relayed answer. The owner then chose "orchestrator records inline", so the orchestrator ran Task 4 and wrote this SUMMARY itself.

## Deviations from Plan

- **Simulator:** The assigned simulator `624729B4-B694-42F1-9EDD-1F1623461879` was used instead of a newly cloned one.
- **Tooling:** Xcode MCP was not connected in the worktree, so builds and tests used the `xcodebuild` CLI.
- **API sources:** `OSAllocatedUnfairLock` signatures came from the iPhoneOS 27.2 SDK `os.swiftinterface`. Replace-by-identifier semantics came from `UNUserNotificationCenter.h`.
- **Task 4 and SUMMARY:** The orchestrator wrote these, as noted under Decisions Made.

## Issues Encountered

- **Pre-existing warning:** `HealthWriteHooksTests.swift:116` has an `UnnecessaryEffectMarker` warning. It is out of scope here. Plan 10-07 owns that file.

## Next Phase Readiness

- Plan 10-09 can read the filled record and apply S1, S2 and O1. In that change, both pins lose their `withKnownIssue` wrappers.

## Self-Check: PASSED

- All 4 created files exist on `worktree-agent-a03ba6427b01d25e2`.
- Commits `acf7a50`, `05e15be` and `6e8f971` are present, and the record check passes.
