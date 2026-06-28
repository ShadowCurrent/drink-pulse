import SwiftData

/// The baseline migration plan governing the SwiftData container.
///
/// It carries a single versioned schema (`SchemaV1`) and **no** migration
/// stages yet — V1 is the baseline, so there is nothing to migrate *from*.
/// The plan exists so the container is governed by an explicit plan rather
/// than implicit lightweight inference; plan-0023 adds `SchemaV2` plus one
/// `MigrationStage` for the CloudKit-compat shape changes.
enum MigrationPlan: SchemaMigrationPlan {
    nonisolated static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    nonisolated static var stages: [MigrationStage] {
        []
    }
}
