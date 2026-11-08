# F2 — Health: edit then quick delete leaves an orphan sample

**Status:** awaiting owner decision — no Health change started
**Proposed destination:** Phase 10, plan 10-08 (applied or retained only after the Owner decision record below is filled)
**Parent decision:** C011 (`08-DECISION-C011.md`), which allows only a diagnosed Phase 10 issue that preserves every ADR-0011 invariant.

## Current behavior

A drink that is deleted right after it was edited can stay in Apple Health. Evidence:

- `drinkpulse/Services/HealthWriteHooks.swift` `remove(_:using:)` captures `event.healthKitUUID` and `event.uuid` synchronously at call time, then enqueues `service.removeSample(healthKitUUID:eventUUID:)` in a `Task`.
- `drinkpulse/Services/HealthService.swift` `performUpdate` deletes the cached sample, then calls `performWrite`, which saves a fresh sample with a new UUID and stores it on the event.
- `HealthService.swift` `performRemoveSample` deletes the passed UUID when it is non-nil and queries by `dp_event_uuid` only when it is nil.
- `runSerial` keeps per-event order correct (update finishes before the queued remove starts), but the remove still carries the UUID captured before the update. It deletes the already-deleted old sample, and the sample the update just wrote survives.

Test evidence: `HealthServiceConcurrencyTests.removeQueuedBehindInFlightUpdate_leavesNoSample_knownIssueF2` drives the real `HealthService` with `FakeHealthStore`, enqueues `update` and then `removeSample(healthKitUUID: <captured>, eventUUID:)` through a deterministic enqueue helper, and expects no sample for the event. The expectation fails today and is wrapped in `withKnownIssue`, so the test goes red if the defect stops reproducing while the wrapper is present. The control `HealthServiceConcurrencyTests.updateThenRemove_awaitedSequentially_leavesNoSample` (update awaited, then `remove` awaited) passes, which isolates the stale captured UUID plus parallel timing as the cause and shows per-event serialization itself is intact. The research probe (10-RESEARCH.md, F2) reproduced the same result on 2026-11-08.

Real-device effect: a deleted drink remains in Apple Health. D-10 trigger 3 (a failing parallel-operation test) is met by the pin. No concurrency rewrite is proposed; the existing serialization is kept.

### ADR-0011 invariants every option must preserve

1. Health write-back stays opt-in and off by default.
2. Every Health operation stays best-effort and non-blocking: errors are caught and logged by category, and never block or revert the in-app log, edit or delete.
3. `dp_event_uuid` sample metadata (= `ConsumptionEvent.uuid`) stays the durable identity and the source of truth.
4. `ConsumptionEvent.healthKitUUID` stays a device-local cache only: never synced, never exported.
5. Per-event serial ordering through `runSerial` stays.
6. The delete path stays value-based (`removeSample(healthKitUUID:eventUUID:)`), so the UI can delete the SwiftData event immediately.

## Source-backed decision table

**Availability:** The HealthKit APIs involved (`HKHealthStore.deleteObjects(of:predicate:)`, `HKQuery.predicateForObjects(withMetadataKey:operatorType:value:)` and `HKSampleQueryDescriptor`) are already used by `HealthKitAdapter.swift` and are available at the iOS 27 minimum. No API is replaced or deprecated by this decision.

| Topic | Evidence |
| --- | --- |
| Official source | [HKHealthStore](https://developer.apple.com/documentation/healthkit/hkhealthstore) (deleting objects, `deleteObjects(of:predicate:)`: "An application may only delete objects that it previously saved") and [HKQuery](https://developer.apple.com/documentation/healthkit/hkquery) (`predicateForObjects(withMetadataKey:operatorType:value:)`). Reached through the iPhoneOS 27.2 SDK headers (`HKHealthStore.h`, `HKQuery.h`) because Xcode MCP `DocumentationSearch` was not available to the executing agent; developer.apple.com page text was not re-fetched. No deprecation or replacement is claimed. |
| Proposed behavior | **fix-query-first (recommended):** inside the serialized remove, resolve the current sample by `dp_event_uuid` query first, delete that sample, and fall back to the captured UUID when the query returns nothing or throws. |
| Benefit | The delete targets the sample that exists at the moment the serialized remove runs, so an edit followed by a fast delete no longer leaves an orphan. It uses the metadata source of truth (ADR-0011 decision 2). |
| Cost | `HealthService.swift` only (`performRemoveSample`, plus the `performRemove` call that passes `event.healthKitUUID`). One extra HealthKit query per delete. New regression tests (the pin loses its wrapper) and one UI test. Alternatives cost more: see the options below. |
| Alternatives | **fix-delete-captured-and-queried:** delete the captured UUID and the queried sample. Redundant calls in the common case and more HealthKit traffic, with the same result as fix-query-first. **retain:** accept the orphan risk, keep the known-issue pin as documentation. **defer:** decide later, the pin stays and the defect stays open. |
| Compatibility | No schema, export, sync or API-surface change. The `dp_event_uuid` contract, the device-local cache and its export exclusion, authorization, opt-in and ordering are untouched under every option. |
| Data / accessibility / lifecycle risk | Medium integration/data risk: a delete that misses the current sample leaves health data in a store the user believes was cleaned. A fix must not delete a different event's sample (the query is scoped by `dp_event_uuid`) and must keep the delete non-blocking. Direct accessibility effect: none. |

Flagged assumption A5 (10-RESEARCH.md): real HealthKit deletion of an already-deleted sample UUID is assumed not to throw, so the defect is silent on device. If it throws, the error is logged and swallowed and the orphan outcome is unchanged. The device check D-18 in plan 10-12 observes the real behavior on the owner's iPhone.

### Options with exact scope and cost

| Option id | Exact scope | Cost |
| --- | --- | --- |
| `fix-query-first` (recommended) | In `HealthService.performRemoveSample`, query `store.sampleUUID(forEventUUID:)` first, delete the result, and use the passed `healthKitUUID` only when the query returns nil or throws. Add regression tests in the Health test files and one UI test. No other file changes. | One extra HealthKit query per delete. |
| `fix-delete-captured-and-queried` | Delete the captured UUID, then query by `dp_event_uuid` and delete any different surviving sample. Same file and tests. | Up to two deletes plus one query per delete, redundant in the common case. |
| `retain` | No Health production change. The known-issue pin stays as documentation. | Accepted risk: a deleted drink can persist in Apple Health after a fast edit then delete. |
| `defer` | No Health production change now. The pin stays and the defect stays open. | Same open risk, decided later. |

## Recommendation and proposed scope

Recommend `fix-query-first`: the smallest change that keeps every ADR-0011 invariant and uses the metadata source of truth. Scope: `HealthService.swift` only, applied by plan 10-08 with regression tests (the F2 pin loses its `withKnownIssue` wrapper) and one UI test. Under `retain` or `defer`, plan 10-08 changes no code and the pin stays. No generic HealthKit modernization, actor rewrite or cancellation rewrite is proposed or authorized.

## Owner decision record

**Outcome:** pending
**Decision date:** pending
**Exact scope:** pending
**Owner reason:** pending
