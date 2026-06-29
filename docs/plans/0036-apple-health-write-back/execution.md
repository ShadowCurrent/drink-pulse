# 0036 — Execution journal

Append-only. Frozen plan: `plan.md` (2026-06-29). Executed by **separate Opus
session(s)** (owner direction); parallelize independent waves where useful.

---

## 2026-06-29 — Handoff (planning session, no feature code)

Plan frozen, decisions locked. No production code written in this session — only
plan/docs/CLAUDE.md. The CLAUDE.md forward-compat rule (CloudKit + HealthKit)
added this session governs every step below.

### Confirmed decisions (owner)
1. Backfill = **ask at enable** (dialog: all-history vs new-only).
2. Error model = **best-effort, non-blocking** — Health failure never blocks or
   rolls back the in-app log/edit/delete; `log.error` by category, no PII, no
   alert beyond Settings auth state. Resolves the revoked-permission sub-question.
3. `healthKitUUID` = **device-local** — NOT synced (CloudKit), NOT exported;
   foreign/absent id → "write fresh".
4. **New ADR-0011** (device-local Health sample identity) — not a note in 0008.
5. Grams written = `ConsumptionEvent.pureAlcoholGrams` (0.789). No calc change.
6. Schema = **new SchemaV4 + v3→v4 stage** (never amend V3) — additive optional
   `healthKitUUID: UUID?`, default nil.

### Wave plan + dependencies (for one or many sessions)

**Critical path is mostly sequential — W1 then W3→W4→W5.** W2 and W6 are
independent and safe to run in a *parallel* session if desired.

- **W1 — Schema (foundation, BLOCKS W3/W5).**
  - Verify `Schemas/SchemaV3.swift` is a self-contained snapshot (own nested
    `@Model` copies), not aliasing live classes; if it aliases, freeze it first.
  - Add live `ConsumptionEvent.healthKitUUID: UUID?` (default nil).
  - Add `Schemas/SchemaV4.swift` (`Schema.Version(4,0,0)`, live classes).
  - `MigrationPlan`: `schemas += SchemaV4`; add `v3ToV4` (lightweight if SwiftData
    infers the optional add; else a no-op custom stage destination = live types).
  - Tests: `MigrationTests` v3→v4 (seed V3 on disk → reopen V4 → data intact,
    `healthKitUUID == nil`, no recovery). `ComprehensiveRoundTripTests`: assert
    `healthKitUUID` is NOT in the export bundle and round-trips unchanged (nil).
  - **Touches:** `Domain/ConsumptionEvent.swift`, `Schemas/`, `MigrationPlan.swift`,
    test files. ⚠ Conflicts with any other schema work — single owner.

- **W2 — Platform protocol + adapters (PARALLEL-SAFE, new files only).**
  - `Services/HealthWriting.swift` (protocol per plan), `HealthAuthStatus` enum.
  - `Services/HealthKitAdapter.swift` (real `HKHealthStore`; coverage-excluded).
  - `Services/UITestHealthStore.swift` (launch-arg-gated non-prompting stub).
  - No dependency on W1 (operates on grams + UUID, not the model). Can start
    immediately in a parallel session.

- **W3 — HealthService (needs W2; field from W1 only for the hooks, not the
  service API).**
  - `Services/HealthService.swift` (`@MainActor`, injected `HealthWriting`):
    requestAuthorization / write / update (delete-old+write) / remove / backfill.
    All best-effort (catch, log category, never throw to UI). Serialize per-event
    ops (key by `persistentModelID`) to avoid edit→delete races.
  - `HealthServiceTests` (≥85%): authorized/denied/unavailable; write stores UUID;
    update deletes-then-writes; remove clears; backfill batches; every error path
    swallowed + event still saved — via a `HealthWriting` fake.

- **W4 — Settings UI (needs W3).**
  - `HealthSection` glass card (toggle + state) in `SettingsView`; persisted
    `dp_health_write_enabled` (AppStorageKeys); first-enable backfill dialog;
    denied → inline message + Open Settings (reuse Reminders pattern).

