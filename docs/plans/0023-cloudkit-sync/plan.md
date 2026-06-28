# 0023 — CloudKit sync (SwiftData + iCloud)

**Status**: in-progress
**Size**: large
**Created**: 2026-06-03
**Frozen**: 2026-06-28
**Revised**: 2026-06-28 (rebased onto plan-0035; added stable identity + LWW conflict strategy; split into Phase A / Phase B)

## Summary

Enable cross-device sync and cloud backup of DrinkPulse data using SwiftData's
built-in CloudKit integration — no custom backend, per the project's
non-negotiable stack.

Three things make the current schema unfit for CloudKit and for safe
backup-restore once sync is on:
1. `UserProfile` keeps `@Attribute(.unique)` (unsupported with CloudKit), and
   many non-optional fields lack an **inline** schema default (init defaults do
   not count — CloudKit never runs your init).
2. The deprecated `ConsumptionEvent.name` is slated for removal here.
3. There is **no stable record identity**, so restoring a JSON backup while sync
   is active would insert new objects and **duplicate** data. CloudKit cannot
   enforce uniqueness, so identity + de-dup must live in app code.

This plan builds an explicit **`SchemaV2`** on top of the **`SchemaV1` +
`MigrationPlan` foundation already shipped by plan-0035 / ADR-0009**, adds a
stable `uuid` identity and a `modifiedDate` to the syncable models, makes import
idempotent (upsert by `uuid`, newer `modifiedDate` wins), adds a cross-device
de-dup sweep, replaces the unique constraint with an app-level singleton
invariant, and (Phase B) wires up the private CloudKit database + entitlements.

Enabling CloudKit is an **outward-facing, one-way change** (data leaves the
device to iCloud, and the pushed CloudKit schema cannot be changed
destructively). It is gated on explicit per-action approval.

## Context

- Triggered by the 2026-06-03 audit; owner wants iCloud after daily on-device use.
- **Dependency satisfied.** The old "wait for plan-0022 to remove the destructive
  path" framing is obsolete: plan-0022 shipped non-destructive recovery, and
  **plan-0035 / ADR-0009** shipped the migration foundation —
  `SchemaV1` (`VersionedSchema`, `Schema.Version(1,0,0)`) + `MigrationPlan`
  (`SchemaMigrationPlan`, `stages = []`) already wired into
  `StoreBootstrap.makeContainer` and `UITestSeed`. 0023 adds `SchemaV2` + one
  stage; it does not reintroduce versioning or a harness.
- **Snapshot-on-divergence (ADR-0009) — must be step 1.** `SchemaV1.models`
  currently references the live `@Model` classes. 0023 is the first divergence,
  so freeze V1 (copy current model defs into a self-contained `SchemaV1`
  namespace) **before** editing the live classes into V2, or V1 silently
  describes V2 and the migration corrupts.
- **Pre-App-Store, single real store.** The only real data is the owner's device
  (no published users). The V1→V2 migration scaffolding is therefore written to
  be **retire-able before App Store release**: once the device is migrated to V2,
  V1 + the custom stage may be collapsed into a clean V2 baseline. Until then
  the stage stays.
- **Owner device reality (2026-06-28):** device runs an OLDER store, not yet on
  the current schema; owner has a backup. Phase A's V2 build migrates that store
  on first launch; backup + non-destructive `RecoveredStores/` make worst case a
  recovery + re-import.
- **CloudKit container is NOT provisioned yet** (owner). Phase B is blocked on
  provisioning `iCloud.com.drinkpulse.app` (or chosen id) in the Apple Developer
  account. Phase A does not need it.
- SwiftData + CloudKit constraints: no `@Attribute(.unique)`; every attribute
  optional or with an **inline** default; relationships optional + inverse
  (already satisfied: `ConsumptionEvent.template` optional; `DrinkTemplate.events`
  inverse + `[]`, `.nullify`).

## Resolved decisions (owner sign-off 2026-06-28)

- **Q1 — Scope/approval:** build Phase A now (SchemaV2 + identity + migration +
  de-dup, **CloudKit OFF**); hold Phase B (enable CloudKit) for a separate
  explicit approval after on-device migration is verified.
- **Q2 — Container:** `iCloud.com.drinkpulse.app` not provisioned yet → Phase B
  blocked until set up; Phase A unaffected.
- **Q3 — Migration stage:** **custom** V1→V2 stage (required for the per-row
  `uuid`/`modifiedDate` backfill); same stage also adds inline defaults, drops
  `.unique`, and removes `name`. Written to be retire-able pre-launch.
- **Q4 — timestamp:** non-optional, inline **constant** default
  `Date(timeIntervalSince1970: 0)` (sentinel; init still sets `.now` on insert,
  existing rows keep their real timestamps).
