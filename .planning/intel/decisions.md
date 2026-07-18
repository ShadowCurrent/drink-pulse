# Decisions (from ADRs)

One entry per ADR found in this ingest. All entries preserved separately — no merging.
See `.planning/INGEST-CONFLICTS.md` for contradictions between entries.

## ADR-0001: SwiftData + CloudKit for persistence and sync
- source: docs/decisions/0001-swiftdata-cloudkit.md
- status: locked (Accepted, 2026-05-16)
- decision: Use SwiftData for local persistence and CloudKit (via SwiftData's built-in integration) for optional sync. No custom backend, no third-party database. Conflict resolution is last-write-wins, handled by SwiftData/CloudKit for v1.
- scope: SwiftData, CloudKit, persistence, sync, conflict resolution, schema migrations

## ADR-0002: @Observable macro over ObservableObject
- source: docs/decisions/0002-observable-macro.md
- status: locked (Accepted, 2026-05-16)
- decision: Use @Observable for all view models and shared state objects. ObservableObject, @Published, @StateObject, and @ObservedObject are prohibited in this codebase.
- scope: @Observable, ObservableObject, view models, SwiftUI state, Swift 6 strict concurrency

## ADR-0003: MVVM architecture with repository layer
- source: docs/decisions/0003-mvvm-with-repositories.md
- status: proposed (Status: Superseded by ADR-0004, 2026-05-16; Superseded 2026-05-31) — locked: false
- decision: Use MVVM with a repository layer between view models and SwiftData (View → ViewModel → Repository → ModelContext). Note appended 2026-06-31: the repository layer was never built; the codebase actually follows ADR-0004's pattern. Body preserved unchanged as historical record.
- scope: MVVM, repository layer, SwiftData, view models, architecture

## ADR-0004: Data access via @Query + stateless view models
- source: docs/decisions/0004-data-access-query-stateless-vm.md
- status: locked (Accepted, 2026-05-31; Supersedes ADR-0003)
- decision: Views own data access via @Query and simple mutations via @Environment(\.modelContext); view models are @Observable @MainActor and stateless with respect to persistence — they receive already-fetched [ConsumptionEvent]/UserProfile? as injected plain values and never own a ModelContext. Platform capabilities (notifications, Health, file IO) live in the Services/ layer instead.
- scope: data access, SwiftData, @Query, view models, repository layer, ModelContext

## ADR-0005: Volume→mass density depends on the chosen display unit
- source: docs/decisions/0005-density-by-display-unit.md
- status: proposed (Status: Superseded by ADR-0006, 2026-06-15; Superseded 2026-07-18) — locked: false
- decision: Density used to convert volume → mass depends on the active display unit. AlcoholUnit has three cases: `.grams` → 0.789 g/ml; `.units` (UK) → 0.8 g/ml (500 ml × 5% = 20.0 g = 2.0 WHO/DE units / 2.5 UK units); `.standardDrinks` (US) → 0.789 g/ml (355 ml × 5% = 14.0 g = 1.0 US standard drink). Physical mass (calories, future BAC) always uses 0.789. Guideline limits stay in physical grams. UK unit size = 8.0 g; UK weekly = 112 g. The prior display-rounding layer (displayValue/displayPct/etc.) is deleted. Note appended 2026-07-18: superseded by ADR-0006, which collapses AlcoholUnit to two cases and makes density depend on mode AND guideline; body preserved unchanged as historical record.
- scope: AlcoholUnit, density, pure alcohol grams, guideline limits, BAC, calories, UK units, US standard drinks
- note: formerly locked (Accepted, Status header unset). The Status header now reads "Superseded by ADR-0006" (Superseded date 2026-07-18), so per the locked-ADR rule (only Accepted ADRs are locked) this entry is no longer locked. This resolves the prior LOCKED-vs-LOCKED contradiction with ADR-0006 on the same scope (AlcoholUnit case set / density table). See INGEST-CONFLICTS.md INFO — auto-resolved (LOCKED ADR-0006 wins over non-LOCKED ADR-0005).

## ADR-0006: Volume→mass density depends on the display mode AND the guideline
- source: docs/decisions/0006-density-by-mode-and-guideline.md
- status: locked (Accepted, 2026-06-15; metadata line: "Amends ADR-0005 (which stays frozen)")
- decision: The volume→mass display density depends on both the display mode and the selected guideline, and AlcoholUnit collapses to exactly two cases (`grams`, `standardDrinks`) — the `.units` case is removed; UK folds into `.standardDrinks` at 8.0 g/unit, 0.8 density. Density table: `.grams` any guideline → 0.789; `.standardDrinks` US/CA → 0.789 (mass-defined standard drink); `.standardDrinks` WHO/DE/AU/UK/custom → 0.8 (EU/UK unit convention). Default unit becomes `.standardDrinks`. Persisted `"units"` (and any unknown raw value) decodes to `.standardDrinks` via a custom `init(from:)` (lightweight, additive migration, no store wipe). Physical mass still always uses 0.789; guideline gram limits unchanged. Prose states: "ADR-0005 stays frozen; this ADR is the authoritative density rule going forward."
- scope: AlcoholUnit, density, standard drinks, guideline limits, unit conversion, BAC, calories
- note: this entry is the sole locked, authoritative decision for AlcoholUnit/density going forward. It previously appeared to contradict ADR-0005 (same scope) while both were classified locked; ADR-0005's Status header has since been formally updated to "Superseded by ADR-0006," resolving that contradiction. Corroborated by docs/domain.md (DOC, non-authoritative for precedence) and docs/roadmap.md, both of which already described the two-case model. See INGEST-CONFLICTS.md INFO — auto-resolved.

## ADR-0007: Volume provenance — store the entered unit on each event
- source: docs/decisions/0007-volume-provenance-entered-unit.md
- status: locked (Accepted, 2026-06-23)
- decision: Add an optional `enteredUnit: UnitSystem?` field to ConsumptionEvent, recording the UserProfile.unitSystem in effect when the event was logged; written once at log time, never edited afterward. `volumeMl` remains the canonical, frozen, snapshotted truth — no calculation path changes. The displayed serving name is derived live from the preset table via `(category, volumeMl)` lookup rendered with `enteredUnit`, falling back to the current profile unit (legacy events) or `formatVolume(volumeMl)` (no matching preset). Additive SwiftData migration, no store wipe; export/import gain one optional back-compatible key.
- scope: ConsumptionEvent, volumeMl, enteredUnit, UnitSystem, VolumeOption, SwiftData migration, export/import

## ADR-0008: Services layer for platform capabilities
- source: docs/decisions/0008-services-layer.md
- status: locked (Accepted, 2026-06-26; related to ADR-0004)
- decision: Introduce a `Services/` layer — a stateless or app-lifecycle-scoped type that mediates a platform/system capability (notifications, Health, file IO, …), exposed through a protocol so views/view models depend on the abstraction, not the framework. The framework type is wrapped behind a narrow protocol via a thin adapter; the service (@MainActor final class) takes the protocol via initializer injection defaulting to the real adapter. Tests inject a fake — no real platform prompt/scheduled item/file in tests. Services do not own a ModelContext and are not data access (that stays with ADR-0004). First member: ReminderService (+ NotificationScheduling).
- scope: Services layer, notifications, UNUserNotificationCenter, protocol abstraction, testability, view models

## ADR-0009: Versioned schema baseline and migration plan
- source: docs/decisions/0009-versioned-schema-and-migration-plan.md
- status: locked (Accepted, 2026-06-28; related to ADR-0001, ADR-0008)
- decision: Introduce an explicit versioned-schema baseline and governing migration plan, wired through StoreBootstrap: SchemaV1 (VersionedSchema, versionIdentifier Schema.Version(1,0,0)) capturing the current three-model schema (DrinkTemplate, ConsumptionEvent, UserProfile) as-shipped; MigrationPlan (SchemaMigrationPlan) with schemas=[SchemaV1.self], stages=[]. StoreBootstrap.makeContainer builds the ModelContainer passing migrationPlan: MigrationPlan.self on all container-construction paths. Infrastructure-only — no model-shape change, no behaviour change. Establishes the "snapshot-on-divergence" rule: the first divergent schema (plan-0023) must copy then-current model definitions into a frozen SchemaV1 namespace before editing live classes as SchemaV2.
- scope: SwiftData, VersionedSchema, SchemaMigrationPlan, StoreBootstrap, CloudKit migration

## ADR-0010: CloudKit-ready schema — stable identity, LWW, app-level singleton
- source: docs/decisions/0010-cloudkit-ready-identity-and-lww.md
- status: locked (accepted, Phase A of plan-0023, 2026-06-28; builds on ADR-0009)
- decision: SchemaV2 (on the SchemaV1 baseline from ADR-0009) drops `.unique`, adds inline defaults on every attribute, removes deprecated `ConsumptionEvent.name`; a custom V1→V2 migration stage backfills identity. Adds a stable `uuid: UUID` (NOT `.unique`) on ConsumptionEvent and DrinkTemplate, app code owns de-dup/upsert by uuid. Adds an LWW clock `modifiedDate: Date` on all three models, set on create and on every edit (`touch()`). Conflict resolution = last-write-wins by modifiedDate, except profile manual import which is an unconditional restore, not LWW. App-level singleton for UserProfile via UserProfileStore (fetch-or-create + de-dupe keeping newest modifiedDate), replacing the dropped `.unique`. CloudKit itself stays OFF at this stage (Phase B is a separately-approved, one-way flip).
- scope: SchemaV2, CloudKit, ConsumptionEvent, DrinkTemplate, UserProfile, last-write-wins, migration, RecordDeduplicator, UserProfileStore

## ADR-0011: Apple Health write-back & device-local sample identity
- source: docs/decisions/0011-health-write-back-and-device-local-sample-identity.md
- status: locked (accepted, plan-0036, 2026-06-29; builds on ADR-0008, ADR-0009, ADR-0010)
- decision: Write `numberOfAlcoholicBeverages` as an exact fractional count = `ConsumptionEvent.pureAlcoholGrams / 14.0` (HealthKit has no grams-based alcohol type; Apple fixes one beverage = US standard drink = 14 g, independent of the user's guideline/display unit — no calculation-module change). Durable cross-device identity = sample metadata key `dp_event_uuid` = `ConsumptionEvent.uuid`; before any write/backfill, query Health for that key and relink an existing sample instead of duplicating (requires read + write authorization). `ConsumptionEvent.healthKitUUID: UUID?` is a device-local cache only (SchemaV4, additive optional) — never exported, never synced. Every Health operation is best-effort and non-blocking (caught, logged by category, never blocks or reverts in-app log/edit/delete). Implemented via the Services layer (ADR-0008): `HealthWriting` protocol + `HKHealthStore` adapter + non-prompting `UITestHealthStore` stub, mediated by `@MainActor HealthService`, serialized per `event.uuid`.
- scope: HealthKit, numberOfAlcoholicBeverages, sample identity, ConsumptionEvent, HealthKitAdapter, HealthService
