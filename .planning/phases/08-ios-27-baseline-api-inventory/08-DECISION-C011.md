# C011 — HealthKit concurrency, identity, and serial execution

**Status:** owner-approved eligibility recorded — modernization not started
**Proposed destination:** Phase 10

## Current behavior

`drinkpulse/Services/HealthKitAdapter.swift:4-60`, `HealthService.swift:4-155`, `HealthWriteHooks.swift:4-36`, `HealthWriting.swift:3-25`, `UITestHealthStore.swift:3-28`, and `HealthServiceEnvironment.swift:1-5` implement the boundary. `@MainActor` service state and `runSerial(_:_:)` preserve per-event write/update/delete ordering. ADR-0011 fixes opt-in/non-blocking behavior, `dp_event_uuid` deduplication, and device-local `healthKitUUID` cache semantics.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official source below; no replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [HKHealthStore](https://developer.apple.com/documentation/healthkit/hkhealthstore) and [Swift data-race safety guidance](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/dataracesafety/) (checked 2026-09-16). No deprecation/replacement is claimed. |
| Proposed behavior | Retain until observed interrupted/parallel-operation proof supports a precise actor/sendability or task-lifetime change. |
| Benefit | A proven correction could address a real race; none is reproduced. |
| Cost | High: authorization, write/update/delete/backfill/dedup, parallel ordering, and device behavior regression evidence. |
| Alternatives | **Retain** the existing adapter boundary and per-event serial execution. |
| Compatibility | Existing HealthKit API surface is supported at the iOS 27 minimum. |
| Data / accessibility / lifecycle risk | High integration/lifecycle/data risk: changes can affect permissions, non-blocking delete, durable metadata identity, cache locality, or duplicate samples. Direct accessibility effect is none. |

## Recommendation and proposed scope

Recommend retain pending proof. Any later owner-approved scope must preserve all ADR-0011 invariants and prove interrupted/parallel cases; no generic HealthKit modernization is authorized.

## Owner decision record

**Outcome:** approve
**Decision date:** 2026-09-16
**Exact scope:** Audyt współbieżności HealthKit i tylko punktowe poprawki tam, gdzie diagnostyka udowodni problem; zachować opt-in, nieblokowanie, `dp_event_uuid`, lokalny cache i kolejność usuwania, bez szerokiego przepisywania aktorów albo anulowania.
**Owner reason:** Modernizacja ma być ostrożna, oparta na mierzalnych problemach i testach regresji; bez szerokich przebudów ani zmian danych/formatów bez celu biznesowego.
**Owner response:** `zatwierdzam wszystkie C001–C012 z tym powodem, jednak nie zaczynaj modernizacji, jedynie zapisz stan tak abym po wyczyszczeniu kontekstu mogl go wznowic jutro`

No modernization has started. Only a diagnosed Phase 10 issue preserving every ADR-0011 invariant is eligible; no broad actor or cancellation rewrite is authorized.
