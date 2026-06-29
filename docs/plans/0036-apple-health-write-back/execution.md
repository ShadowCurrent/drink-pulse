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

---

## 2026-06-29 — W4 DONE: Settings Apple Health section + enable flag + backfill dialog + UI test

Built on W3's `HealthService`. Shared-file touches (`AppStorageKeys`,
`SettingsView`, `drinkpulseApp`, `Localizable.xcstrings`, `UITestSeed`) done as the
single owner of this wave.

### What landed
- **`AppStorageKeys.healthWriteEnabled = "dp_health_write_enabled"`** (off by
  default). Marked the enum `nonisolated` (plain string constants) so referencing a
  key from the `nonisolated` `resetTransientDefaults()` no longer warns — this also
  cleared the *pre-existing* `reminderEnabled` warning at UITestSeed:52.
- **`Features/Settings/Components/HealthSection.swift`** (~165 lines) — a
  `SettingsSection` glass card mirroring `ReminderSection`:
  - Toggle bound to `@AppStorage(healthWriteEnabled)`. Turning ON →
    `HealthService.requestAuthorization()`, then branch on `authorizationStatus()`:
    `.authorized` → stay on; `.denied`/`.notDetermined` → flip back OFF, show inline
    "Apple Health access is off…" message + an "Open Settings" deep link
    (`UIApplication.openSettingsURLString`) — the Reminders denied pattern.
  - On a successful enable, lazily fetches events (mirrors `DataSection.startExport`,
    never a screen-level `@Query`); if any exist, presents a `confirmationDialog`
    "Add your past drinks to Apple Health?" → "Add past drinks" calls
    `healthService.backfill(events)` then `modelContext.save()` (service mutates
    `healthKitUUID` in place); "Not now" cancels. Zero events → no dialog (brand-new
    user just enables).
  - Accessibility labels on the toggle and dialog buttons. Copy is English via
    `String(localized:)` and says "Apple Health" / "your logged drinks" — **never a
    gram value** (Health value is a drinks count, ADR/W2).
- **Env-injection seam (for W5/W8):** `Services/HealthServiceEnvironment.swift` adds
  `@Entry var healthService: HealthService? = nil` to `EnvironmentValues`.
  `drinkpulseApp` holds one `@State private var healthService = HealthService()`
  (real adapter, or UI-test stub under `-dp_uitest`) and injects it via
  `.environment(\.healthService, healthService)` at the root. Optional + `nil`
  default avoids constructing the `@MainActor` service in the key's nonisolated
  default (a Swift 6 isolation error); the root always supplies a real instance.
  W5 (hooks) and W8 (onboarding) read `@Environment(\.healthService)` for the SAME
  instance (its per-event serialization only holds per instance).
- **`SettingsView`** renders `HealthSection()` right after `ReminderSection()`,
  above the Privacy section.
- **`Localizable.xcstrings`** — 9 new English keys: `settings.section.health`,
  `settings.health.toggle` ("Write to Apple Health"), `.hint`, `.denied`,
  `.openSettings`, `.backfill.title/.message/.confirm/.cancel`.
- **`UITestSeed.resetTransientDefaults`** also clears `healthWriteEnabled` so the UI
  test's "starts off" baseline holds across simulator-persisted runs.

### UI test
`drinkpulseUITests/Features/Settings/HealthSettingsUITests.swift` (under `-dp_uitest`
→ `UITestHealthStore` stub auto-grants, no real permission sheet):
- `test_healthToggle_turnsOn_andOffersBackfill` — toggle starts off (Switch value
  "0"), tapping it raises the backfill dialog ("Add past drinks", seeded 500 ml beer
  fixture gives non-empty history), and after dismissing the toggle reads "1".
- `test_healthSection_showsHintCopy` — section hint copy is visible.
Keys off the app's English text + Switch value, never a system-process label.

**Deviation:** the `confirmationDialog`'s `.cancel` button ("Not now") is not exposed
in the XCUI accessibility tree (a SwiftUI confirmationDialog quirk — only the action
button "Add past drinks" appears). The test dismisses via "Add past drinks" (exercises
the backfill-accept path through the stub) instead of "Not now"; the in-app cancel
button still works for users.