- **W5 — Wire hooks (needs W1 + W3).**
  - Add Drink save, Edit save, History/context-menu delete call HealthService
    when enabled, fire-and-forget (`Task { await … }`) — UI never waits.

- **W6 — Entitlement + Info.plist (PARALLEL-SAFE).**
  - HealthKit capability; `NSHealthUpdateUsageDescription` (+ Share string only
    if the API surface needs it). English strings. Flag device-vs-simulator to
    owner (simulator/UI tests need no paid account).

- **W7 — Close-out (last, single session).**
  - `ADR-0011`; `HealthSettingsUITests` (toggle + backfill dialog via the stub);
    full suite + coverage (Services ≥85%, overall ≥90%); no file > 300; living
    docs (architecture Services note, domain Health-write note, roadmap 🗓→✅,
    product if scope text changes); DEVLOG; INDEX status; context files.

### Coordination notes for parallel sessions
- Single-owner files (do NOT touch from two sessions): `MigrationPlan.swift`,
  `ConsumptionEvent.swift`, `SettingsView.swift`, `drinkpulseApp.swift`,
  `AppStorageKeys`, `Localizable.xcstrings`, all living docs + this file.
- W2 and W6 are the only cleanly-parallel waves (new files / project settings).
  Everything else shares the model or Settings and should serialize.
- Each executing session: append a dated entry below with what landed + gates.

### Gates (every session, before declaring its wave done)
Build clean (0 warnings) · suite green · no file > 300 · no calc-module change ·
no PII in logs · no new network. Final wave: coverage report + UI test ran.

---

## 2026-06-29 — Discovery (pre-execution): app-deletion + dual-sync duplication risk

Owner raised: does deleting the app remove the Health data, and is sync handled?

**Findings:**
1. **App deletion does NOT delete HealthKit samples.** iOS leaves `dietaryAlcohol`
   samples in the Health store, attributed to the removed app; only the user can
   delete them (Health app → Apps → DrinkPulse → Delete All Data). Meanwhile OUR
   SwiftData store — including every `healthKitUUID` — IS wiped with the app, so
   after delete+reinstall (or backup restore, which excludes `healthKitUUID`) the
   app cannot match its prior samples → orphaned.
2. **Two independent syncs.** Apple Health has its OWN iCloud sync (separate from
   our CloudKit) that propagates our samples to the user's other devices. Combined
   with the plan's "device-local UUID → write fresh" rule, this DUPLICATES samples
   in two scenarios: (a) reinstall/restore + backfill; (b) Phase-B multi-device —
   device B holds the CloudKit-synced event without a `healthKitUUID`, writes a
   fresh sample, while Health already synced device A's original.

**Implication for the frozen plan:** decisions 3 ("write fresh") + 4 (new ADR) are
incomplete — "write fresh" alone causes duplicates. Plan.md is frozen; the dedup
design correction is recorded here and folded into ADR-0011.

**Recommended correction (pending owner decision below):** stamp each HKSample's
`metadata["dp_event_uuid"] = ConsumptionEvent.uuid` (our stable, synced, backup-
preserved identity) and **dedup-on-write**: before write/backfill, query Health for
a sample carrying that uuid; relink locally if found instead of writing. Fixes both
reinstall and multi-device. Requires **read** authorization for `dietaryAlcohol`
(integration becomes read+write, not strictly write-only) — scope change for owner
to confirm. `healthKitUUID` stays device-local (a fast local cache); `dp_event_uuid`
metadata is the durable cross-device/reinstall key.

### Resolution (owner, 2026-06-29): metadata uuid + read-for-dedup

Adopt the recommended correction. This **amends the frozen plan** (recorded here,
not in plan.md) and MUST be reflected in ADR-0011 and the executing waves:

- **Identity:** every HKSample we write carries `metadata["dp_event_uuid"] =
  ConsumptionEvent.uuid.uuidString` (stable, synced, backup-preserved). The local
  `healthKitUUID` stays a device-local fast cache; `dp_event_uuid` is the durable
  cross-device/reinstall key.
