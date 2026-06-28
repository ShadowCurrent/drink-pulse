import Foundation
import SwiftData

/// The CloudKit-ready schema (plan-0023).
///
/// V2 is the schema the app runs on today: it references the **live** top-level
/// `@Model` classes (`DrinkTemplate`, `ConsumptionEvent`, `UserProfile`). The
/// shape differs from the frozen `SchemaV1` snapshot in exactly the ways CloudKit
/// and safe backup-restore require:
///
/// - no `@Attribute(.unique)` (singleton enforced in code by `UserProfileStore`);
/// - every attribute has an inline default (CloudKit materializes without `init`);
/// - the deprecated `ConsumptionEvent.name` is removed;
/// - `uuid` stable identity on `ConsumptionEvent` + `DrinkTemplate`;
/// - `modifiedDate` LWW clock on all three models.
///
/// `MigrationStage.custom` (in `MigrationPlan`) migrates V1 → V2, backfilling a
/// distinct `uuid` and a `modifiedDate` per existing row. Written to be
/// retire-able into a clean V2 baseline before App Store release (no external
/// users yet).
enum SchemaV2: VersionedSchema {
    nonisolated static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
    }

    nonisolated static var models: [any PersistentModel.Type] {
        [DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self]
    }
}
