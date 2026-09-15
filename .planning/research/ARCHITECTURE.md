# Architecture Research — v1.4

## Integration points

1. Build baseline: app/unit/UI-test targets and build/test documentation.
2. SwiftUI and design system: existing Tab/NavigationStack/Observation architecture, List identity, sheets, chart annotations and accessibility.
3. Persistence: MigrationPlan and SchemaV1–V4, StoreBootstrap, data-transfer code and model identities.
4. Services and concurrency: HealthKitAdapter, notification scheduling/delegate assignment, startup container work and Sendable boundaries.
5. Verification: existing MigrationTests, DataBackupExportTests, WeeklySummaryServiceScheduleTests, HealthServiceTests and UI suites.

## Recommendations

Keep views owning @Query/modelContext and stateless persistence view models. Audit all layers with a disposition of change/retain/blocked plus official source and evidence; do not require arbitrary rewrites when implementations are already current. A new OS minimum alone is not a reason to mutate shipped model schemas. If a model change proves necessary, add a version/stage and establish fixture-based migration tests before the change.

## Suggested ordering

Baseline and complete inventory → SwiftUI modernization → persistence/services/concurrency modernization → integrated regression and accessibility verification. Phase numbers continue at 08 after the archived Phase 07.

## Sources

- https://developer.apple.com/documentation/SwiftData/SchemaMigrationPlan
- https://developer.apple.com/documentation/SwiftData/VersionedSchema
- https://developer.apple.com/documentation/SwiftData/MigrationStage
- https://developer.apple.com/documentation/Swift/concurrency
- https://developer.apple.com/documentation/UserNotifications/UNUserNotificationCenter

No architecture replacement is required by the sources inspected. Concrete changes are selected during inventory and phase planning.