### Gates
- `xcodebuild build` (clean) → **BUILD SUCCEEDED**, warnings = ReminderService:38 ×2 +
  UITestSeed:51 ×1 (the `isActive` ref). **Zero new warnings** — in fact one fewer
  than baseline (the `reminderEnabled`/`healthWriteEnabled` key refs no longer warn
  after `nonisolated AppStorageKeys`).
- `xcodebuild test -only-testing:drinkpulseTests` → **TEST SUCCEEDED**, 513 tests in
  33 suites, 0 failures.
- `xcodebuild test -only-testing:drinkpulseUITests/HealthSettingsUITests` → **TEST
  SUCCEEDED**, 2/2 passed (both names above appear in the log; ran on iPhone 17 Pro).
- No new file > 300 (HealthSection ~165, env file 19, UI test ~100). No force-unwrap /
  `try!` in prod (`try!` only in `#Preview`). No PII in logs. No new network.

### For W5/W7/W8
- **W5:** read `@Environment(\.healthService)`; call `write`/`update`/`remove`
  fire-and-forget then `modelContext.save()`, gated on `AppStorageKeys.healthWriteEnabled`.
- **W8:** onboarding writes the SAME `healthWriteEnabled` and reads the SAME
  `\.healthService`; `requestAuthorization()` + status branch as in `HealthSection.enable()`;
  no backfill (guard on count, which is empty for a new user).
- **W7 living docs** (architecture Services note, domain Health-write note, roadmap,
  product onboarding-steps) remain W7's responsibility — not touched here.

Committed locally (no push).

---

## 2026-06-29 — W5 DONE: wired Health write/update/remove into Add/Edit/Delete (fire-and-forget) + tests

Built on W3 (`HealthService`) and W4 (`@Environment(\.healthService)` seam + the
`dp_health_write_enabled` flag). Every hook is gated on the flag, fire-and-forget,
and never blocks/reverts the in-app mutation.

### Shared helper (no per-site duplication)
- **`Services/HealthWriteHooks.swift`** (`@MainActor enum`, 55 lines) — one place for
  the gated, fire-and-forget bridge so the logic is not copy-pasted across the 4
  delete sites + 2 write sites:
  - `isEnabled` — cheap `UserDefaults.standard.bool(forKey: AppStorageKeys.healthWriteEnabled)`
    (unset → false, matching the off-by-default `@AppStorage`).
  - `write(_:in:using:)` / `update(_:in:using:)` — `Task { await service.write/update(event); try? context.save() }`
    so the device-local `healthKitUUID` the service stamps in place gets persisted.
  - `remove(_:using:)` — captures `event.healthKitUUID` + `event.uuid` **synchronously**,
    then `Task { await service.removeSample(healthKitUUID:eventUUID:) }`.
  All three no-op when `!isEnabled` or `healthService == nil` (previews).

### Sites wired
1. **Add Drink save** — `DrinkDetailInputView+Logic.save()`: after `modelContext.insert`
   + `RecordDeduplicator.ensureUniqueIdentity`, calls `HealthWriteHooks.write(event, in: modelContext, using: healthService)`
   before `dismissSheet?()`. Added `@Environment(\.healthService)` to `DrinkDetailInputView`.
2. **Edit save** — `EditEventView.save()`: `HealthWriteHooks.update(event, in: modelContext, using: healthService)`
   after `event.touch()`, before `dismiss()`. Added the env to `EditEventView`.
3. **Delete sites (all 4)** — each calls `HealthWriteHooks.remove(event, using:)` BEFORE
   `context.delete(event)`:
   - `EditEventView.deleteEvent()`
   - `HistoryListQueryView` swipe-to-delete
   - `EventContextMenu.eventContextMenu(...)` shared menu — signature gained a
     `healthService: HealthService?` param; both call sites (`HistoryListQueryView`,
     `HistoryCalendarDayDetail`) pass their `@Environment(\.healthService)`.
   - `HistoryCalendarDayDetail` (via the shared context menu).

### Delete-ordering decision (approach (b), value-based)
Chose the RECOMMENDED capture-ids-first path over awaiting `remove(_:)` before delete:
- Added **`HealthService.removeSample(healthKitUUID: UUID?, eventUUID: UUID) async`** —
  deletes by the cached `healthKitUUID`, else by a `dp_event_uuid` metadata query, all
  best-effort/serialized per `eventUUID`. Refactored `performRemove(_:)` to delegate to a
  shared private `performRemoveSample(...)` (then clear `event.healthKitUUID`), so `remove(_:)`
  is unchanged in behaviour and the two paths share one implementation.
