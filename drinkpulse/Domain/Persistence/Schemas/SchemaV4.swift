import Foundation
import SwiftData

/// The current live schema (plan-0036).
///
/// V4 references the **live** top-level `@Model` classes. It differs from the
/// frozen `SchemaV3` only on `ConsumptionEvent`: a new optional, device-local
/// **`healthKitUUID: UUID?`** (Apple Health write-back). Purely additive — the
/// new property is optional with no inline default required, so the `v3ToV4`
/// stage is lightweight (existing rows get `nil`). `UserProfile` / `DrinkTemplate`
/// are unchanged from V3.
///
/// `healthKitUUID` is intentionally NOT exported and NOT synced (see ADR-0011).
enum SchemaV4: VersionedSchema {
    nonisolated static var versionIdentifier: Schema.Version {
        Schema.Version(4, 0, 0)
    }

    nonisolated static var models: [any PersistentModel.Type] {
        [DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self]
    }
}