- **Identity (uuid):** add `uuid: UUID = UUID()` to **`ConsumptionEvent` and
  `DrinkTemplate`** (NOT `.unique`). New objects auto-get one; a creation-time
  uniqueness check scans the local store and regenerates on the (astronomically
  unlikely) collision. Importer upserts by `uuid`; exporter emits it.
- **modifiedDate:** add `modifiedDate: Date` to **all three** `@Model` types
  (`UserProfile`, `ConsumptionEvent`, `DrinkTemplate` — the complete stored set);
  set to `.now` on create and on every edit. Drives newer-wins conflict
  resolution everywhere, incl. the `UserProfile` singleton (which has no `uuid` —
  its identity is the singleton `id`). `Date` is an absolute instant (UTC-based),
  so `max(modifiedDate)` is timezone-correct by construction; no timezone field
  is needed. Caveat: LWW trusts each device's clock — acceptable skew for a
  single user's own devices (no vector clocks).
- **Q5 — Conflict resolution:** LWW by `modifiedDate`. On import, same `uuid` →
  keep the newer `modifiedDate`. For live CloudKit sync, SwiftData's built-in
  per-field LWW applies; `modifiedDate` also feeds the de-dup sweep. The
  `UserProfile` singleton de-dup keeps the **newest** `modifiedDate` (not the
  earliest), so an offline profile edit is never lost to an older copy.
- **De-dup sweep:** in scope. A launch / post-sync sweep groups by `uuid`, keeps
  the newest `modifiedDate`, deletes the rest (both models) — this is what
  enforces newer-wins across devices (app-level `uuid` ≠ CloudKit record id, so
  the same logical record can arrive twice via sync).
- **Q6 — Defaults:** approved harmless inline defaults (numerics `0`, strings
  `""`, enums first/sensible case, Bool `false`).
- **Q7 — Sync UX:** show a lightweight "Syncing with iCloud…" status (Settings)
  — built in Phase B (needs sync signals).

## CloudKit-incompatibility inventory (verified 2026-06-28)

Fields needing a **new inline default** (non-optional, no inline default today):

- **UserProfile:** `bodyWeightKg`, `biologicalSex`, `guidelineChoice`,
  `weeklyGoalGrams`, `unitSystem`, `currency`. Drop `@Attribute(.unique)` on `id`
  (keeps its inline `"singleton"`). Already safe: `dateOfBirth` (optional),
  `abvPrecisionPermille` (`= 5`), `alcoholUnit` (`= .standardDrinks`). **New:**
  `modifiedDate` (no `uuid` — singleton identity is `id`).
- **ConsumptionEvent:** `volumeMl`, `abv`, `category`, `icon`, and `timestamp`
  (constant-default special case, Q4). **Remove** `name`. Already safe:
  `quantity` (`= 1`), optionals `enteredUnit`/`customName`/`notes`/`price`/
  `priceCurrency`, relationship `template`. **New:** `uuid`, `modifiedDate`.
- **DrinkTemplate:** `name`, `category`, `defaultVolumeMl`, `abv`, `icon`,
  `colorHex`, `isFavorite`, `isArchived`. Already safe: `events` (`= []`).
  **New:** `uuid`, `modifiedDate`.

## Scope

### In — Phase A (local; buildable now, CloudKit OFF)
- Freeze `SchemaV1` (self-contained snapshot).
- `SchemaV2` models: drop `.unique`; inline defaults per inventory; `timestamp`
  constant default; **remove `name`**; add `uuid: UUID = UUID()` to
  `ConsumptionEvent` + `DrinkTemplate`; add `modifiedDate: Date` to **all three**
  models (incl. `UserProfile`).
- Custom `MigrationStage` (V1→V2): backfill a **distinct** `uuid` per existing
  `ConsumptionEvent`/`DrinkTemplate` row and set `modifiedDate` on all three
  (events → their `timestamp`; templates & profile → `.now`); apply defaults /
  drop-unique / remove-`name`. Structured to be retire-able pre-launch
  (isolated, documented).
- `modifiedDate` maintenance: set `.now` on create and in every edit path
  (Add, Edit, duplicate, context-menu mutations).
- Creation-time `uuid` uniqueness: a small helper that, on insert, checks the
  local store for a collision and regenerates (belt-and-suspenders).
- Importer: **upsert by `uuid`** (same `uuid` → keep newer `modifiedDate`, else
  insert); tolerate old backups (no `uuid` → fall back to the existing
  heuristic; no `modifiedDate` → treat as oldest). Stop mapping the removed
  `name`; keep decoding it from old backups and ignore it.
- Exporter: emit `uuid` + `modifiedDate` (optional decode, back-compatible).
  Add `DrinkTemplate` to export/import (currently events + profile only).
- Cross-device de-dup sweep: launch / post-sync, group by `uuid`, keep newest
  `modifiedDate`, delete the rest (both models).