- The helper captures `healthKitUUID`/`uuid` synchronously, the UI calls `context.delete(event)`
  immediately (in-app store updates at once, no Health await on the sync path), and the
  detached task deletes the right sample even though the `@Model` is invalidated by then.
  This is non-blocking AND targets the correct sample — `remove(_:)`, which reads the live
  `@Model`, would have been unsafe to call after `context.delete`.

### Tests
- **Unit** — `drinkpulseTests/Services/HealthServiceRemoveSampleTests.swift` (5 `@Test`s,
  new file to keep `HealthServiceTests` < 300; it dropped back to 288):
  `removeSample_deletesByCachedUUID` · `removeSample_deletesByQuery_whenCachedUUIDIsNil`
  (relink-by-metadata when the cache is nil) · `removeSample_noOps_whenNoSampleExists` ·
  `removeSample_swallowsDeleteError` (error swallowed, no throw) ·
  `removeSample_doesNothing_whenDenied`. `remove(_:)`'s existing tests are untouched.
- **UI** — `drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift` (2 tests),
  launched with Health ENABLED via `-dp_health_write_enabled YES` (NSArgumentDomain
  override outranks the app-domain key `resetTransientDefaults` clears) + `-dp_uitest`
  (→ non-prompting `UITestHealthStore` stub, no real Health sheet):
  `test_healthEnabled_logDrink_stillAppearsInHistory` (log a Wine → appears in History)
  and `test_healthEnabled_deleteDrink_stillRemovesEvent` (context-menu delete still
  removes the seeded beer). Asserts in-app flow integrity; HK sample correctness is
  unit-covered in W3.

### Gates
- `xcodebuild build` → **BUILD SUCCEEDED**, zero new warnings (only the allowed baseline:
  ReminderService:38 ×2, UITestSeed:51 ×1).
- `xcodebuild test -only-testing:drinkpulseTests` → **TEST SUCCEEDED** (full target green;
  the CoreData "no access" log lines are the intentional MigrationTests recovery path).
  `HealthServiceTests` + `HealthServiceRemoveSampleTests` = **26 tests in 2 suites passed**.
- `xcodebuild test -only-testing:drinkpulseUITests/HealthWriteHooksUITests` → **TEST
  SUCCEEDED**, 2/2 passed (both names appear in the log; iPhone 17 Pro).
- No file > 300 (HealthService 197, HealthWriteHooks 55, HealthServiceTests 288, new UI
  test 139, new unit test 73). No prod force-unwrap / `try!` (the `try? context.save()` in
  the write/update hooks is intentional best-effort with a comment). No PII logs. No new network.

### Deviations
- Added `removeSample(_:_:)` to `HealthService` (approach (b)) as the value-based delete
  entry point; `remove(_:)` is retained and now shares `performRemoveSample`.
- `EventContextMenu.eventContextMenu` signature changed (added `healthService:`) — both
  call sites updated; it is the only shared delete site so no further fan-out.
- UI test placed under `Features/AddDrink/` (the log flow is the headline; it also drives
  the History delete) rather than a non-existent Health UI feature folder.

Committed locally (no push). W6/W7/W8 NOT started.

---

## 2026-06-29 — W8 DONE: onboarding Apple Health opt-in (4th step) — finished in main session

The W8 subagent hit its session limit mid-task (work left uncommitted in the tree);
the main coordinator session finished, debugged, and committed it.

- **`Features/Onboarding/Components/HealthStep.swift`** (114 lines) — new optional
  4th step, OFF by default. Toggle reuses `AppStorageKeys.healthWriteEnabled` +
  `@Environment(\.healthService)`; enable path mirrors `HealthSection.enable()`
  minus backfill (a brand-new user has no history). Denied → flip back off + inline
  "enable later in Settings" hint; never blocks finishing.
