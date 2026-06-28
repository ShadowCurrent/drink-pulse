import Foundation
import SwiftData
import OSLog

private nonisolated let migrationLog = Logger(subsystem: "com.drinkpulse.app", category: "migration")

/// The migration plan governing the SwiftData container.
///
/// Carries the frozen `SchemaV1` baseline and the CloudKit-ready `SchemaV2`, with
/// one **custom** V1 → V2 stage (plan-0023). The schema delta itself (inline
/// defaults, drop `@Attribute(.unique)`, remove `ConsumptionEvent.name`, add the
/// `uuid` / `modifiedDate` columns) is lightweight; the custom stage exists to
/// **backfill a distinct `uuid` and a real `modifiedDate` per existing row** —
/// the inline `UUID()` default cannot guarantee per-row distinctness on migrated
/// data.
///
/// Retire-ability (plan-0023): once the only real device is on V2, V1 + this stage
/// may be collapsed into a clean V2 baseline before App Store release. Keep the
/// stage self-contained so that removal is a clean delete.
enum MigrationPlan: SchemaMigrationPlan {
    nonisolated static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    nonisolated static var stages: [MigrationStage] {
        [v1ToV2]
    }

    /// V1 → V2: backfill stable identity + LWW clock on existing rows.
    nonisolated static let v1ToV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            // Events: distinct uuid; LWW clock seeded to the event's own timestamp
            // (its last known mutation instant), not `.now`.
            let events = try context.fetch(FetchDescriptor<ConsumptionEvent>())
            for event in events {
                event.uuid = UUID()
                event.modifiedDate = event.timestamp
            }
            // Templates: distinct uuid; no historical edit instant, so `.now`.
            let templates = try context.fetch(FetchDescriptor<DrinkTemplate>())
            for template in templates {
                template.uuid = UUID()
                template.modifiedDate = .now
            }
            // Profile (singleton, no uuid): seed the LWW clock.
            let profiles = try context.fetch(FetchDescriptor<UserProfile>())
            for profile in profiles {
                profile.modifiedDate = .now
            }
            try context.save()
            migrationLog.info(
                "Migrated V1→V2: backfilled uuid/modifiedDate on \(events.count, privacy: .public) events, \(templates.count, privacy: .public) templates"
            )
        }
    )
}