- App-level singleton enforcement for `UserProfile` (`UserProfileStore`:
  fetch-or-create + de-dupe keeping the **newest `modifiedDate`**; route
  `profiles.first` call sites through it).
- Extend the existing `MigrationTests` harness with the V1→V2 case; add upsert /
  LWW / sweep tests; old-`name` backup round-trip.

### In — Phase B (gated: container provisioned + explicit CloudKit-enable approval)
- Entitlements & capabilities: iCloud (CloudKit) + container id, push
  entitlement, "Remote notifications" background mode.
- Enable CloudKit: `cloudKitDatabase: .private(…)` in `StoreBootstrap`
  (one-way switch). Validate schema initialization against the dev CloudKit env.
- "Syncing with iCloud…" status row in Settings (Q7).
- Wire the de-dup sweep to a post-sync trigger.
- Finalize ADR-0010 + README/docs (sync on).

### Out
- Custom CloudKit schema / CKRecord-level code, sharing, public database.
- Conflict-resolution UI / field-merge screens (LWW only).
- Apple Watch / widget targets.
- DrinkControl import work (already handled).
- Reintroducing versioning/harness scaffolding (done in plan-0035).

## Implementation steps

Ordered; each ≈ one commit. **Phase A first; do not start Phase B without
container provisioning + explicit approval.**

1. **Freeze `SchemaV1`** (snapshot-on-divergence) — self-contained V1; harness
   stays green.
2. **`UserProfileStore`** (no schema change) — fetch-or-create + de-dupe; route
   `profiles.first` call sites; tests.
3. **`SchemaV2` models** — drop `.unique`; inline defaults; `timestamp` constant
   default; remove `name` (fix init/`duplicated`/previews); add `uuid` to the two
   non-singleton models + `modifiedDate` to all three; creation-time `uuid`
   uniqueness helper; `modifiedDate` set on create + all edit paths.
4. **Custom `MigrationStage` V1→V2** — append to `MigrationPlan`
   (`schemas = [SchemaV1, SchemaV2]`); `didMigrate` backfills distinct `uuid` +
   `modifiedDate`; verify defaults / drop-unique / remove-`name`. Keep isolated
   for pre-launch retirement.
5. **Export/import** — emit + decode `uuid`/`modifiedDate` (back-compatible);
   importer upsert-by-`uuid` + LWW-by-`modifiedDate`; tolerate/ignore old
   `name`; add `DrinkTemplate` to the bundle.
6. **De-dup sweep** — `uuid`-grouped, newest-`modifiedDate` wins (both models);
   unit-tested; trigger on launch (Phase A) and post-sync (Phase B).
7. **Harness + tests** — extend `MigrationTests` (V1→V2: data intact, distinct
   uuids, `name` gone, no recovery); upsert/LWW/sweep tests; old-backup
   round-trip.
8. **Owner on-device migration verification (gate to Phase B)** — owner exports
   a fresh backup; installs the V2 build (CloudKit OFF); confirms the device's
   old store migrates with data intact and `RecoveredStores/` did not fire;
   re-export a uuid-stamped backup. Fallback: restore backup + re-import.
9. **(Phase B) Entitlements + enable CloudKit** — provision container; add
   capabilities; set `cloudKitDatabase: .private(…)`; validate dev schema. One-
   way, approval-gated.
