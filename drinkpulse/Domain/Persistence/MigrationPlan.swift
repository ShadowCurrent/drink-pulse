import Foundation
import SwiftData
import OSLog

private nonisolated let migrationLog = Logger(subsystem: "com.drinkpulse.app", category: "migration")

enum MigrationPlan: SchemaMigrationPlan {
    nonisolated static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]
    }

    nonisolated static var stages: [MigrationStage] {
        [v1ToV2, v2ToV3, v3ToV4]
    }

    nonisolated static let v1ToV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            let events = try context.fetch(FetchDescriptor<SchemaV2.ConsumptionEvent>())
            for event in events {
                event.uuid = UUID()
                event.modifiedDate = event.timestamp
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

    nonisolated static let v2ToV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: nil,
        didMigrate: { context in
            let events = try context.fetch(FetchDescriptor<SchemaV3.ConsumptionEvent>())
            for event in events {
                event.creationDate = event.consumptionDate
            }
            try context.save()
            migrationLog.info(
                "Migrated V2→V3: backfilled creationDate on \(events.count, privacy: .public) events"
            )
        }
    )

    nonisolated static let v3ToV4 = MigrationStage.lightweight(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self
    )
}