- **Scope is now READ + WRITE** (no longer strictly write-only). Authorization
  requests **share(read) + update(write)** for `dietaryAlcohol`.
- **Dedup-on-write:** before any write/backfill, query Health for a sample whose
  `dp_event_uuid` == event.uuid (`HKQuery.predicateForObjects(withMetadataKey:operatorType:value:)`
  or a sample query filtered to our source). If found → relink (`healthKitUUID =
  found.uuid`), do NOT write a duplicate. If absent → write fresh + stamp metadata.
- **Reinstall/restore:** on first enable after a reinstall, the dedup query makes
  backfill idempotent — existing samples are relinked, not re-added.
- **Phase-B multi-device:** device B (event via CloudKit, no local `healthKitUUID`)
  finds device A's Health-synced sample by `dp_event_uuid` → relinks, no duplicate.

**Wave deltas (apply during execution):**
- **W2 (`HealthWriting`):** add read capability — e.g.
  `func sampleUUID(forEventUUID: UUID) async throws -> UUID?` (query by metadata),
  and `requestAuthorization()` must cover read+write. Adapter + UITest stub follow.
- **W3 (`HealthService`):** `write`/`backfill` do the dedup query first (relink vs
  write). Tests add: existing-sample → relink + no duplicate write; absent → write
  + metadata stamped; backfill idempotent across a second run.
- **W6 (Info.plist):** `NSHealthShareUsageDescription` is now **required** (read),
  alongside `NSHealthUpdateUsageDescription`. HealthKit capability unchanged.
- **W7 / ADR-0011:** document read+write scope, `dp_event_uuid` durable identity,
  dedup-on-write, and that it neutralizes both reinstall and multi-device dup.

**Note on app deletion (unchanged behaviour, document in ADR + help/UX copy):**
deleting the app does NOT remove Health samples; they remain until the user clears
them in the Health app. The dedup key makes a later reinstall non-duplicating.

### Reconsidered & reaffirmed (owner, 2026-06-29): healthKitUUID stays device-local

Owner asked whether to include `healthKitUUID` in backup/CloudKit to avoid
reinstall duplicates. Weighed and **rejected** — duplicates are already prevented
by `dp_event_uuid` + read-for-dedup, and an HKSample UUID is device-scoped (not
portable; cross-device sync does not guarantee a stable UUID). Including it would:
not remove the read scope (must still verify against the live Health DB), add a
stale-trust hazard (skip a needed write / fail a silent delete), be redundant for
reinstall (query already relinks persisted samples), and feed Phase-B devices a
meaningless id. **Decision stands:** `healthKitUUID` = device-local cache only;
`dp_event_uuid` metadata + query is the durable, self-verifying mechanism.

### Scope addition (owner, 2026-06-29): Apple Health opt-in step in onboarding

Add an Apple Health opt-in to the onboarding flow — **OFF by default, user must
manually toggle it on**. Placement (owner-chosen): a **new dedicated 4th step**
after Guideline.