- **`OnboardingViewModel`** — `totalSteps` 3 → 4 (step dots follow). **onFinish
  re-routed:** GuidelineStep's continue now `advance()`s to the Health step; the
  Health step's "Done" calls the existing finish closure (`vm.complete(into:) +
  onFinish()`), so the profile is still created exactly once, at completion.
- **`OnboardingView`** — added the 4th `TabView` page (tag 3).
- Localizable.xcstrings — new English onboarding.health.* strings.
- Tests: `OnboardingViewModelTests` (16, incl. `totalSteps == 4` + advance/back
  bounds) green; new `OnboardingHealthStepUITests` green; the two pre-existing
  onboarding UI suites (`OnboardingFlowUITests` 3, `OnboardingLocaleDefaultUITests`
  2) updated for the extra step and still green.

**Debug note (coordinator):** the new UI test first failed — DIAG proved `enable()`
never ran (both flags false even after a temp nil-branch marker). Root cause: a
centre `XCUIElement.tap()` on the full-width *labelled* onboarding Toggle lands off
its interactive area (the Settings toggle is `.labelsHidden()` and narrow, so it
worked). Not a logic/env bug — the view is correct for real users. Fixed in the test
by tapping the switch via a trailing-edge coordinate
(`coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5))`). Temp diagnostic
reverted.

**Gates:** build SUCCEEDED, zero new code warnings (only the benign AppIntents
metadata note). All onboarding unit + UI tests green. No production file > 300
(HealthStep 114, OnboardingView 104). No PII logs, no new network. Committed locally.

---

## 2026-06-29 — W6 DONE: HealthKit entitlement + Info.plist usage strings (main session)

- **`drinkpulse/drinkpulse.entitlements`** (new) — `com.apple.developer.healthkit = true`
  (+ empty `com.apple.developer.healthkit.access`).
- **project.pbxproj** (app target, BOTH Debug + Release configs):
  `CODE_SIGN_ENTITLEMENTS = drinkpulse/drinkpulse.entitlements;` and, since the
  project uses `GENERATE_INFOPLIST_FILE = YES` (no physical Info.plist), the two
  usage strings as build settings:
  - `INFOPLIST_KEY_NSHealthUpdateUsageDescription` (write) — "DrinkPulse writes the
    drinks you log to Apple Health as Alcohol Consumption."
  - `INFOPLIST_KEY_NSHealthShareUsageDescription` (read, required for dedup) —
    "DrinkPulse reads its own Alcohol Consumption entries in Apple Health to avoid
    writing duplicate drinks."
  Both strings are required — calling HealthKit authorization without them crashes
  the app; the read string backs the W2/W3 dedup-by-metadata query.

**Gates:** `xcodebuild build` SUCCEEDED with the entitlement processed
(`ProcessProductPackaging` → `__entitlements` linked), signed ad-hoc ("Sign to Run
Locally") — **no provisioning profile needed for the simulator**, so simulator +
UI tests work without a paid account. Health UI tests (Settings ×2, onboarding ×1)
re-run green with the entitlement embedded — app launches + runs fine. Zero new
warnings.

**Device caveat (owner):** the app target signs ad-hoc for the simulator (no
`DEVELOPMENT_TEAM` on the app config). A real **device** install with the HealthKit
entitlement needs automatic signing against a team that has the HealthKit capability
provisioned. Free/personal Apple ID provisioning generally allows HealthKit for
development; App Store distribution needs the paid account. Not a blocker for
simulator development or this plan.

---

## 2026-06-29 — W7 DONE: close-out (ADR-0011, coverage, living docs) — main session

- **ADR-0011** created (Health write-back & device-local sample identity:
  numberOfAlcoholicBeverages count, fixed 14 g, dp_event_uuid dedup, read+write,
  device-local healthKitUUID, best-effort).
- **Full suite + coverage:** `xcodebuild test` (all targets) → **TEST SUCCEEDED**;
  app coverage **93.23%** (≥90%); `HealthService` logic 100%; `HealthSection`/
  `HealthStep` are SwiftUI views (82% — view layout excluded from the denominator,
  wiring covered by UI tests).
- **Living docs:** roadmap (🗓→✅, corrected type), product.md (onboarding 4 steps +
  Health feature), architecture.md (Services: HealthService/HealthWriting/hooks),
  README (Settings + onboarding Health line), domain.md (`healthKitUUID` field +
  "Apple Health write-back mapping" rule).
- **Lifecycle:** plan.md → completed; INDEX → completed; retrospective.md created;
  DEVLOG appended; context files updated.

plan-0036 is **complete**. All work committed locally; nothing pushed.
