# 0036 — Apple Health write-back (dietaryAlcohol)

**Status**: completed
**Size**: medium-large
**Created**: 2026-06-29
**Frozen**: 2026-06-29
**Completed**: 2026-06-29

## Summary

Opt-in, **write-only** integration that mirrors logged drinks into Apple
Health as `HKQuantityTypeIdentifier.dietaryAlcohol` samples (grams of pure
alcohol). When enabled:

- New `ConsumptionEvent`s write a Health sample; edits rewrite it; deletes
  remove it. Identity is tracked by a stored `healthKitUUID` on the event.
- On first enable the user is **asked whether to also add past drinks**
  (backfill) — otherwise only events going forward are mirrored.
- Health writes are **best-effort and never block** logging/editing/deleting;
  failures are logged by category only (no PII) and surfaced passively.

Read-back from Health is **out of scope** (roadmap is write-back only).

## Context

Roadmap item (`docs/roadmap.md`): "Apple Health write-back
(HKQuantityTypeIdentifierDietaryAlcohol, grams) — deduplication via stored
HealthKit UUID on ConsumptionEvent; edits/deletes in app reflected in Health."

Open-questions.md ("Apple Health integration: deduplication model") is the
design seed: add `healthKitUUID: UUID?`, store the sample UUID on write,
delete-by-UUID on edit/delete, with an open sub-question on revoked
permission — resolved here (see Decisions).

`dietaryAlcohol` is a writable HK quantity type measured in grams. We write
`ConsumptionEvent.pureAlcoholGrams` (physical density 0.789 — unconditional,
matches calories/BAC), so **no calculation changes** and nothing in the
Domain calc module is touched.

### New `Services/` member

`HealthService` joins `Services/` alongside `ReminderService`, following the
same shape (ADR-0008): a `@MainActor` type mediating a platform capability
behind a `Sendable` protocol so it is unit-testable without HealthKit. No new
architectural layer — this is an additive member; `architecture.md` Services
section gets a one-line mention.

## Scope

### In

- **Schema (additive, requires a new version).**
  - Freeze the current live shape as a self-contained `SchemaV4` snapshot? No —
    current live = `SchemaV3`. Adding a stored property changes the `@Model`
    shape, so per CLAUDE.md the **previous shape is frozen and the live classes
    become `SchemaV4`**:
    - Freeze `SchemaV3` as a self-contained snapshot (nested `@Model` copies,
      no `healthKitUUID`) — already a file (`Schemas/SchemaV3.swift`); confirm
      it is snapshot-shaped (own nested classes), not aliasing live classes.
    - Add `SchemaV4` (`Schema.Version(4,0,0)`, live classes) with
      `var healthKitUUID: UUID?` on `ConsumptionEvent`.
    - `MigrationPlan`: `schemas += SchemaV4`, add a **lightweight** `v3ToV4`
      stage (new optional property, default nil — no custom willMigrate needed;
      use `.lightweight` if SwiftData infers it, else a no-op custom stage).
  - `healthKitUUID` is **device-local advisory** data (HK samples are
    per-device). See Decisions for the CloudKit (Phase B) interaction.

- **`Services/HealthWriting.swift`** — protocol abstracting the slice of
  `HKHealthStore` used, so `HealthService` is testable without HealthKit:

  ```swift
  protocol HealthWriting: Sendable {
      var isHealthDataAvailable: Bool { get }
      func requestAuthorization() async throws -> Bool
      func authorizationStatus() -> HealthAuthStatus   // notDetermined/denied/authorized
      func save(grams: Double, date: Date) async throws -> UUID
      func delete(uuid: UUID) async throws
  }
  ```

- **`Services/HealthService.swift`** (`@MainActor`) — injected `HealthWriting`;
  `requestAuthorization()`, `write(event:)` (returns/stores `healthKitUUID`),
  `update(event:)` (delete old UUID + write new), `remove(event:)` (delete by
  UUID, clear field), `backfill(events:)` (batched best-effort). All paths are
  best-effort: catch, log category, never throw to the caller's UI flow.

- **`Services/HealthKitAdapter.swift`** — thin real `HKHealthStore`
  conformance of `HealthWriting` (excluded from coverage as a framework
  adapter).

- **`Services/UITestHealthStore.swift`** — launch-arg-gated non-prompting stub
  (mirrors `UITestNotificationCenter`) so UI tests never hit real Health.

- **Settings UI** — new `HealthSection` glass card (toggle + state):
  off by default; toggling on → authorization request; on first-ever enable →
  confirmation dialog "Also add your past drinks to Health?" (backfill choice);
  denied → inline message + Open Settings deep link (reuse the Reminders
  pattern). Persisted flag `dp_health_write_enabled` (AppStorageKeys).

