import SwiftData

/// The first *explicit* versioned schema for the SwiftData store.
///
/// V1 captures the schema exactly as it ships today. It already absorbed the
/// prior *implicit* lightweight migrations that predate explicit versioning
/// (`quantity`, `enteredUnit`, `priceCurrency`, the `ageYears` → `dateOfBirth`
/// swap, and the `alcoholUnit` raw-value retirement); none of those needs a
/// migration stage here because they landed before this baseline.
///
/// Per ADR-0009's snapshot-on-divergence rule, `models` references the **live**
/// `@Model` classes rather than duplicating their definitions. When the first
/// divergent schema lands (plan-0023), that session must copy the then-current
/// model definitions into a frozen V1 namespace *before* editing the live
/// classes as `SchemaV2`.
enum SchemaV1: VersionedSchema {
    nonisolated static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    nonisolated static var models: [any PersistentModel.Type] {
        [DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self]
    }
}
