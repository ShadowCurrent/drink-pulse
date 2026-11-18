---
phase: 10-data-platform-integration-modernization
plan: "08"
subsystem: health-integration
tags: [healthkit, swift-concurrency, swift-testing, xcuitest, adr-0011]

requires:
  - phase: 10-data-platform-integration-modernization
    provides: "10-05 F2 brief, pin test and owner decision record; 10-07 ordering pins"
provides:
  - "HealthService.performRemoveSample resolves the current sample by dp_event_uuid first, captured UUID only as fallback"
  - "F2 pin flipped to a plain regression test plus stale-UUID, query-nothing and query-throws tests"
  - "Log-edit-delete UI test asserting dp_health_sample_count 1, 1, 0"
affects: [10-12 device check (assumption A5)]

actuals:
  tokens: 2170
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Serialized remove resolves target by metadata source of truth, cached UUID is a fallback"

key-files:
  created: []
  modified:
    - drinkpulse/Services/HealthService.swift
    - drinkpulseTests/Services/HealthServiceConcurrencyTests.swift
    - drinkpulseTests/Services/HealthServiceRemoveSampleTests.swift
    - drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift

key-decisions:
  - "Applied owner outcome fix-query-first (10-DECISION-F2.md, 2026-11-09) exactly as recorded, no scope edits"
  - "Nested do/catch around the lookup so a throwing query falls back to the captured UUID instead of aborting the remove"

patterns-established:
  - "Lookup failure is logged by error description only (no UUIDs) and never blocks the delete"

requirements-completed: [INT-02, MOD-03]

coverage:
  - id: D1
    description: "Serialized Health remove deletes the sample that exists when it runs, so edit then quick delete leaves no orphan"
    requirement: "INT-02"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/HealthServiceConcurrencyTests#removeQueuedBehindInFlightUpdate_leavesNoSample_knownIssueF2"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/HealthServiceConcurrencyTests#removeSample_deletesStoredSample_whenCapturedUUIDIsStale"
        status: pass
    human_judgment: false
  - id: D2
    description: "Captured-UUID fallback when the query finds nothing or throws"
    requirement: "MOD-03"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/HealthServiceConcurrencyTests#removeSample_fallsBackToCapturedUUID_whenQueryFindsNoSample"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/HealthServiceConcurrencyTests#removeSample_fallsBackToCapturedUUID_whenQueryThrows"
        status: pass
    human_judgment: false
  - id: D3
    description: "User flow log, edit, delete leaves zero Health samples in the UI-test store"
    requirement: "INT-02"
    verification:
      - kind: automated_ui
        ref: "drinkpulseUITests/HealthWriteHooksUITests/test_healthEnabled_logEditDelete_leavesNoHealthSample"
        status: pass
    human_judgment: false
  - id: D4
    description: "Real HealthKit behavior when deleting an already-deleted sample (assumption A5) and the fix on a real device"
    verification: []
    human_judgment: true
    rationale: "Simulator fake store cannot show real HealthKit semantics; plan 10-12 device check observes it."

plan_head_before: 67514a19250f8db9e8c9359a88c8f9aabd8e272a
plan_head_after: 8c3327df240361e3ac59c4cac5e8fc0e3a3eac6f
commits: 3

duration: 25min
completed: 2026-11-09
status: complete
---

# Phase 10 Plan 08: F2 Health orphan-sample fix Summary

**Serialized Health remove now queries the current sample by `dp_event_uuid` first and falls back to the captured UUID only when the query finds nothing or throws, closing the edit-then-quick-delete orphan (F2).**

## Owner decision applied

10-DECISION-F2.md Owner decision record: Outcome `fix-query-first`, dated 2026-11-09, reason "Smallest change that uses the `dp_event_uuid` metadata as the source of truth". Exact scope text matches the plan defaults (query first, delete result, captured UUID fallback on nil or throw, regression tests, one UI test, no other file changes). No difference from plan defaults to note.

## Accomplishments

- `HealthService.performRemoveSample`: after the unchanged authorization guard, `store.sampleUUID(forEventUUID:)` runs first; a found sample is the delete target. A nil or thrown lookup leaves the captured `healthKitUUID` as the target. A lookup error is logged (error description only) and swallowed; delete errors are logged and swallowed as before.
- F2 pin `removeQueuedBehindInFlightUpdate_leavesNoSample_knownIssueF2` lost its `withKnownIssue` wrapper and is now a plain expectation; enqueue helper and update-first order untouched.
- Three new tests: stale captured UUID deletes the stored sample; query-nothing falls back to captured; query-throws falls back to captured with the error swallowed.
- New UI test `test_healthEnabled_logEditDelete_leavesNoHealthSample`: probe reads 0, then 1 after logging, 1 after editing, 0 after confirmed delete, event gone from History.

## Task Commits

1. Task 1 RED: `234d942` test(10-08): failing F2 regression tests
2. Task 1 GREEN: `86d5639` feat(10-08): resolve current Health sample by dp_event_uuid before remove
3. Task 2: `8c3327d` test(10-08): log-edit-delete Health UI test

## TDD Gate Compliance

