import Foundation
import SwiftData

enum SchemaV5: VersionedSchema {
    nonisolated static var versionIdentifier: Schema.Version {
        Schema.Version(5, 0, 0)
    }

    nonisolated static var models: [any PersistentModel.Type] {
        [DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self]
    }
}