10. **(Phase B) Syncing indicator + post-sync sweep wiring.**
11. **Living docs + ADR-0010** — architecture.md (sync + conflict + identity),
    domain.md (defaults, no unique, `name` removed, `uuid`/`modifiedDate`,
    singleton in code), README (sync on), roadmap, context. Coverage + file-size
    gates.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift` | Modify — freeze self-contained snapshot |
| `drinkpulse/Domain/Persistence/Schemas/SchemaV2.swift` | Create — CloudKit-ready models |
| `drinkpulse/Domain/Persistence/MigrationPlan.swift` | Modify — add SchemaV2 + custom V1→V2 stage |
| `drinkpulse/Domain/UserProfile.swift` | Modify — drop `.unique`, inline defaults, add `modifiedDate` |
| `drinkpulse/Domain/ConsumptionEvent.swift` | Modify — defaults, timestamp, remove `name`, add `uuid`/`modifiedDate` |
| `drinkpulse/Domain/DrinkTemplate.swift` | Modify — defaults, add `uuid`/`modifiedDate` |
| `drinkpulse/Domain/Persistence/UserProfileStore.swift` | Create — fetch-or-create + de-dupe |
| `drinkpulse/Domain/Persistence/RecordDeduplicator.swift` | Create — uuid sweep (newest modifiedDate wins) |
| `drinkpulse/Domain/DataTransfer/ExportRecord.swift` | Modify — emit/decode uuid+modifiedDate; tolerate old `name` |
| `drinkpulse/Domain/DataTransfer/ExportBundle.swift` | Modify — add templates |
| `drinkpulse/Domain/DataTransfer/DataImporter.swift` | Modify — upsert by uuid, LWW by modifiedDate |
| Edit paths (Add/Edit/duplicate/context-menu) | Modify — set `modifiedDate` |
| `drinkpulse/Domain/Persistence/StoreBootstrap.swift` | Modify (Phase B) — CloudKit config only |
| `drinkpulse/drinkpulse.entitlements` (+ capabilities) | Modify (Phase B) — iCloud/CloudKit/push/background |
| Settings sync-status UI | Create (Phase B) — "Syncing…" row |
| Call sites using `profiles.first` | Modify — route via `UserProfileStore` |
| Call sites using `ConsumptionEvent.name` | Modify — drop usage |
| `docs/decisions/0010-enable-cloudkit-sync.md` | Create — ADR |
| `drinkpulseTests/Domain/Persistence/UserProfileStoreTests.swift` | Create |
| `drinkpulseTests/Domain/Persistence/RecordDeduplicatorTests.swift` | Create |
| `drinkpulseTests/Domain/Persistence/MigrationTests.swift` | Modify — V1→V2 case |
| `drinkpulseTests/Domain/DataTransfer/…` | Modify — upsert/LWW + old-`name` round-trip |

## Open questions

Remaining (others resolved above):

- [ ] **Phase B approval** to enable CloudKit (one-way) — required before step 9.
- [ ] **Container provisioning** — set up `iCloud.com.drinkpulse.app` (or final
      id) in the Apple Developer account before Phase B.
- [ ] **Pre-launch baseline** — after the device is on V2, decide whether to
      collapse V1 + the custom stage into a clean V2 baseline before App Store
      submission (no external users, so safe). Default: do it at release prep.

## Tests required

- **UserProfileStore**: fetch-or-create idempotent; two profiles collapse to one
  (**newest `modifiedDate` kept**, older deleted — an offline edit isn't lost);
  call sites see exactly one.
- **Migration (V1→V2)**: seeded V1 store (incl. a `name`-bearing event + a
  profile) migrates with data intact, **distinct** uuids assigned, `modifiedDate`
  populated, `name` dropped, exactly one profile, no `RecoveredStores/` fallback.
- **Import upsert / LWW**: re-importing the same (uuid-stamped) backup is
  idempotent (no duplicates); on `uuid` conflict the newer `modifiedDate` wins;
  old backup without uuid falls back to the heuristic and without `modifiedDate`
  is treated as oldest.
- **De-dup sweep**: two objects with the same `uuid` collapse to the newest
  `modifiedDate` (both models); distinct uuids untouched.
- **uuid uniqueness helper**: a forced collision regenerates.
- **Defaults**: initializers still produce equivalent objects.
- **Old-`name` backup round-trip**: a version-2 backup containing `name` imports
  cleanly after removal (name tolerated/ignored; all other fields round-trip).
- Note: real CloudKit round-trip / multi-device sync is an integration concern
  validated on-device against the dev iCloud env (steps 8–10), not in unit tests.

## Execution parallelization

Executed via **multiple Opus 4.8 sessions, simultaneous where meaningful**
(owner instruction — overrides the usual Opus-plans/Sonnet-executes default for
this plan), reviewed in the orchestrating session after each step/wave. Parallel
only where file-sets do not overlap; one builder builds/tests at a time to avoid
DerivedData/codesign contention.

**Phase A waves:**
- **Wave 1 (parallel):** Step 1 freeze `SchemaV1` ‖ Step 2 `UserProfileStore`
  (independent file-sets — V1 snapshot vs the store helper + `profiles.first`
  call sites).
- **Wave 2 (sequential):** Step 3 `SchemaV2` models (the new fields `uuid` /
  `modifiedDate`, defaults, `name` removal) — this is the critical-path
  bottleneck everything else depends on; do it alone, review, build green.
- **Wave 3 (parallel, all depend on Wave 2's fields, disjoint files):** Step 4
  custom `MigrationStage` (`MigrationPlan.swift`) ‖ Step 5 export/import
  (`DataTransfer/`) ‖ Step 6 de-dup sweep (`RecordDeduplicator.swift`) ‖
  `UserProfileStore` newest-wins refinement.
- **Wave 4 (sequential):** Step 7 — full test run (whole-project compile +
  coverage gate); the harness V1→V2 case + upsert/LWW/sweep/round-trip tests.
- **Step 8** is the owner's on-device verification (manual gate to Phase B).

**Phase B** is sequential and gated (container provisioning + explicit
CloudKit-enable approval): entitlements → enable `cloudKitDatabase` → syncing
indicator + post-sync sweep wiring → ADR-0010 + living docs.
