---
phase: 10-data-platform-integration-modernization
plan: "07"
subsystem: testing
tags: [swift-testing, healthkit, usernotifications, sendable, concurrency]
requires: []
provides:
  - HealthServiceOrderingTests pins for per-event ordering, double-write idempotency and interrupted-write convergence
  - NotificationOptOutTests pins for cancel isolation and no-resurrection after opt-out
  - HealthKitAdapter declared without the unchecked Sendable qualifier
  - 10-CONCURRENCY-RECORD.md with the D-12 disposition table and applied-change record
affects: [10-08, 10-09, 10-11]
actuals:
  tokens: 5500
  tasks: 3
  commits: 4
plan_head_before: 4fc01253466793723cb617539e8503c1c03abc4d
plan_head_after: ab6176daec70c6590bf4a98f7e3c9340066e2db8
tech-stack:
  added: []
  patterns:
    - Recording store wrapper that yields before each call, so a missing serialization chain shows up as interleaving
    - Deterministic enqueue helper (started flag plus Task.yield polling, 2 second deadline) instead of fixed sleeps
key-files:
  created:
    - drinkpulseTests/Services/HealthServiceOrderingTests.swift
    - drinkpulseTests/Services/NotificationOptOutTests.swift
    - .planning/phases/10-data-platform-integration-modernization/10-CONCURRENCY-RECORD.md
  modified:
    - drinkpulse/Services/HealthKitAdapter.swift
    - drinkpulseTests/Services/HealthWriteHooksTests.swift
key-decisions:
  - "HealthKitAdapter loses @unchecked Sendable under D-12: HKHealthStore and HKObjectType are NS_SWIFT_SENDABLE in the iOS 27.2 SDK and the compile probe is warning-free"
  - "All other unchecked Sendable sites retained (notification center retroactive conformance, NotificationActionHandler, UI-test and fake doubles)"