- RED: target `removeQueuedBehindInFlightUpdate_leavesNoSample_knownIssueF2()` failed on `Expectation failed: fake.samplesByEvent[event.uuid] == nil`. `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` (swift-testing, 5 tests, 4 failing: the pin and the stale-UUID, query-nothing, query-throws tests; the awaited-sequential control passed). Semantic assessment: target executed and failed on the planned assertion (stale captured UUID deleted, fresh sample survives); the new fallback tests fail on their planned `queryCount == 1` / `deletedUUIDs` assertions because the old code never queried when a UUID was captured.
- GREEN: same suite plus ordering, service, remove-sample and hooks suites: `Test run with 43 tests in 5 suites passed`.
- REFACTOR: none needed.
- Task 2 is `tdd="true"` but cannot have a meaningful RED: the UI-test store completes instantly, so the flow passes with or without the fix. It is integration evidence only; the race is pinned by the unit regression.

## Isolation and lifecycle reasoning (D-13)

`HealthService` is `@MainActor`; `performRemoveSample` runs inside the existing `runSerial` per-event chain. The change adds one awaited store call (the lookup) inside already-serialized work. No actor, Task or cancellation structure changed, `runSerial`, public signatures, `performWrite`, `performUpdate`, `backfill`, authorization and the cache clearing in `performRemove` are untouched. Because the remove starts only after the preceding update finished, the lookup sees the sample update just wrote. `HealthWriteHooks.swift` and `HealthWriting.swift` unchanged (`git diff --quiet fbd37fa -- ...` exits 0). Delete stays non-blocking (hooks still enqueue a Task); `dp_event_uuid` stays the source of truth; `healthKitUUID` stays device-local and unexported; opt-in unchanged.

## Official source (AGENTS.md Apple policy)

- Xcode MCP `DocumentationSearch` was not available to this executor, so the iPhoneOS 27.2 SDK header `HealthKit.framework/Headers/HKHealthStore.h` was read: `deleteObjects:withCompletion:` and `deleteObjectsOfType:predicate:withCompletion:` document "An application may only delete objects that it previously saved", `API_AVAILABLE(ios(9.0) ...)`, available at the iOS 27 minimum. `HKQuery.predicateForObjects(withMetadataKey:operatorType:value:)` and `HKSampleQueryDescriptor` are already used by `HealthKitAdapter.sampleUUID(forEventUUID:)`. developer.apple.com page text was not re-fetched; the decision record cites the same pages. No API added, replaced or deprecated.
- Route record: builds and tests ran via `xcodebuild` CLI fallback (Xcode MCP acts on the main workspace, not this worktree, per the dispatch instructions) on the assigned simulator `02193FDE-1810-4E16-8E72-73371BBC7F1E` (iPhone 17, iOS 27.2) with worktree-local `-derivedDataPath build/`. Dedicated-simulator creation from the plan Execution note was replaced by the orchestrator's assignment.

## Regression evidence

- `build/p10-08-t1.log`: `Test run with 43 tests in 5 suites passed` (concurrency, ordering, service, remove-sample, hooks suites); no warnings in changed Swift files.
- `build/p10-08-t2.log`: `Executed 6 tests, with 0 failures` (HealthWriteHooksUITests 4 tests incl. the new one, HealthSettingsUITests 2).
- Pin wrapper state matches outcome (0 occurrences of `withKnownIssue`).

## Deviations from Plan

### Justified edit to an existing test (plan-permitted)

`HealthServiceRemoveSampleTests.removeSample_deletesByCachedUUID` asserted `fake.queryCount == 0`, which encoded the old strategy (no query when a UUID is captured). Changed to `queryCount == 1`, renamed to `removeSample_deletesSample_whenCachedUUIDMatchesStoredSample`, with a comment citing F2. The behavioral assertion (`deletedUUIDs == [sample]`) is unchanged. Commit `86d5639`.

### Other notes

- UI test edit interaction changes the custom name (typed into the Custom Name field), not the volume. The plan said "for example changing its volume"; `EditEventView.save()` always calls `HealthWriteHooks.update`, so any edit exercises the same delete-and-rewrite path, and the typing interaction is the proven one in existing UI tests.
- Verify command `-derivedDataPath build/p10-08` and `LOCAL_IOS_27_UDID_P10_08` were substituted by the orchestrator-assigned `build/` and simulator; logs were still written to `build/p10-08-t1.log` and `build/p10-08-t2.log`.

**Total deviations:** 0 auto-fixed bugs. **Impact:** none on scope; ADR-0011 invariants unchanged.

## Known Stubs

None.

## Threat Flags

None. Threat T-10-17 mitigated (target resolved by `dp_event_uuid`, unit regressions, ordering pins pass). T-10-18 mitigated (new log line prints the error description only, no UUIDs or event data).

## Open items

- Assumption A5 (real HealthKit behavior when deleting an already-deleted sample) remains for the plan 10-12 device check.
- Full test suite not run (orchestrator runs it after merge); scoped runs only per dispatch instructions.
- Living docs audit: no living doc describes the remove strategy; ADR-0011 is frozen and its value-based delete contract is unchanged.

## Self-Check: PASSED

- FOUND: drinkpulse/Services/HealthService.swift, drinkpulseTests/Services/HealthServiceConcurrencyTests.swift, drinkpulseTests/Services/HealthServiceRemoveSampleTests.swift, drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift
- FOUND commits: 234d942, 86d5639, 8c3327d (ancestors of HEAD)