**W8 — Onboarding Health step (needs W2 + W3; shares flag/AppStorageKeys with W4).**
- New `Features/Onboarding/Components/HealthStep.swift`: explanation copy +
  `Toggle` (OFF initially). Toggling ON → `HealthService.requestAuthorization()`
  (read+write); denied → reflect state inline (don't force-advance). Localized
  English strings.
- `OnboardingViewModel.totalSteps` 3 → 4 (step dots follow automatically);
  `OnboardingView` adds the 4th `TabView` page and moves `onFinish` to it (Health
  step becomes the finisher; Guideline's continue now advances to Health).
- **Shared flag:** writes the SAME `dp_health_write_enabled` (AppStorageKeys) and
  uses the SAME `HealthService` as the Settings toggle (W4), so the two stay in
  sync. Inject `HealthService` into onboarding env like Settings does.
- **No backfill at onboarding** — a brand-new user has empty history; the W4
  "ask at enable" backfill dialog only triggers when events exist (guard on count).
- **Skippable** like the rest of onboarding → leaving it untouched keeps Health OFF.
- Tests: VM test `totalSteps == 4` + advance/back bounds; onboarding UI test that
  the 4th step appears, toggle starts OFF, and toggling drives the
  `UITestHealthStore` stub (no real permission prompt). Reuse `-dp_force_onboarding`.
- **Living docs:** `product.md` (onboarding is now 4 steps incl. optional Health
  opt-in), `roadmap.md`. Note this extends the completed **plan-0009** onboarding.

**Coordination:** W8 and W4 both touch `dp_health_write_enabled` / `AppStorageKeys`
and depend on W3 — keep AppStorageKeys edits single-owner; if run in parallel, one
session adds the key and the other rebases onto it.

---

## 2026-06-29 — W1 DONE: SchemaV4 + v3→v4 stage + healthKitUUID (Opus, main session)

Executed in the planning session (owner said "start"). Single-owner of the
model/migration files — no other session touched them.

- **Froze `SchemaV3`** into a self-contained snapshot (own nested `@Model` copies:
  `consumptionDate` via `@Attribute(originalName:"timestamp")` + `creationDate`,
  NO `healthKitUUID`) — it previously aliased the live classes, so per the no-amend
  rule it had to be frozen before the live shape changed.
- **Added `SchemaV4`** (`Schema.Version(4,0,0)`, live classes).
- **Live `ConsumptionEvent.healthKitUUID: UUID?`** (default nil; doc marks it
  device-local, never exported/synced — ADR-0011).
- **`MigrationPlan`:** `schemas = [V1,V2,V3,V4]`, `stages = [v1ToV2, v2ToV3, v3ToV4]`.
  Retargeted `v2ToV3.didMigrate` to fetch `SchemaV3.ConsumptionEvent` (snapshot)
  — it is no longer the final/live stage. `v3ToV4 = .lightweight` (additive optional).
- **Tests:** `MigrationTests.v3Store_migratesToV4_addsNilHealthKitUUID` (seed frozen
  V3 on disk → reopen V4 → data intact, identity preserved, `healthKitUUID == nil`,
  no recovery). `ComprehensiveRoundTripTests`: stamp `healthKitUUID` on source →
  assert it is dropped by export (post-import nil) — proves device-local exclusion.
  Existing `v2Store_migratesToV3` now transparently exercises V2→V3→V4.

**Gates:** `xcodebuild build` SUCCEEDED, **zero new warnings** (the 2 `UITestSeed`
warnings are pre-existing, commit 5604699). `drinkpulseTests` target green incl.
both new tests (`✔ v3Store_migratesToV4_addsNilHealthKitUUID`, `✔
fullyPopulatedEventAndProfile_everyFieldRoundTrips`). No file > 300 (largest changed
= ConsumptionEvent 189). No calc-module change. No PII logs.
**UI suite not re-run for W1** (no UI surface changed; container-open proven by unit
MigrationTests) — full UI + coverage run is W7's gate.

Committed locally (no push): see `[plan-0036] W1 ...`.

---

## 2026-06-29 — W2 DISCOVERY: HealthKit has no `dietaryAlcohol`; use `numberOfAlcoholicBeverages`

While writing the adapter, SourceKit + the iOS 26.5 SDK headers confirmed the
plan/roadmap/ADR premise is wrong: **`HKQuantityTypeIdentifier.dietaryAlcohol`
does not exist.** The only alcohol identifiers are:
- `numberOfAlcoholicBeverages` — unit **count**, Cumulative (iOS 15+). Apple
  defines 1 unit = a US standard drink = **14 g** pure alcohol. Surfaces in Health
  as "Alcohol Consumption".
- `bloodAlcoholContent` — BAC %, an estimate; belongs to the future BAC feature.

**Correction adopted (pending owner confirm):** write `numberOfAlcoholicBeverages`
as `pureAlcoholGrams / 14.0` (count). The 14 g divisor is FIXED (Apple's
definition), NOT the user's guideline std-drink size — so Health values don't shift
when the user toggles display units (matches calories/BAC using physical 0.789).
`HealthWriting.save(grams:)` stays grams; the adapter converts to count, keeping the
HK contract detail isolated. Code already updated + builds green.

**Ripples to fix once confirmed:** plan summary wording (drinks-count not grams),
ADR-0011 (W7), domain note, and the onboarding/Settings copy ("logs your drinks to
Apple Health" — drinks, not a gram figure). W2 NOT committed until confirmed.

### Resolution (owner, 2026-06-29): numberOfAlcoholicBeverages, exact fractional count

Owner confirmed after clarifying that fractional counts are supported. `HKQuantity`
count unit is a Double, so we write the **exact** `pureAlcoholGrams / 14.0` (e.g.
500 ml @5% → 1.409 drinks) — no rounding, no forced integers; grams recoverable as
`count × 14`. Decision 5 in the handoff is amended: **write a drinks-count to
`numberOfAlcoholicBeverages`, not grams.** Plan/ADR/doc wording to say "drinks" not
"grams" (ADR-0011 + docs in W7). `HealthWriting.save(grams:)` keeps a grams-in API;
the adapter owns the ÷14 conversion.

## 2026-06-29 — W2 DONE: HealthWriting protocol + HKHealthStore adapter + UITest stub

- `Services/HealthWriting.swift` — `HealthWriting` protocol (read+write: auth,
  status, save(grams:date:eventUUID:)→UUID, sampleUUID(forEventUUID:), delete),
  `HealthAuthStatus` enum, `HealthSampleMetadata.eventUUIDKey = "dp_event_uuid"`.
- `Services/HealthKitAdapter.swift` — real `HKHealthStore` conformance using
  `numberOfAlcoholicBeverages` (count); save stamps `dp_event_uuid` metadata and
  writes `grams / 14.0`; `sampleUUID(forEventUUID:)` queries by metadata via
  `HKSampleQueryDescriptor`; delete via `deleteObjects(of:predicate:)` (no-op if
  absent). Framework glue — coverage-excluded.
- `Services/UITestHealthStore.swift` — launch-arg-gated non-prompting stub
  (in-memory event→sample map), mirrors `UITestNotificationCenter`. Inert in prod.

No unit tests in W2 (protocol = no logic; adapter = excluded framework glue; stub =
test infra). HealthService logic + its fake-driven tests are W3.

**Gates:** `xcodebuild build` SUCCEEDED, zero new warnings (only the 2 pre-existing
UITestSeed). New files import HealthKit but need no entitlement to COMPILE (W6 adds
the capability for runtime). No file > 300. No PII logs. Committed locally (no push).

---

## 2026-06-29 — W3 DONE: HealthService (best-effort write/update/remove/backfill + dedup) + tests

Built on the W2 `HealthWriting` contract. New files only — no shared/single-owner
file touched.

### What landed
- `Services/HealthService.swift` (183 lines) — `@MainActor final class`, injected
  `HealthWriting`. `os.Logger` category "HealthService". Methods:
  - `requestAuthorization() async -> Bool` — delegates; catches + logs + returns
    false on error (never throws).
  - `authorizationStatus() -> HealthAuthStatus` — passthrough.
  - `write(_:)` — guards `isHealthDataAvailable` + authorized; **dedup-on-write**:
    `sampleUUID(forEventUUID:)` first → relink (`event.healthKitUUID = found`, no
    duplicate save) if found, else `save(...)` and stamp `healthKitUUID`.
  - `update(_:)` — delete old `healthKitUUID` sample if present (clear field), then
    `performWrite` re-runs dedup. (Nice property: if the delete *fails*, the surviving
    sample is relinked by the follow-up dedup query — never a duplicate.)
  - `remove(_:)` — delete by cached `healthKitUUID`, or by metadata query when nil,
    then clear `healthKitUUID = nil`.
  - `backfill(_:)` — `write` each event; dedup makes a re-run idempotent; continues
    past individual failures.
  - **Serialization:** per-`event.uuid` serial chain (`[UUID: ChainBox]`, identity
    tail-cleanup, all on MainActor) so a rapid edit→delete can't race two ops on one
    event. The service MUTATES `event.healthKitUUID` but owns NO `ModelContext` — the
    caller (W5) saves its own context. All paths best-effort: catch every error, log
    category only (no grams/date/uuid), never throw to the UI flow.
- `drinkpulseTests/Services/HealthServiceTests.swift` (259 lines) + extracted
  `drinkpulseTests/Services/FakeHealthStore.swift` (60 lines) — split to stay < 300.
  Configurable `FakeHealthStore` (tunable availability/status/auth result+error,
  pre-seeded event→sample map, throw-on-save/delete/query flags; records
  save/delete/query counts, grams, deleted uuids). Separate from prod `UITestHealthStore`.

### Tests — 21 `@Test`s, all green; HealthService.swift coverage 100% (123/123)
write_doesNothing_whenHealthUnavailable · write_doesNothing_whenDenied ·
write_doesNothing_whenNotDetermined · write_savesOnce_andStoresHealthKitUUID_whenAuthorizedAndNew ·
write_relinksWithoutDuplicate_whenSampleAlreadyExists · update_deletesOldSample_thenWritesFresh ·
update_writesFresh_whenNoPriorSample · update_whenDeleteFails_relinksSurvivingSample_noDuplicate ·
remove_deletesByCachedUUID_andClearsField · remove_deletesByQuery_whenCacheIsNil ·
remove_noOps_whenNoSampleExists · backfill_writesEveryEvent · backfill_isIdempotent_onSecondRun ·
write_swallowsSaveError_andLeavesUUIDNil · remove_swallowsDeleteError_andStillClearsField ·
write_swallowsQueryError_andLeavesUUIDNil · requestAuthorization_returnsGranted ·
requestAuthorization_returnsFalse_onError · authorizationStatus_passesThroughStoreState ·
writeThenRemove_serialized_leavesConsistentState · defaultInit_buildsServiceFromFactoryStore.

### Gates
- `xcodebuild build` → **BUILD SUCCEEDED**, zero new warnings (only the 4 pre-existing
  baseline warnings: 2 in ReminderService:38, 2 in UITestSeed:50/51).
- `xcodebuild test -only-testing:drinkpulseTests` → **green** (full target passed);
  `HealthServiceTests` = 21/21 (names above appear in the log).
- Coverage: `Services/HealthService.swift` **100.00% (123/123)** — exceeds the
  Services ≥85% target. (Initial run measured 92.68%; the convenience-init/factory and
  the update delete-`catch` branch were the only gaps — covered by the two added tests.)
- Files: HealthService 183, tests 259 + fake 60 — none > 300. No force-unwrap / `try!`.
  No new network. No PII in logs (categories only).

### Deviation
- `defaultStore()` is kept **`@MainActor`** (not `nonisolated` like
  `ReminderService.defaultCenter()`). Reason: both branches (`UITestHealthStore()`,
  `HealthKitAdapter()`) are app-defined main-actor-isolated inits, so a `nonisolated`
  factory would emit 3 NEW main-actor warnings (vs ReminderService's `else` being a
  nonisolated framework call). To keep "zero new warnings", the factory stays on the
  main actor and is invoked from a `@MainActor convenience init()` (the production
  entry point) instead of a default-argument expression (default args evaluate in a
  nonisolated context, which is why ReminderService needed `nonisolated`). `init(store:)`
  remains the injection seam for tests. Same pattern/intent, warning-free.

### For the next waves
- **W4 (Settings) / W8 (Onboarding):** construct via `HealthService()` (convenience
  init picks the real adapter / UI-test stub). Inject through the environment.
- **W5 (hooks):** call `write`/`update`/`remove` fire-and-forget (`Task { await … }`)
  **then save the ModelContext** — the service mutates `event.healthKitUUID` in place
  but does not persist. `backfill(_:)` is for the one-time enable path (W4).
- Runtime authorization needs the **HealthKit entitlement (W6)** — without it
  `authorizationStatus()` returns `.notDetermined` (seen in the test log) and writes
  no-op gracefully; nothing crashes.

Committed locally (no push).
