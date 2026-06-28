import Foundation
import SwiftData
import OSLog

private nonisolated let migrationLog = Logger(subsystem: "com.drinkpulse.app", category: "migration")

/// The migration plan governing the SwiftData container.
///
/// Versions: `SchemaV1` (original), `SchemaV2` (CloudKit-ready: identity + LWW),
/// `SchemaV3` (current: `timestamp` → `consumptionDate`, add `creationDate`).
///
/// Stages:
/// - **v1→v2** (custom): backfill a distinct `uuid` + a `modifiedDate` per row. It
///   fetches the **`SchemaV2` snapshot types** — the stage's destination — *not*
///   the live classes (which are now V3), or the fetch would hydrate against the
///   wrong shape.
/// - **v2→v3** (custom): backfill `creationDate` from `consumptionDate`. This is
///   the final stage, so its destination (V3) *is* the live class set — it fetches
///   the live `ConsumptionEvent`.
///
/// Pre-launch retire-ability: once every real store is on V3, V1/V2 + both stages
/// may be collapsed into a clean V3 baseline before App Store release.
enum MigrationPlan: SchemaMigrationPlan {
    nonisolated static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }

    nonisolated static var stages: [MigrationStage] {
        [v1ToV2, v2ToV3]
    }

    /// V1 → V2: stable identity + LWW clock on existing rows.
    nonisolated static let v1ToV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            // Fetch the V2 snapshot types (this stage's destination shape).
            let events = try context.fetch(FetchDescriptor<SchemaV2.ConsumptionEvent>())
            for event in events {
                event.uuid = UUID()
                event.modifiedDate = event.timestamp   // last known mutation instant
            }
            let templates = try context.fetch(FetchDescriptor<SchemaV2.DrinkTemplate>())
            for template in templates {
                template.uuid = UUID()
                template.modifiedDate = .now
            }
            let profiles = try context.fetch(FetchDescriptor<SchemaV2.UserProfile>())
            for profile in profiles {
                profile.modifiedDate = .now
            }
            try context.save()
            migrationLog.info(
                "Migrated V1→V2: identity/clock on \(events.count, privacy: .public) events, \(templates.count, privacy: .public) templates"
            )
        }
    )

    /// V2 → V3: the `timestamp` → `consumptionDate` rename is handled by the
    /// `@Attribute(originalName:)` mapping; this stage backfills the new
    /// non-optional `creationDate` from each event's `consumptionDate`.
    nonisolated static let v2ToV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: nil,
        didMigrate: { context in
            // Final stage: destination V3 == the live classes.
            let events = try context.fetch(FetchDescriptor<ConsumptionEvent>())
            for event in events {
                event.creationDate = event.consumptionDate
            }
            try context.save()
            migrationLog.info(
                "Migrated V2→V3: backfilled creationDate on \(events.count, privacy: .public) events"
            )
        }
    )
}
