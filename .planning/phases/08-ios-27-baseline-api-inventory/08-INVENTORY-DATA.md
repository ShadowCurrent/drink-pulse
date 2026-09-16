# Phase 08 — Data, Platform Service, Concurrency, Test, and Tooling Inventory

**Reviewed:** 2026-09-16  
**Scope:** Plan 08-04 only. This is an inventory, not an implementation plan; it does not alter production code, tests, frozen schemas, user data, notifications, HealthKit, or Xcode configuration.

## Review rules and source register

The current Xcode 27 toolchain uses the Swift 6.4 compiler while this project deliberately remains in `SWIFT_VERSION = 6.0` language mode. A compiler or standard-library novelty alone is not a reason to rewrite calculations, migration, export, notification, or HealthKit behavior.

| Source | Checked | Used for |
| --- | --- | --- |
| [Swift 6.4 Released](https://www.swift.org/blog/swift-6.4-released/) | 2026-09-16 | Async `defer`, `withTaskCancellationShield`, Observation notifications, and Swift Testing/XCTest interoperability. The release describes async `defer` and cancellation shields as cleanup tools, not required migrations. |
| [Swift data-race safety guidance](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/dataracesafety/) | 2026-09-16 | Review of `Sendable`, actor isolation, and the existing `@unchecked Sendable` boundaries. |
| [Apple `VersionedSchema`](https://developer.apple.com/documentation/swiftdata/versionedschema) | 2026-09-16 | SwiftData versioned-schema and migration-plan review. |
| [Apple `HKHealthStore`](https://developer.apple.com/documentation/healthkit/hkhealthstore) | 2026-09-16 | Permission, save, query, and delete APIs at the HealthKit trust boundary. |
| [Apple `UNUserNotificationCenter`](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter) | 2026-09-16 | Notification authorization, scheduling, pending-request, and delegate APIs. |
| `docs/decisions/0009-versioned-schema-and-migration-plan.md` | 2026-09-16 | Shipped snapshots are immutable; a model-shape change requires a new version and stage. |
| `docs/decisions/0010-cloudkit-ready-identity-and-lww.md` | 2026-09-16 | UUID/LWW, deduplication, singleton, and CloudKit-off invariants. |
| `docs/decisions/0011-health-write-back-and-device-local-sample-identity.md` | 2026-09-16 | Opt-in/non-blocking HealthKit, `dp_event_uuid`, and device-local `healthKitUUID` invariants. |
| `docs/domain.md` | 2026-09-16 | Canonical grams, versioned export format, v1/v2 import compatibility, and profile restore rule. |

For every row, “no deprecation statement” means this review found no current official Apple/Swift deprecation or replacement statement for the cited API. The exact availability/deprecation wording is therefore **“No deprecation or replacement is claimed by this inventory.”** An API's age, a compiler update, or an unobserved iOS 27 behavior is not affirmative evidence of a replacement.

## Invariants that constrain every disposition

- `SchemaV1.swift` through `SchemaV4.swift` are immutable shipped snapshots. A stored-property or schema-shape proposal is substantial (D-09), must add a new `VersionedSchema` and `MigrationStage`, and requires a Phase 10 owner brief before it can be planned.
- `ConsumptionEvent.uuid` and `DrinkTemplate.uuid` are stable app-owned identities; `modifiedDate` implements LWW. CloudKit stays disabled.
- `ExportBundle` is currently v2. Export format, import compatibility, quantity, profile-upsert behavior, calculation formulas, and grams as the canonical unit are not changed for a target raise.
- HealthKit writes fractional `numberOfAlcoholicBeverages`; `dp_event_uuid` is durable dedup identity and `healthKitUUID` is a never-exported, device-local cache. Health operations remain opt-in, best-effort, and non-blocking.

## Distinct candidates and retain decisions — domain, persistence, and tests

| ID | Area / pattern | All exact locations | Official source and availability/deprecation | Evidence | Disposition / priority / phase | Rationale and D-09 status |
| --- | --- | --- | --- | --- | --- | --- |
| D-01 | `VersionedSchema` + `SchemaMigrationPlan` + custom/lightweight stages | `drinkpulse/Domain/Persistence/MigrationPlan.swift:7-61`; `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift:4-133`; `SchemaV2.swift:4-70`; `SchemaV3.swift:4-72`; `SchemaV4.swift:4-12`; `drinkpulseTests/Domain/Persistence/MigrationTests.swift:19-255` | Apple [`VersionedSchema`](https://developer.apple.com/documentation/swiftdata/versionedschema), checked 2026-09-16. No deprecation or replacement is claimed by this inventory. | Source + ADR-0009/0010 + migration tests. | **retain**, P0, Phase 10 verification only | Current V1→V4 stages preserve snapshot, UUID/LWW, rename/backfill, and nullable Health cache behavior. Any replacement or schema edit is substantial: it can change persisted data, migration lifecycle, or CloudKit readiness; prepare an owner brief before any Phase 10 plan. |
| D-02 | JSON backup/export transfer representation and v1/v2 import | `drinkpulse/Domain/DataTransfer/BackupExport.swift:5-44`; `DataImporter.swift:4-157`; `ExportBundle.swift:3-17`; `ExportRecord.swift:3-64`; `ProfileRecord.swift:3-42`; `TemplateRecord.swift:3-62`; `BackupDocument.swift:3-20`; `ImportError.swift:3-15`; `ImportResult.swift:3-8`; `DrinkControlImporter.swift:3-112`; `drinkpulseTests/Domain/DataTransfer/ComprehensiveRoundTripTests.swift:1-84`; `DataBackupExportTests.swift:1-71`; `DataImporterEdgeCaseTests.swift:1-135`; `DataImporterRoundTripTests.swift:1-231`; `DataImporterUpsertTests.swift:1-129`; `DrinkControlImporterTests.swift:1-192` | Apple [Transferable](https://developer.apple.com/documentation/coretransferable/transferable), checked 2026-09-16; Swift 6.4 release notes, checked 2026-09-16. No deprecation or replacement is claimed by this inventory. | Source, docs/domain.md, ADR-0010, round-trip/upsert tests. | **retain**, P0, Phase 10 verification only | `FileRepresentation` creates an atomic temporary JSON export. The v2 bundle, ISO-8601 encoding, UUID/LWW upsert, legacy heuristic, and unconditional profile restore are compatibility contracts. A new format, stored field, or import rule is substantial and needs its own owner brief; no Swift 6.4 feature supplies a behavior-preserving reason to change it. |
| D-03 | Swift 6.4 async cleanup / cancellation shield at real cleanup call sites | `drinkpulseTests/Domain/Persistence/MigrationTests.swift:27-33,106-112,158-164,210-216`; `StoreBootstrapTests.swift:39-46`; other `defer` occurrences are synchronous test fixture cleanup | Swift [6.4 release notes](https://www.swift.org/blog/swift-6.4-released/), checked 2026-09-16: async `defer` awaits asynchronous cleanup; `withTaskCancellationShield` protects cleanup from cancellation. No deprecation or replacement is claimed by this inventory. | Concrete call-site review. | **retain**, P2, — | These `defer` blocks only remove temporary files synchronously. No asynchronous resource cleanup or cancellation bug was found, so adopting either feature would be speculative churn. |
| D-04 | Swift Testing / XCTest interoperability and XCTest performance measurement | All assigned Domain, Services, Features, Diagnostics, and Performance test files in the reviewed-file record; `drinkpulseTests/Performance/ScreenComputePerformanceTests.swift:1-92` is the sole XCTest `measure` surface | Swift [6.4 release notes](https://www.swift.org/blog/swift-6.4-released/), checked 2026-09-16: XCTest assertions can be used in Swift Testing and `#expect` in XCTest. No deprecation or replacement is claimed by this inventory. | Imports and test-framework scan. | **retain**, P2, — | The suite already uses Swift Testing for async/domain behavior and keeps XCTest `measure` for performance. There is no concrete mixed-framework assertion problem; no test rewrite is justified. |
| D-05 | Domain calculations, model identity, guideline and unit helpers | `ConsumptionEvent.swift:4-132`; `DrinkTemplate.swift:4-74`; `UserProfile.swift:4-59`; `AlcoholUnit.swift:3-63`; `GuidelineChoice+Limits.swift:3-36`; `GuidelineLimits.swift:3-12`; `WeeklySummaryCalculator.swift:3-33`; all matching Domain tests below | Swift 6.4 release notes, checked 2026-09-16. No deprecation or replacement is claimed by this inventory. | Source + docs/domain.md + tests. | **retain**, P0, — | Canonical grams, display-density rules, threshold boundaries, UUID/LWW, and weekly comparison semantics are deliberately established behavior. No source-backed iOS 27/Swift 6.4 candidate benefits these call sites. A calculation or stored-property change is substantial. |

## Explicit no-candidate rows — domain and corresponding unit tests

| ID | Reviewed area | Files and API/pattern families checked | Result |
| --- | --- | --- | --- |
| N-D01 | Domain root models and calculations | All root `drinkpulse/Domain/*.swift`; SwiftData `@Model`, `Codable`, Foundation formatting/Calendar/UUID, pure-alcohol calculation, guideline/unit/risk helpers, UUID/LWW | **no-candidate — retain.** No deprecation or behavior-preserving Swift 6.4 replacement was found. |
| N-D02 | Data transfer | All `drinkpulse/Domain/DataTransfer/*.swift`; `Transferable`, `FileRepresentation`, `Codable`, JSON/ISO-8601, temporary atomic file write, import validation/upsert | **no-candidate — retain.** Export-format and importer changes are substantial. |
| N-D03 | Persistence and current-store safety | All `drinkpulse/Domain/Persistence/*.swift`; `VersionedSchema`, `SchemaMigrationPlan`, `MigrationStage`, `ModelContainer`, recovery, dedupe, singleton | **no-candidate — retain.** Existing-store proof, not a source rewrite, belongs to Phase 10. |
| N-D04 | Frozen schema snapshots | `SchemaV1.swift` through `SchemaV4.swift`; model shapes, defaults, relationship, V3 rename, V4 live-model bridge | **no-candidate — retain.** Snapshots are read-only; no target raise warrants mutation. |
| N-D05 | Domain unit tests | All top-level `drinkpulseTests/Domain/*.swift`; Swift Testing `@Test`/`#expect`, deterministic calculations, Codable, formatting and value behavior | **no-candidate — retain.** Existing test framework mix is intentional. |
| N-D06 | Data-transfer and persistence tests | All `drinkpulseTests/Domain/DataTransfer/*.swift` and `Persistence/*.swift`; round trip, legacy v1/v2 data, LWW, migration, recovery fixture cleanup | **no-candidate — retain.** Tests preserve compatibility; no Swift 6.4 change has a concrete benefit. |

## Reviewed-file record — domain and corresponding tests

Each tracked Swift path below was opened/reviewed. The line count is the reviewed file extent on 2026-09-16. `SchemaV1`–`V4` are explicitly read-only.

### `drinkpulse/Domain/` root

`AlcoholUnit.swift` (63), `BiologicalSex.swift` (5), `ConsumptionEvent.swift` (132), `Currency.swift` (38), `CustomNameSuggestionFilter.swift` (30), `DrinkCategory.swift` (7), `DrinkTemplate.swift` (74), `GuidelineChoice+Display.swift` (23), `GuidelineChoice+Limits.swift` (36), `GuidelineChoice+Selectable.swift` (5), `GuidelineChoice.swift` (5), `GuidelineLimits.swift` (12), `RiskLevel.swift` (13), `UnitSystem+ServingLabels.swift` (67), `UnitSystem+Volume.swift` (43), `UnitSystem.swift` (7), `UserProfile.swift` (59), `WeeklySummaryCalculator.swift` (33).

### `drinkpulse/Domain/DataTransfer/`

`BackupDocument.swift` (20), `BackupExport.swift` (45), `DataImporter.swift` (157), `DrinkControlImporter.swift` (112), `ExportBundle.swift` (17), `ExportRecord.swift` (64), `ImportError.swift` (15), `ImportResult.swift` (8), `ProfileRecord.swift` (42), `TemplateRecord.swift` (62).

### `drinkpulse/Domain/Persistence/`

`ContainerLoadState.swift` (7), `MigrationPlan.swift` (62), `RecordDeduplicator.swift` (54), `StartupError.swift` (18), `StoreBootstrap.swift` (91), `UserProfileStore.swift` (36); frozen `Schemas/SchemaV1.swift` (133), `SchemaV2.swift` (70), `SchemaV3.swift` (72), and `SchemaV4.swift` (12).

### `drinkpulseTests/Domain/`

`AlcoholCalculationTests.swift` (64), `AlcoholUnitFormattingTests.swift` (167), `AlcoholUnitTests.swift` (82), `ConsumptionEventTests.swift` (187), `CurrencyTests.swift` (46), `CustomNameSuggestionFilterTests.swift` (73), `DrinkTemplateTests.swift` (67), `DrinkTypePresetTests.swift` (230), `GuidelineChoiceDisplayTests.swift` (100), `GuidelineLimitsTests.swift` (192), `RiskLevelTests.swift` (43), `UnitSystemVolumeTests.swift` (171), `UserProfileTests.swift` (25), `WeeklySummaryCalculatorTests.swift` (97).

### `drinkpulseTests/Domain/DataTransfer/`

`ComprehensiveRoundTripTests.swift` (84), `DataBackupExportTests.swift` (71), `DataImporterEdgeCaseTests.swift` (135), `DataImporterRoundTripTests.swift` (231), `DataImporterUpsertTests.swift` (129), `DrinkControlImporterTests.swift` (192).

### `drinkpulseTests/Domain/Persistence/`

`MigrationTests.swift` (257), `RecordDeduplicatorTests.swift` (108), `StartupErrorTests.swift` (23), `StoreBootstrapTests.swift` (121), `UserProfileStoreTests.swift` (85).

## Task 1 verification record

- Reviewed source locations resolve to tracked files (`git ls-files` inventory, 2026-09-16).
- No production, test, or frozen-schema file was modified by Task 1.
- Pending Task 2 adds Services, remaining test, concurrency, and Xcode tooling coverage to this same artifact.
