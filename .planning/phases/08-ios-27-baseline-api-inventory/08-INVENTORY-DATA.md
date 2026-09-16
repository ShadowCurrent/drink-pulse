# Phase 08 — Data, Platform Service, Concurrency, Test, and Tooling Inventory

**Reviewed:** 2026-09-16  
**Scope:** Plan 08-04 only. This is an inventory, not an implementation plan; it does not alter production code, tests, frozen schemas, user data, notifications, HealthKit, or Xcode configuration.

## Review rules and source register

The current Xcode 27 toolchain uses the Swift 6.4 compiler while this project deliberately remains in `SWIFT_VERSION = 6.0` language mode. The concurrency review follows current Swift data-race guidance; the platform review includes HealthKit and UserNotifications. A compiler or standard-library novelty alone is not a reason to rewrite calculations, migration, export, notification, or HealthKit behavior.

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

## Distinct candidates and retain decisions — services, concurrency, remaining tests, and tooling

| ID | Area / pattern | All exact locations | Official source and availability/deprecation | Evidence | Disposition / priority / phase | Rationale and D-09 status |
| --- | --- | --- | --- | --- | --- | --- |
| S-01 | Notification-center `@retroactive @unchecked Sendable` and delegate isolation | `drinkpulse/Services/NotificationScheduling.swift:4-20` (unchecked conformance at :11); `NotificationActionHandler.swift:4-32` (delegate conformance at :4, main-actor hops at :16-18 and :20-23); `ReminderService.swift:5-69`; `WeeklySummaryService.swift:6-132`; `UITestNotificationCenter.swift:4-21`; matching tests listed below | Apple [`UNUserNotificationCenter`](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter) and Swift [data-race safety guidance](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/dataracesafety/), checked 2026-09-16. No deprecation or replacement is claimed by this inventory. | Concrete source review; notification scheduling and cold/warm routing invariants. | **retain pending proof**, P1, Phase 10 | Removing/replacing the unchecked conformance or moving delegate isolation can change authorization, pending-request cancellation, and cold/warm routing. This is a **substantial system-integration/lifecycle candidate**: a Phase 10 owner brief must show an iOS 27 data-race diagnostic or a reproducer, exact proposed isolation, and regression coverage before a rewrite is planned. |
| S-02 | HealthKit adapter, authorization, sample identity, and per-event serial execution | `drinkpulse/Services/HealthKitAdapter.swift:4-60`; `HealthService.swift:4-155`; `HealthWriteHooks.swift:4-36`; `HealthWriting.swift:3-25`; `UITestHealthStore.swift:3-28`; `HealthServiceEnvironment.swift:1-5`; matching tests listed below | Apple [`HKHealthStore`](https://developer.apple.com/documentation/healthkit/hkhealthstore) and Swift [data-race safety guidance](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/dataracesafety/), checked 2026-09-16. No deprecation or replacement is claimed by this inventory. | Source, ADR-0011, Health service and hook tests. | **retain pending proof**, P0, Phase 10 | `@MainActor` service state and `runSerial(_:_: )` protect write/update/delete ordering by event UUID; adapters are unchecked Sendable at the framework boundary. Altering their actor/sendability form, task lifetime, or authorization flow can alter permission behavior, `dp_event_uuid` deduplication, device-local cache semantics, or non-blocking deletes. It is a **substantial integration/lifecycle candidate** requiring an owner brief plus observed interrupted/parallel-operation proof. |
| S-03 | Swift 6.4 async `defer` / cancellation shield against task-lifetime call sites | `drinkpulse/Services/HealthWriteHooks.swift:11-35`; `HealthService.swift:44-71,142-154`; `ReminderService.swift:51-68`; `WeeklySummaryService.swift:55-90` | Swift [6.4 release notes](https://www.swift.org/blog/swift-6.4-released/), checked 2026-09-16: async `defer` and `withTaskCancellationShield` are cleanup tools. No deprecation or replacement is claimed by this inventory. | Existing `Task` lifetimes and serial tail implementation; no interruption reproducer. | **retain pending proof**, P1, Phase 10 | There is no current async cleanup that must outlive cancellation. Shielding notification or HealthKit operations without a demonstrated loss can prolong work after user intent and change lifecycle semantics. **Flagged assumption:** interrupted or parallel service/test operations need observed guarantees before any modernization recommendation. |
| S-04 | Swift Testing/XCTest continuation, service fakes, UI seed doubles, diagnostics, and performance tests | All assigned `drinkpulseTests/Services/`, `Features/`, `Diagnostics/`, and `Performance/` files; `ScreenComputePerformanceTests.swift:1-92` is XCTest `measure` | Swift [6.4 release notes](https://www.swift.org/blog/swift-6.4-released/), checked 2026-09-16. No deprecation or replacement is claimed by this inventory. | Framework/import scan and existing focused test surfaces. | **retain**, P2, — | Swift 6.4 permits assertion interoperability but creates no need to rewrite focused Swift Testing tests, fake stores, UI seeds, diagnostics, or XCTest performance measurement. |
| S-05 | Xcode project, shared scheme, deployment/language configuration, Info.plist/entitlements references, dependency state | `drinkpulse.xcodeproj/project.pbxproj:282-287,346,405,422-440,451-469,479-517`; `drinkpulse.xcodeproj/xcshareddata/xcschemes/drinkpulse.xcscheme:1-114`; `project.xcworkspace/contents.xcworkspacedata:1-7` | Apple [Xcode command-line reference](https://developer.apple.com/documentation/xcode/xcode-command-line-tool-reference) and [Running tests and interpreting results](https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results), checked 2026-09-16. No deprecation or replacement is claimed by this inventory. | Project/scheme inspection and `08-BASELINE.md`. | **retain**, P1, Phase 11 verification | All six target/config pairs are iOS 27.0 and Swift language mode 6.0. The shared scheme has unit and UI testables enabled. The project references the app `Info.plist` and entitlements but this inventory does not expose their contents or change signing. No package dependency is resolved. |
| S-06 | Baseline diagnostics attributable to the service/tooling review | Original evidence: `.planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md` and `08-BASELINE.json`; raw logs: `/Users/fempter/Library/Logs/DrinkPulse/phase-08-ios27/20260916T200000Z/{debug-build,release-build,full-test}.{stdout,stderr}.log` | Baseline evidence, checked 2026-09-16. | D-03 classification record. | **retain / externally evidenced**, P1, Phase 09 | No assigned Services, test, or Xcode tooling diagnostic was found. All three baseline commands stop on the app-owned `drinkpulse/DesignSystem/DPArcProgress.swift:33` `Shape`/main-actor data-race compiler error; `drinkpulse/Features/AddDrink/AddDrinkView.swift:5` also warns about an `@Entry` closure. Raw logs remain outside Git and no health values are copied here. |

## Explicit no-candidate rows — services, remaining tests, concurrency, and tooling

| ID | Reviewed area | Files and API/pattern families checked | Result |
| --- | --- | --- | --- |
| N-S01 | Notification services | `NotificationScheduling`, `NotificationActionHandler`, `ReminderService`, `WeeklySummaryService`, `UITestNotificationCenter`; `UNUserNotificationCenter`, requests/triggers, authorization, delegate routing, lazy center resolution, test double | **no-candidate — retain.** The unchecked Sendable boundary is separately flagged in S-01; no evidence supports removal. |
| N-S02 | Health services | `HealthKitAdapter`, `HealthService`, `HealthWriteHooks`, `HealthWriting`, `HealthServiceEnvironment`, `UITestHealthStore`; `HKHealthStore`, authorization, quantity sample, metadata query/delete, actor isolation, per-event serialization, test double | **no-candidate — retain.** The potential concurrency boundary is separately flagged in S-02/S-03; permission and identity semantics stay unchanged. |
| N-S03 | Service unit tests | All `drinkpulseTests/Services/*.swift`; Swift Testing, async tests, fake Health store, authorization/write/update/remove/backfill, scheduling and cancellation assertions | **no-candidate — retain.** Existing test models cover the behavior that a future substantial brief must preserve. |
| N-S04 | Feature unit tests assigned to this plan | All `drinkpulseTests/Features/**/*.swift`; Swift Testing assertions, feature view-model calculations, History/Insights/accessibility helpers, onboarding Health step | **no-candidate — retain.** These are non-UI unit surfaces, not a reason for a framework migration. |
| N-S05 | Diagnostics and performance tests | `drinkpulseTests/Diagnostics/ViewLoadLoggerTests.swift`; `drinkpulseTests/Performance/ScreenComputePerformanceTests.swift`; XCTest `measure`, deterministic test fixtures | **no-candidate — retain.** `measure` remains the concrete performance facility; interop adds no benefit. |
| N-S06 | Xcode tooling and project state | Tracked project file, workspace, shared scheme; build settings, target testables, Info.plist and entitlements references, package/dependency state | **no-candidate — retain.** No project/tooling change is supported beyond the completed iOS 27 baseline alignment. |

## Reviewed-file record — services, remaining tests, and Xcode tooling

Each tracked file below was opened/reviewed. The line count is the reviewed file extent on 2026-09-16.

### `drinkpulse/Services/`

`HealthKitAdapter.swift` (61), `HealthService.swift` (156), `HealthServiceEnvironment.swift` (5), `HealthWriteHooks.swift` (37), `HealthWriting.swift` (25), `NotificationActionHandler.swift` (33), `NotificationScheduling.swift` (21), `ReminderService.swift` (70), `UITestHealthStore.swift` (29), `UITestNotificationCenter.swift` (22), `WeeklySummaryService.swift` (132).

### `drinkpulseTests/Services/`

`FakeHealthStore.swift` (57), `HealthServiceRemoveSampleTests.swift` (64), `HealthServiceTests.swift` (302), `HealthWriteHooksTests.swift` (129), `ReminderServiceTests.swift` (209), `WeeklySummaryServiceScheduleTests.swift` (208), `WeeklySummaryServiceTests.swift` (129).

### `drinkpulseTests/Features/`

`AddDrink/DrinkDetailInputMathTests.swift` (101); `Dashboard/DashboardViewModelTests.swift` (265), `DashboardViewModelTests+Formatting.swift` (123), `DashboardViewModelTests+Metrics.swift` (327), `DashboardViewModelTests+PctAndRisk.swift` (157); `History/EditEventDeleteTests.swift` (45), `EditEventVolumeGuardTests.swift` (48), `EventRowStringsTests.swift` (119), `HistoryViewModelTests.swift` (244), `HistoryViewModelTests+DayRollover.swift` (64), `HistoryViewModelTests+Pagination.swift` (127), `HistoryViewTests.swift` (23), `RowUnitContextTests.swift` (49); `Insights/AlcoholAreaChartAXDescriptorTests.swift` (65), `InsightsDataGeneratorTests.swift` (102), `InsightsPeriodTests.swift` (207), `InsightsViewModelTests.swift` (263), `InsightsViewModelTests+Aggregates.swift` (335), `InsightsViewModelTests+Navigation.swift` (146), `WeekdayBarChartAXDescriptorTests.swift` (59); `Onboarding/Components/HealthStepTests.swift` (17), `Onboarding/OnboardingViewModelTests.swift` (174).

### Diagnostics and performance

`drinkpulseTests/Diagnostics/ViewLoadLoggerTests.swift` (24); `drinkpulseTests/Performance/ScreenComputePerformanceTests.swift` (92).

### `drinkpulse.xcodeproj/`

`project.pbxproj` (537; build settings and Info.plist/entitlements references reviewed), `project.xcworkspace/contents.xcworkspacedata` (7), and `xcshareddata/xcschemes/drinkpulse.xcscheme` (114). No user-specific `xcuserdata` artifact is tracked, and no `Package.resolved` is present.

### Exact tracked-path audit manifest

The contextual lists above are concise; this literal manifest is the coverage assertion for every path assigned to Plan 08-04.

```text
drinkpulse/Domain/AlcoholUnit.swift
drinkpulse/Domain/BiologicalSex.swift
drinkpulse/Domain/ConsumptionEvent.swift
drinkpulse/Domain/Currency.swift
drinkpulse/Domain/CustomNameSuggestionFilter.swift
drinkpulse/Domain/DataTransfer/BackupDocument.swift
drinkpulse/Domain/DataTransfer/BackupExport.swift
drinkpulse/Domain/DataTransfer/DataImporter.swift
drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift
drinkpulse/Domain/DataTransfer/ExportBundle.swift
drinkpulse/Domain/DataTransfer/ExportRecord.swift
drinkpulse/Domain/DataTransfer/ImportError.swift
drinkpulse/Domain/DataTransfer/ImportResult.swift
drinkpulse/Domain/DataTransfer/ProfileRecord.swift
drinkpulse/Domain/DataTransfer/TemplateRecord.swift
drinkpulse/Domain/DrinkCategory.swift
drinkpulse/Domain/DrinkTemplate.swift
drinkpulse/Domain/GuidelineChoice+Display.swift
drinkpulse/Domain/GuidelineChoice+Limits.swift
drinkpulse/Domain/GuidelineChoice+Selectable.swift
drinkpulse/Domain/GuidelineChoice.swift
drinkpulse/Domain/GuidelineLimits.swift
drinkpulse/Domain/Persistence/ContainerLoadState.swift
drinkpulse/Domain/Persistence/MigrationPlan.swift
drinkpulse/Domain/Persistence/RecordDeduplicator.swift
drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift
drinkpulse/Domain/Persistence/Schemas/SchemaV2.swift
drinkpulse/Domain/Persistence/Schemas/SchemaV3.swift
drinkpulse/Domain/Persistence/Schemas/SchemaV4.swift
drinkpulse/Domain/Persistence/StartupError.swift
drinkpulse/Domain/Persistence/StoreBootstrap.swift
drinkpulse/Domain/Persistence/UserProfileStore.swift
drinkpulse/Domain/RiskLevel.swift
drinkpulse/Domain/UnitSystem+ServingLabels.swift
drinkpulse/Domain/UnitSystem+Volume.swift
drinkpulse/Domain/UnitSystem.swift
drinkpulse/Domain/UserProfile.swift
drinkpulse/Domain/WeeklySummaryCalculator.swift
drinkpulse/Services/HealthKitAdapter.swift
drinkpulse/Services/HealthService.swift
drinkpulse/Services/HealthServiceEnvironment.swift
drinkpulse/Services/HealthWriteHooks.swift
drinkpulse/Services/HealthWriting.swift
drinkpulse/Services/NotificationActionHandler.swift
drinkpulse/Services/NotificationScheduling.swift
drinkpulse/Services/ReminderService.swift
drinkpulse/Services/UITestHealthStore.swift
drinkpulse/Services/UITestNotificationCenter.swift
drinkpulse/Services/WeeklySummaryService.swift
drinkpulseTests/Diagnostics/ViewLoadLoggerTests.swift
drinkpulseTests/Domain/AlcoholCalculationTests.swift
drinkpulseTests/Domain/AlcoholUnitFormattingTests.swift
drinkpulseTests/Domain/AlcoholUnitTests.swift
drinkpulseTests/Domain/ConsumptionEventTests.swift
drinkpulseTests/Domain/CurrencyTests.swift
drinkpulseTests/Domain/CustomNameSuggestionFilterTests.swift
drinkpulseTests/Domain/DataTransfer/ComprehensiveRoundTripTests.swift
drinkpulseTests/Domain/DataTransfer/DataBackupExportTests.swift
drinkpulseTests/Domain/DataTransfer/DataImporterEdgeCaseTests.swift
drinkpulseTests/Domain/DataTransfer/DataImporterRoundTripTests.swift
drinkpulseTests/Domain/DataTransfer/DataImporterUpsertTests.swift
drinkpulseTests/Domain/DataTransfer/DrinkControlImporterTests.swift
drinkpulseTests/Domain/DrinkTemplateTests.swift
drinkpulseTests/Domain/DrinkTypePresetTests.swift
drinkpulseTests/Domain/GuidelineChoiceDisplayTests.swift
drinkpulseTests/Domain/GuidelineLimitsTests.swift
drinkpulseTests/Domain/Persistence/MigrationTests.swift
drinkpulseTests/Domain/Persistence/RecordDeduplicatorTests.swift
drinkpulseTests/Domain/Persistence/StartupErrorTests.swift
drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift
drinkpulseTests/Domain/Persistence/UserProfileStoreTests.swift
drinkpulseTests/Domain/RiskLevelTests.swift
drinkpulseTests/Domain/UnitSystemVolumeTests.swift
drinkpulseTests/Domain/UserProfileTests.swift
drinkpulseTests/Domain/WeeklySummaryCalculatorTests.swift
drinkpulseTests/Features/AddDrink/DrinkDetailInputMathTests.swift
drinkpulseTests/Features/Dashboard/DashboardViewModelTests+Formatting.swift
drinkpulseTests/Features/Dashboard/DashboardViewModelTests+Metrics.swift
drinkpulseTests/Features/Dashboard/DashboardViewModelTests+PctAndRisk.swift
drinkpulseTests/Features/Dashboard/DashboardViewModelTests.swift
drinkpulseTests/Features/History/EditEventDeleteTests.swift
drinkpulseTests/Features/History/EditEventVolumeGuardTests.swift
drinkpulseTests/Features/History/EventRowStringsTests.swift
drinkpulseTests/Features/History/HistoryViewModelTests+DayRollover.swift
drinkpulseTests/Features/History/HistoryViewModelTests+Pagination.swift
drinkpulseTests/Features/History/HistoryViewModelTests.swift
drinkpulseTests/Features/History/HistoryViewTests.swift
drinkpulseTests/Features/History/RowUnitContextTests.swift
drinkpulseTests/Features/Insights/AlcoholAreaChartAXDescriptorTests.swift
drinkpulseTests/Features/Insights/InsightsDataGeneratorTests.swift
drinkpulseTests/Features/Insights/InsightsPeriodTests.swift
drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift
drinkpulseTests/Features/Insights/InsightsViewModelTests+Navigation.swift
drinkpulseTests/Features/Insights/InsightsViewModelTests.swift
drinkpulseTests/Features/Insights/WeekdayBarChartAXDescriptorTests.swift
drinkpulseTests/Features/Onboarding/Components/HealthStepTests.swift
drinkpulseTests/Features/Onboarding/OnboardingViewModelTests.swift
drinkpulseTests/Performance/ScreenComputePerformanceTests.swift
drinkpulseTests/Services/FakeHealthStore.swift
drinkpulseTests/Services/HealthServiceRemoveSampleTests.swift
drinkpulseTests/Services/HealthServiceTests.swift
drinkpulseTests/Services/HealthWriteHooksTests.swift
drinkpulseTests/Services/ReminderServiceTests.swift
drinkpulseTests/Services/WeeklySummaryServiceScheduleTests.swift
drinkpulseTests/Services/WeeklySummaryServiceTests.swift
drinkpulse.xcodeproj/project.pbxproj
drinkpulse.xcodeproj/project.xcworkspace/contents.xcworkspacedata
drinkpulse.xcodeproj/xcshareddata/xcschemes/drinkpulse.xcscheme
```

## Task 2 verification record

- Every assigned non-UI source, test, performance, and tracked Xcode tooling path has a reviewed-file record and an area-level explicit `no-candidate` row.
- S-01 through S-03 record the only concurrency/lifecycle leads as retain-pending-proof; no `externally-blocked` claim is used without affirmative platform evidence.
- The baseline diagnostic classification links its original committed log manifest and external log location without copying health data.
- Phase 08 does not modify service, model, schema, Xcode project, or test code. Any stored-property, export-format, calculation, permission, lifecycle, or system-integration change is substantial and requires the D-09/D-10 owner-brief flow before downstream implementation.