- **Write hooks** — Add Drink save, Edit save, and the History delete/context-
  menu delete call `HealthService` when enabled. Hooks are fire-and-forget
  (`Task { await … }`) so the UI never waits on Health.

- **Entitlement & Info.plist** — HealthKit capability; `NSHealthUpdateUsageDescription`
  (and `NSHealthShareUsageDescription` only if required by the API surface).
  English usage strings.

- **Tests**
  - `HealthServiceTests` (≥85%): authorized/denied/unavailable; write stores
    UUID; update deletes-then-writes; remove deletes + clears; backfill batches;
    every error path is swallowed (no throw) and the event still saves —
    exercised through a `HealthWriting` fake.
  - `MigrationTests` addition: seed a V3 store on disk → reopen on V4 → data
    intact, `healthKitUUID == nil`, no recovery.
  - `ComprehensiveRoundTripTests`: `healthKitUUID` is **not** exported (device-
    local) — assert export/import ignores it and round-trips unchanged.
  - UI test `HealthSettingsUITests`: toggle reveals/hides state via the
    `UITestHealthStore` stub (no real permission prompt); backfill dialog
    appears on first enable.

### Out
- Reading alcohol data **from** Health into the app.
- Writing anything other than `dietaryAlcohol` (no calories/water/etc.).
- Syncing `healthKitUUID` across devices (it is device-local; see Decisions).
- Retroactive re-sync UI beyond the one-time enable backfill prompt.

## Decisions (owner-confirmed 2026-06-29)

1. **Backfill = ask at enable.** First enable shows a confirmation dialog; user
   picks backfill-all vs new-events-only.
2. **Error model = best-effort, non-blocking.** A Health failure (denied,
   revoked, write error) never blocks or rolls back the in-app log/edit/delete.
   Failures `log.error` by category (no PII), no user-facing alert beyond the
   Settings authorization state. Resolves the open sub-question on revoked
   permission: a delete that fails silently is acceptable — the in-app source
   of truth is unchanged, and the stale field is harmless.
3. **Grams written = `pureAlcoholGrams` (0.789).** No calc change; consistent
   with calories/BAC. Quantity is the per-event total (volume × quantity).
4. **`healthKitUUID` is device-local, not exported, not synced.** HK samples
   live on one device. Excluded from the export bundle. **CloudKit Phase B
   caveat (deferred, CloudKit is OFF):** when sync is on, an event synced from
   another device may carry a `healthKitUUID` that names no local sample; the
   write path must treat "no local sample for this UUID" as "write fresh" and
   restamp. Documented now, implemented when Phase B lands.
5. **Schema = new `SchemaV4` + v3→v4 stage** (never amend V3). Additive
   optional `healthKitUUID: UUID?`, default nil.

## Risks
- **HealthKit entitlement / signing.** Adding the HealthKit capability is
  required for the API to work on device. Simulator + UI tests work without a
  paid account; **device install/distribution needs the capability provisioned**
  (free dev provisioning generally allows HealthKit for development, unlike the
  CloudKit container). Flag to owner; does not block simulator development.
- **Async fire-and-forget ordering.** Rapid edit→delete could race two Health
  ops on the same event. Serialize per-event ops in `HealthService` (await the
  prior op or key by `event.persistentModelID`).

## Steps (high level)
0. **Create `ADR-0011` — Health write-back & device-local sample identity**
   (owner-confirmed: new ADR, not a note in 0008). Captures: write-only scope,
   grams = `pureAlcoholGrams` (0.789), device-local `healthKitUUID` (never
   synced/exported), best-effort non-blocking error model, and the CloudKit
   Phase-B "foreign/absent id → write fresh" caveat.
1. Schema: freeze V3 snapshot (verify shape), add SchemaV4 + v3→v4 stage + test.
2. `HealthWriting` protocol + `HealthKitAdapter` + `UITestHealthStore`.
3. `HealthService` + unit tests (fake-driven, all error paths).
4. Settings `HealthSection` + persisted flag + backfill dialog.
5. Wire write/update/remove hooks into Add/Edit/Delete (fire-and-forget).
6. Entitlement + Info.plist usage strings.
7. UI test; full-suite + coverage; living docs (architecture/domain/roadmap/
   product) + DEVLOG + INDEX + context files.

## Acceptance
- Toggling on (authorized) and logging a drink creates a `dietaryAlcohol`
  sample of the right grams; editing rewrites it; deleting removes it.
- Backfill prompt appears on first enable and writes history when accepted.
- Denied/revoked permission never blocks logging; app stays usable.
- Build clean (0 warnings), full suite green, Services ≥85% / overall ≥90%,
  no file > 300, no calc-module change.
