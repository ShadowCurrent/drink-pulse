# ADR-0010 — CloudKit-ready schema: stable identity, LWW, app-level singleton

**Status**: accepted (Phase A of plan-0023)
**Date**: 2026-06-28
**Supersedes / amends**: builds on [ADR-0009](0009-versioned-schema-and-migration-plan.md)
(versioned schema + migration plan).

## Context

plan-0023 enables SwiftData + CloudKit sync. CloudKit imposes hard schema
constraints and removes guarantees the app relied on:

- `@Attribute(.unique)` is unsupported — the `UserProfile` singleton lost its
  database-enforced uniqueness.
- Every attribute must be optional or carry an **inline** default (CloudKit
  materializes records without running `init`).
- CloudKit cannot enforce app-level uniqueness, and sync (or a JSON backup
  restore) can deliver the same logical record twice — there was **no stable
  identity** to de-duplicate against.

Phase A makes the schema CloudKit-ready and safe to restore **without enabling
CloudKit** (no paid Apple Developer account / container yet — Phase B is parked).

## Decision

1. **`SchemaV2`** (on the `SchemaV1` baseline from ADR-0009): drop `.unique`;
   inline defaults on every attribute; remove the deprecated
   `ConsumptionEvent.name`; `timestamp` gets a constant sentinel inline default.
   A **custom V1→V2 migration stage** backfills identity on existing rows.

2. **Stable identity (`uuid: UUID`)** on `ConsumptionEvent` and `DrinkTemplate`
   (NOT `.unique`). App code owns de-dup/upsert by `uuid`. `UserProfile` has no
   `uuid` — its identity is the singleton `id`.

3. **LWW clock (`modifiedDate: Date`)** on all three models. Set on create and on
   every edit (`touch()`). An absolute UTC instant, so `max(modifiedDate)` is
   timezone-correct; single-user multi-device clock skew is accepted (no vector
   clocks).

4. **Conflict resolution = last-write-wins by `modifiedDate`.**
   - **Import (events/templates):** upsert by `uuid`; newer `modifiedDate` wins;
     re-import is idempotent. uuid-less legacy backups fall back to the
     (timestamp, volume, abv, quantity) heuristic.
   - **De-dup sweep** (`RecordDeduplicator`, launch / post-sync): group by `uuid`,
     keep newest, delete the rest — this is what enforces newer-wins across
     devices once sync is on.
   - **Profile manual import = unconditional restore, NOT LWW** (see Consequences).

5. **App-level singleton** for `UserProfile` (`UserProfileStore`): fetch-or-create
   + de-dupe keeping the newest `modifiedDate`, replacing the dropped `.unique`.

## Consequences

- The schema is CloudKit-compatible; Phase B only flips
  `cloudKitDatabase: .private(…)` + entitlements (one-way, separately approved).
- **Profile import is a deliberate restore and applies unconditionally.**
  `.iso8601` export encoding drops sub-second precision, so a freshly-encoded
  backup can read marginally *older* than an in-memory profile; gating the restore
  on LWW would silently skip it. LWW for the singleton is therefore kept only in
  the de-dup sweep (the true-duplicate / sync case). Events keep LWW on import —
  their stored clock comes from the same truncated source, so re-import stays
  idempotent. (Deviation from plan-0023 Q5, recorded in execution.md.)
- **Live Settings profile edits do not yet bump `modifiedDate`** (no single commit
  point; direct `@Bindable` writes). Create / import / delete-all-reset do. Only
  matters once sync is on (two offline-edited profiles) → tighten in Phase B.
- V1 + the custom stage are written to be **retire-able**: once the only real
  device is migrated to V2, they may be collapsed into a clean V2 baseline before
  App Store release (no external users).
