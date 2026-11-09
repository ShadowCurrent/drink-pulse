---
phase: 10-data-platform-integration-modernization
plan: "05"
subsystem: services
tags: [swift-testing, healthkit, concurrency, known-issue, decision-brief]

requires:
  - phase: 08-ios-27-baseline-api-inventory
    provides: D-09 to D-11 owner brief gate and the 08-DECISION-C011 brief format
provides:
  - HealthServiceConcurrencyTests F2 known-issue pin and sequential edit-then-delete control
  - 10-DECISION-F2.md brief with the owner decision recorded (fix-query-first)
affects: [10-08 Health F2 fix application]

actuals:
  tasks: 4
  commits: 3
plan_head_before: 4fc01253466793723cb617539e8503c1c03abc4d
plan_head_after: ba02e9878cd7eb821544d5c6a2a7c97ea91b8ee6

tech-stack:
  added: []
  patterns:
    - "withKnownIssue pin that fails loudly if the defect stops reproducing while the wrapper is present"

key-files:
  created:
    - drinkpulseTests/Services/HealthServiceConcurrencyTests.swift
    - .planning/phases/10-data-platform-integration-modernization/10-DECISION-F2.md
  modified: []

key-decisions:
  - "F2 owner decision fix-query-first (2026-11-09): in HealthService.performRemoveSample query store.sampleUUID(forEventUUID:) first, fall back to the captured healthKitUUID; applied by plan 10-08"

requirements-completed: []

coverage:
  - id: D1
    description: "F2 pinned: a remove queued behind an in-flight update leaves an orphan Health sample (known issue)"
    requirement: INT-02
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/HealthServiceConcurrencyTests.swift#removeQueuedBehindInFlightUpdate_leavesNoSample_knownIssueF2"
        status: pass
    human_judgment: false
  - id: D2
    description: "Sequential edit-then-delete control passes unwrapped, proving per-event serialization is intact"
    requirement: INT-02
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/HealthServiceConcurrencyTests.swift#updateThenRemove_awaitedSequentially_leavesNoSample"
        status: pass
    human_judgment: false
  - id: D3
    description: "F2 owner decision brief with the owner's recorded decision"
    requirement: MOD-03
    verification:
      - kind: other
        ref: "Task 4 python record check: 'F2 decision recorded: fix-query-first'"
        status: pass
    human_judgment: true
---

# Phase 10 Plan 05: Health edit-then-delete orphan sample (F2) Summary

**F2 is pinned with a `withKnownIssue` test and a passing sequential control. The owner chose `fix-query-first`, which is recorded for plan 10-08 to apply.**

## Performance

- **Tasks:** 4 of 4 (Task 3 was the owner checkpoint)
- **Files:** 2 created, no production file modified

## Accomplishments

- **Pin test:** `removeQueuedBehindInFlightUpdate_leavesNoSample_knownIssueF2` proves that a quick delete queued behind an in-flight edit leaves an orphan sample. The cause is the stale captured UUID. The known issue recorded is `Expectation failed: fake.samplesByEvent[event.uuid] == nil`. With the wrapper removed, the test fails, so the wrapper cannot rot silently.
- **Control test:** `updateThenRemove_awaitedSequentially_leavesNoSample` passes unwrapped, which shows per-event serialization is intact.
- **Scoped run:** `HealthServiceConcurrencyTests`, `HealthServiceTests` and `HealthServiceRemoveSampleTests` passed 30 tests in 3 suites, with 1 known issue. The new file produces no warnings.
- **No production change:** `git diff fbd37fa` on `HealthService.swift`, `HealthWriteHooks.swift`, `FakeHealthStore.swift` and `HealthServiceTests.swift` is empty.
- **Brief:** `10-DECISION-F2.md` follows the D-10 format, and its Owner decision record is filled in.

## Task Commits

1. **Task 1: F2 pin plus sequential control.** `879f2a2` (test)
2. **Task 2: F2 owner decision brief.** `bd7237d` (docs)
3. **Task 3: owner decision.** This was a checkpoint, so it has no commit. The owner answered `fix-query-first`.
4. **Task 4: record the owner decision.** `ba02e98` (docs)

## Decisions Made

- **F2 outcome:** `fix-query-first`, dated 2026-11-09, with no scope edits.
- **Where the answer came from:** The orchestrator collected the owner's answer directly, through its own owner prompt. The original executor refused to record a relayed answer. The owner then chose "orchestrator records inline", so the orchestrator ran Task 4 and wrote this SUMMARY itself.

## Deviations from Plan

- **[Rule 3, orchestrator override] Simulator:** The assigned simulator `4744814D-BEFF-481A-9D46-B2F59E13E530` was used instead of a newly cloned one. Derived data was `build/p10-05`, which is gitignored.
- **[Rule 1, warning fix] `await` on `withKnownIssue`:** The closure has no async work, so it resolves to the sync overload. The `await` was dropped to keep the zero-warning gate.
- **Tooling:** Xcode MCP was not available inside the worktree, so all builds and tests ran through the `xcodebuild` CLI. The `withKnownIssue` signature came from `Testing.swiftinterface` in Xcode 27.2 (iPhoneSimulator).
- **Task 4 and SUMMARY:** The orchestrator wrote these, as noted under Decisions Made.

## Issues Encountered

- The first executor run was interrupted by a session usage limit and a machine reboot under parallel-build load. Tasks 1 and 2 had already been committed.

## Next Phase Readiness

- Plan 10-08 can read the filled Owner decision record (`Outcome: fix-query-first`) and apply the fix in `HealthService.performRemoveSample`. In that fix, the F2 pin loses its `withKnownIssue` wrapper.

## Self-Check: PASSED

- `drinkpulseTests/Services/HealthServiceConcurrencyTests.swift` exists.
- `.planning/phases/10-data-platform-integration-modernization/10-DECISION-F2.md` exists, and the record check passes.
- Commits `879f2a2`, `bd7237d` and `ba02e98` are present on `worktree-agent-a5324a9ede4f424d8`.
