# 0023 — Execution journal

Append-only. Plan frozen 2026-06-28.

---

## 2026-06-28 — Phase A executed (CloudKit OFF), wave by wave

Owner instruction: execute Phase A now, wave after wave; **Phase B parked** — no
paid Apple Developer account, so iCloud/CloudKit cannot be enabled in Xcode.
Executed inline in a single Opus session (not the parallel multi-session model the
plan envisaged) — see deviation note below.

### Step 1 — Freeze `SchemaV1` (snapshot-on-divergence)
- Rewrote `SchemaV1.swift` as a **self-contained namespace** with verbatim copies
  of the pre-0023 models (`SchemaV1.UserProfile/ConsumptionEvent/DrinkTemplate`):
  `name` present, `@Attribute(.unique)` on `id`, no `uuid`/`modifiedDate`, no
  inline defaults beyond what shipped. `versionIdentifier` stays `(1,0,0)`.
- The nested-model pattern (Apple's `TripsV1.Trip` style) is required because the
  live top-level classes become V2; entity names ("UserProfile", …) never collide
  because only one version's models form the active `Schema` (V2 = live classes).

### Step 2 — `UserProfileStore`
- New `Domain/Persistence/UserProfileStore.swift`: `fetchOrCreate` + `deduplicated`
  (keeps the **newest `modifiedDate`**, deletes the rest). Enforces the singleton
  invariant in code now that `.unique` is gone.

### Step 3 — `SchemaV2` (edited live classes)
- `UserProfile`: dropped `.unique`; inline defaults on every attribute; added
  `modifiedDate` (sentinel inline default, `init` sets `.now`); `touch()`.
- `ConsumptionEvent`: **removed `name`**; added `uuid` + `modifiedDate`; `timestamp`
  now a constant inline default (Q4); inline defaults on `volumeMl`/`abv`/`category`
  /`icon`; `touch()`; `duplicated()` now mints a fresh `uuid` (a copy is a distinct
  record).
- `DrinkTemplate`: kept `name` (real field); inline defaults; `uuid` + `modifiedDate`;
  `touch()`.
- `SchemaV2.swift` namespace references the live classes; `versionIdentifier (2,0,0)`.

### Step 4 — Custom V1→V2 migration stage
- `MigrationPlan` now `schemas = [SchemaV1, SchemaV2]`, `stages = [v1ToV2]`.
- `v1ToV2` = `MigrationStage.custom`; `didMigrate` backfills a **distinct** `uuid`
  per event/template and sets `modifiedDate` (events → their `timestamp`; templates
  & profile → `.now`). The schema delta itself (inline defaults / drop-unique /
  remove-`name` / new columns) is lightweight; the custom hook only guarantees the
  per-row distinct identity the inline `UUID()` default can't.

### Step 5 — Export / import (folded in with Step 3, entangled)
- `ExportRecord`: dropped `name`; added optional `uuid` + `modifiedDate`; the old
  `name` key in pre-0023 backups is simply absent from `CodingKeys`, so it is
  ignored on decode (no migration needed).
- `ProfileRecord`: added optional `modifiedDate` (synthesized Codable handles the
  absent key); `apply` sets it.
- New `TemplateRecord` + `ExportBundle.templates` (optional, back-compatible);
  `BackupExport` gained a `templates:` param; `DataSection.startExport` now fetches
  and passes templates.
- `DataImporter`: **upsert by `uuid`** + LWW by `modifiedDate` (newer wins;
  re-import idempotent); uuid-less legacy records fall back to the
  (timestamp/volume/abv/quantity) heuristic; templates imported the same way;
  profile upsert routed through `UserProfileStore.deduplicated`.
- **Deviation from plan Q5 for the profile path:** manual profile import applies
  **unconditionally** (deliberate restore), *not* LWW. `.iso8601` encoding drops
  sub-second precision, so a freshly-encoded backup reads marginally older than an
  in-memory profile and LWW would silently skip the restore. LWW for the singleton
  is kept only in the de-dup **sweep** (keeps newest of true duplicates — the sync
  case). Events keep LWW on import (their stored clock comes from the same
  truncated source, so re-import stays idempotent).

### Step 6 — De-dup sweep + insert-time uniqueness
- New `RecordDeduplicator` (+ `IdentifiedRecord` protocol on the two uuid models):
  `sweep` (events, templates, profiles), generic `dedupe` (newest-`modifiedDate`
  wins), `ensureUniqueIdentity` (regenerate on forced collision).
- Wired: launch sweep in `drinkpulseApp` `RootShellView.onAppear`;
  `ensureUniqueIdentity` after insert in AddDrink `save()` and the History
  context-menu Duplicate.

### Step 7 — Tests
- New: `UserProfileStoreTests`, `RecordDeduplicatorTests`, `DataImporterUpsertTests`
  (idempotent re-import, newer/older LWW, legacy-no-uuid heuristic, template
  round-trip), and a V1→V2 case in `MigrationTests` (seeds an on-disk **V1** store
  via `Schema(versionedSchema: SchemaV1.self)`, reopens through `MigrationPlan`,
  asserts data intact + distinct backfilled uuids + populated `modifiedDate`).
- Existing tests: stripped the `name:` argument from every `ConsumptionEvent(...)`
  in the test targets (scripted, paren-matched, `DrinkTemplate(name:)` untouched);
  removed three `event.name ==` assertions; `duplicated` test now asserts a
  **distinct uuid**.

### Deviations from the plan
- **Single-session, not parallel.** Plan §"Execution parallelization" called for
  multiple simultaneous Opus sessions. Executed inline sequentially instead (owner
  ran one session). Wave boundaries were preserved logically; the build was only
  taken green after the Wave-2 model change (which `UserProfileStore` depends on),
  not at the end of Wave 1.
- **Steps 3 + 5 merged.** The export/import layer does not compile without the
  model change, so they were done together rather than as separate waves.

### Phase-A limitation (deferred, documented)
- **Live Settings profile edits do not yet bump `modifiedDate`** (no single commit
  point; direct `@Bindable` field writes). Create / import / delete-all-reset all
  set it. This only matters once sync is on (two offline-edited profiles), i.e.
  **Phase B** — tighten there (e.g. an `onChange`/`onDisappear` `touch()`).

### Pre-existing (NOT introduced here)
- Two warnings in `UITestSeed.resetTransientDefaults` (nonisolated fn referencing
  main-actor `isActive`/`reminderEnabled`) — from commit `5604699` (2026-06-27),
  predate this plan. Left as-is to avoid touching the reminder-test isolation fix.

### Gates
- `xcodebuild build` (app): **BUILD SUCCEEDED**, zero new warnings (2 pre-existing
  `UITestSeed` warnings noted above).
- Unit suite: **490 tests / 32 suites passed** (`drinkpulseTests`).
- UI tests: all pass. `ExportUITests` were fixed to seed via `-dp_uitest` (see
  note below) so they no longer depend on an ambient real-store profile.
- App coverage: **93.67%** (8272/8831) ≥ 90%.
- No file over the 300-line ceiling (new/changed files checked).

### Test-environment fix (ExportUITests)
Repeated test runs wedged the simulator (`Application failed preflight checks` /
`IOSurface`), so the sim was **erased** to recover. That wiped the real on-disk
store's `UserProfile`; `ExportUITests` launch with `-dp_onboarding_done YES` but
did **not** seed, and `SettingsView` renders only a `ProgressView` when no profile
exists → the Export row never appeared. Root cause was the erased store, **not a
plan-0023 regression** (`SettingsView`'s profile gate is unchanged). Fixed the
latent fragility by adding `-dp_uitest YES` to `ExportUITests.launchApp` (seeds an
in-memory profile + event); the test still drives the real `.fileExporter` save
panel. Also a harness gotcha fixed: the new test helpers must **retain the
`ModelContainer`** (return it, not just `.mainContext`) or the store tears down
mid-test and crashes the suite.

---

## 2026-06-28 (later) — follow-ups: Settings LWW touch, timestamp→consumptionDate, creationDate

Owner-requested, folded into plan-0023 (amends SchemaV2 in place — no store is on
V2 yet, so no SchemaV3 needed; the V1→V2 stage absorbs the changes).

1. **Settings edits now bump `modifiedDate`.** Closes the deferred Phase-A gap.
   `SettingsForm.touching(_:)` binding helper stamps `profile.touch()` on a real
   value change; routed all profile pickers (sex, guideline, unit, alcohol unit,
   ABV precision, currency) + the DOB binding through it.
2. **Renamed `ConsumptionEvent.timestamp` → `consumptionDate`** for clarity, via
   `@Attribute(originalName: "timestamp")` so the existing V1 column maps over with
   no data loss. The backup **wire key stays `"timestamp"`** (ExportRecord
   `CodingKeys.consumptionDate = "timestamp"`) — old backups still import.
3. **Added non-optional `creationDate: Date`.** New inserts seed it from
   `consumptionDate` (`creationDate ?? consumptionDate` in init); the V1→V2 stage
   backfills existing rows from `consumptionDate`. Export/import carry it (optional
   key, back-compat); it's immutable provenance (never overwritten on LWW update).
   Metadata only — no calculation uses it.

Note on creationDate semantics: per the owner's spec it currently **mirrors
consumptionDate** for new events (a drink logged for a past date gets
creationDate = that past date). If a true wall-clock log time is wanted later,
the AddDrink save can pass `creationDate: .now` explicitly — trivial change.

Gates (re-run): app build clean; **490 unit tests pass**; full suite incl. UI
green; **coverage 94.00%**; no file > 300. SchemaV1 snapshot left untouched
(still `timestamp`).

---

## 2026-06-28 (hotfix) — SchemaV3: amend-in-place broke an installed device

**Bug:** the `timestamp`→`consumptionDate` + `creationDate` change was made by
**amending `SchemaV2` in place** (kept version `2.0.0`, changed the shape). The
owner had already installed the first V2 build, so the device store carried the
**shipped-V2 schema hash**. The amended build's `2.0.0` hash no longer matched →
SwiftData: *"Cannot use staged migration with an unknown model version"* →
`StoreBootstrap` non-destructive recovery moved the store to `RecoveredStores/`
and opened an empty one. (No data lost — moved aside.)

**Lesson (now in architecture.md):** never edit a shipped `VersionedSchema` in
place — a shape change must bump the version and freeze the prior shape.

**Fix:**
- Froze the shipped V2 as a self-contained `SchemaV2` snapshot (nested `@Model`
  copies, field `timestamp`, no `creationDate`) — structurally identical to the
  shipped shape so its hash matches migrated stores.
- Moved the new shape to **`SchemaV3`** (`Schema.Version(3,0,0)`, live classes;
  `consumptionDate` via `@Attribute(originalName: "timestamp")`, `creationDate`).
- `MigrationPlan`: `schemas = [V1, V2, V3]`, `stages = [v1ToV2, v2ToV3]`. `v1ToV2`
  now fetches the **`SchemaV2` snapshot types** (its destination), not the live
  classes; `v2ToV3` (custom, final stage → live types) backfills `creationDate`
  from `consumptionDate`.
- New regression test `v2Store_migratesToV3_renamesAndBackfillsCreationDate`
  (seed frozen-V2 on disk → reopen on V3 → data intact, rename mapped, creationDate
  backfilled, no recovery). 491 unit tests pass; build clean.

**Device recovery for the owner:** data is in `RecoveredStores/<timestamp>/`.
Cleanest path on the V3 build: delete + reinstall the app (fresh V3 store), then
re-import the latest backup. (Alternatively the moved-aside `.sqlite` files can be
restored by hand.)

---

## 2026-06-29 — Live-Settings LWW confirmed done; CloudKit flip-point centralized

Owner direction: do **not** enable CloudKit (no paid Apple Developer account /
provisioned container); only make the future flip a clean, single-point switch.

- **`modifiedDate` on live Settings edits — already shipped.** Every editable
  profile field in `SettingsView` binds through `touching(_:)` (which stamps
  `profile.touch()` on a real change) or `dobBinding` (same). Covers sex, DOB,
  guideline, unit system, alcohol unit, ABV precision, currency. This closes the
  Phase-B pre-req TODO ("bump modifiedDate on live Settings edits") — it landed in
  commit `a06eb03` ("Settings LWW touch"); the context docs simply lagged.
- **Flip point centralized.** Extracted `StoreBootstrap.productionConfiguration(schema:)`
  (returns the on-disk config, CloudKit OFF) + `StoreBootstrap.cloudKitContainerID`
  constant (`iCloud.com.drinkpulse.app`). `drinkpulseApp` now calls it instead of
  building `ModelConfiguration` inline. The doc comment spells out the exact 2-step
  one-way flip (iCloud entitlement + `.private(cloudKitContainerID)`). **No
  entitlements file added** on purpose — a CloudKit entitlement with no provisioned
  container breaks code signing. No behaviour change; CloudKit stays OFF.
- **Gates:** app build clean (zero new warnings); full suite green.

**Phase B remains gated** on (a) a provisioned `iCloud.com.drinkpulse.app`
container (paid account) and (b) explicit one-way approval. Plan-0023 stays
`in-progress` until that flip happens — it is the plan's actual deliverable.