requirements-completed: [MOD-03, INT-02, INT-01]
status: complete
duration: resumed after rate limit and a host reboot; wall time not meaningful
completed: 2026-11-09
coverage:
  - id: D1
    description: "Health write, update and remove for one event run in enqueue order (save, delete, save, delete) and different events use independent chains"
    requirement: INT-02
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/HealthServiceOrderingTests.swift#writeUpdateRemove_executeInEnqueueOrder_forOneEvent"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/HealthServiceOrderingTests.swift#operationsOnDifferentEvents_doNotShareAChain"
        status: pass
    human_judgment: false
  - id: D2
    description: "Double write saves one sample and relinks; an interrupted write (sample stored, cache write lost) relinks on the next backfill with no second save"
    requirement: INT-02
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/HealthServiceOrderingTests.swift#doubleWrite_savesOneSample_andRelinksSecondCall"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/HealthServiceOrderingTests.swift#interruptedWrite_savedButNotCached_relinksOnNextBackfill_noDuplicate"
        status: pass
    human_judgment: false
  - id: D3
    description: "Reminder and weekly cancel remove only their own identifier; after opt-out plus cancel, scheduleIfEnabled adds nothing"
    requirement: INT-01
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/NotificationOptOutTests.swift (4 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "HealthKitAdapter compiles without the unchecked Sendable qualifier with zero new warnings; HealthWriteHooksTests redundant try warning removed"
    requirement: MOD-03
    verification:
      - kind: other
        ref: "xcodebuild test scoped run, build/p10-07-all.log: no Swift warning or error, 72 tests in 8 suites passed"
        status: pass
    human_judgment: false
  - id: D5
    description: "10-CONCURRENCY-RECORD.md holds the D-12 disposition table, applied-change entry and compile probe"
    requirement: MOD-03
    verification:
      - kind: other
        ref: "python3 section check from the Task 3 verify block"
        status: pass
    human_judgment: false
---

# Phase 10 Plan 07: Concurrency pins and HealthKitAdapter Sendable Summary

Health per-event ordering, idempotency and interrupted-write convergence plus notification cancel isolation are pinned by new Swift Testing suites, `HealthKitAdapter` no longer carries an unchecked Sendable qualifier, and the concurrency record is started.

## Accomplishments

- `HealthServiceOrderingTests` (4 tests): a private lock-guarded `RecordingHealthStore` wraps `FakeHealthStore` and drives the real `HealthService` through a deterministic enqueue helper. Mutating calls for write, update, remove on one event are exactly save, delete, save, delete; a double write saves once and relinks; different events do not share a chain; `interruptedWrite_savedButNotCached_relinksOnNextBackfill_noDuplicate` shows a saved-but-uncached sample is relinked by `dp_event_uuid` on the next backfill with `saveCount` still 1.
- `NotificationOptOutTests` (4 tests): each service's cancel removes only its own identifier (checked through both the pending set and the removal batch), and cancel followed by `scheduleIfEnabled` with the flag off adds nothing for both services.
- `HealthKitAdapter` is now `final class HealthKitAdapter: HealthWriting`. Scoped build had zero Swift warnings or errors.
- Removed the redundant `try` at `HealthWriteHooksTests.swift:116`.
- `10-CONCURRENCY-RECORD.md` created with the six-site D-12 table, the applied-change entry citing SDK header lines, and the compile probe; C010 to C012 headings are left for plan 10-11.

## RED/GREEN notes (TDD)

Task 1 and Task 2 are characterization pins of existing behavior (no production code changes), so there is no failing RED against missing implementation; unexpected green is the expected outcome and is not a defect. To prove the ordering pins are not vacuous, a mutation check was run: removing `await previous?.value` from `HealthService.runSerial` (reverted afterwards, the file is identical to `fbd37fa`).

- First attempt: the tests still passed, because the fake store never suspends, so operations ran to completion in start order even with no chain. This showed the first version of the pins could not catch a missing chain.
- Fix (commit b5f5261): `RecordingHealthStore` yields once (`Task.yield()`) before each forwarded call. Re-run under the same mutation: `writeUpdateRemove_executeInEnqueueOrder_forOneEvent` failed (`mutatingOps() == [.save, .delete, .save, .delete]`) and `doubleWrite_savesOneSample_andRelinksSecondCall` failed (`saveCount == 1`). `operationsOnDifferentEvents_doNotShareAChain` and the interrupted-write test pass under that mutation by design: they assert cross-event independence and convergence, not same-event ordering.
- With `HealthService.swift` restored, all four pass.

The `gsd_run check tdd-red-evidence` classifier was not used because there is no RED-phase failure to classify for pin tests.

## Task Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | ed098a9 | test(10-07): Health ordering, idempotency, interrupted-write pins |
| 1 (hardening) | b5f5261 | test(10-07): recording store yields so ordering pins catch a missing chain |
| 2 | c6daf84 | test(10-07): notification cancel isolation and no-resurrection pins |
| 3 | ab6176d | refactor(10-07): drop unchecked Sendable from HealthKitAdapter, fix test warning, concurrency record |

## Named test gap (R-02)

No automated test kills the process between the HealthKit save and the device-local cache write; a process kill cannot be reproduced on demand. The seam test simulates the resulting state with a store that commits the sample and then throws, and proves convergence (relink by `dp_event_uuid`, no second save). Accepted residual risk R-02 stands and is acknowledged by the owner in the plan 10-12 Sign-off.

## Apple documentation and tool route

- **Official source:** Xcode MCP `DocumentationSearch` was not exposed to this executor and no online documentation route was available, so the Sendable decision rests on the Apple SDK headers in `iPhoneOS27.2.sdk` (`HKHealthStore.h:36`, `HKObjectType.h:38` and `:175`, `UNUserNotificationCenter.h:39` has no annotation), read with `grep -n NS_SWIFT_SENDABLE`. Apple's online `Sendable` and `OSAllocatedUnfairLock` documentation was not read; the implementation uses `OSAllocatedUnfairLock` in the standard `withLock` form and compiled warning-free. Cross-check recommended.
- **Availability and rationale:** recorded in `10-CONCURRENCY-RECORD.md` (Applied changes and Compile probe).
- **Build and test route:** CLI fallback (`xcodebuild` with `-derivedDataPath build/p10-07`) for every step. Xcode MCP acts on the main workspace, not this worktree, so it could not build this plan's changes. The assigned simulator `1D35E1B8-4141-4EFF-A493-52CB37B600A5` was used instead of creating a dedicated one, as instructed by the dispatch; it was shut down at the end.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Ordering pins could not detect a missing serialization chain**
- **Found during:** Task 1 mutation check
- **Issue:** the first recording store forwarded calls without suspending, so the tests passed even with the chain removed.
- **Fix:** `RecordingHealthStore` yields once before each forwarded call; mutation re-run now fails two tests.
- **Files modified:** `drinkpulseTests/Services/HealthServiceOrderingTests.swift`
- **Commit:** b5f5261

### Process deviations

- **Combined verification run.** Under high host load (and after a rate limit and host reboot interrupted the first mutation run), Tasks 1 to 3 final verification was one scoped `xcodebuild test` run covering all eight suites instead of three separate runs, as the dispatch asked for scoped runs only. Result: 72 tests in 8 suites passed, zero Swift warnings or errors. Per-task acceptance greps and invariant guards (`git diff --quiet fbd37fa -- ...`) were run per task.
- **Compile probe via the test action.** The probe evidence comes from the build step of `xcodebuild test` (the log shows `HealthKitAdapter.swift` compiled), not a separate `xcodebuild build` run.
- **Commit messages** carry no AI attribution lines because AGENTS.md forbids them; this takes precedence over the harness default.

**Total deviations:** 1 auto-fixed (Rule 1), 3 process notes. **Impact:** none on scope; production code changed by one declaration only.

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths, file access or schema changes.

## Issues Encountered

An interrupted first mutation run (rate limit, host reboot) left no residue: the worktree was clean at `ed098a9` on resume and `HealthService.swift` was restored to `fbd37fa` content after the second mutation run.

## Self-Check

- Files exist: `HealthServiceOrderingTests.swift` (188 lines), `NotificationOptOutTests.swift` (107 lines), `10-CONCURRENCY-RECORD.md`.
- Commits `ed098a9`, `b5f5261`, `c6daf84`, `ab6176d` are ancestors of HEAD.
- Invariant guards: `HealthService.swift`, `FakeHealthStore.swift`, `ReminderService.swift`, `ReminderServiceTests.swift`, `NotificationScheduling.swift`, `UITestHealthStore.swift` unchanged against `fbd37fa`.
- No Swift file over 300 lines under `drinkpulse/`.

## Self-Check: PASSED
