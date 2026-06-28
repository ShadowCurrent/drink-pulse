import Foundation
import SwiftData

/// The current live schema (plan-0023 follow-up).
///
/// V3 references the **live** top-level `@Model` classes. It differs from the
/// frozen `SchemaV2` only on `ConsumptionEvent`:
/// - `timestamp` renamed to **`consumptionDate`** (via `@Attribute(originalName:
///   "timestamp")`, so the existing column maps over with no data loss);
/// - a new non-optional **`creationDate`**.
///
/// `MigrationStage` `v2ToV3` (in `MigrationPlan`) backfills `creationDate` from
/// `consumptionDate` on existing rows. `UserProfile` / `DrinkTemplate` are
/// unchanged from V2.
enum SchemaV3: VersionedSchema {
    nonisolated static var versionIdentifier: Schema.Version {
        Schema.Version(3, 0, 0)
    }

    nonisolated static var models: [any PersistentModel.Type] {
        [DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self]
    }
}
