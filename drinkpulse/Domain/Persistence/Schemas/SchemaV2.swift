import Foundation
import SwiftData

/// The CloudKit-ready schema as **originally shipped** (plan-0023 Phase A) — now
/// **frozen**.
///
/// V2 differs from V1: no `@Attribute(.unique)`, inline defaults on every
/// attribute, the deprecated `ConsumptionEvent.name` removed, and stable `uuid`
/// + `modifiedDate` added. It still uses the field name **`timestamp`** and has
/// **no `creationDate`** — those changes are V3.
///
/// Per ADR-0009's snapshot-on-divergence rule, this is the verbatim copy of the
/// model definitions as they shipped at commit `bc471f7`, frozen here when the
/// live classes diverged into `SchemaV3` (the `timestamp` → `consumptionDate`
/// rename + `creationDate`). The structure must stay byte-for-schema-identical to
/// the shipped V2 so its version hash matches stores already migrated to V2 —
/// **do not edit**.
enum SchemaV2: VersionedSchema {
    nonisolated static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
    }

    nonisolated static var models: [any PersistentModel.Type] {
        [SchemaV2.DrinkTemplate.self, SchemaV2.ConsumptionEvent.self, SchemaV2.UserProfile.self]
    }

    // MARK: - Frozen models (verbatim shipped-V2 shape)

    @Model
    final class UserProfile {
        private(set) var id: String = "singleton"
        var bodyWeightKg: Double = 0
        var biologicalSex: BiologicalSex = BiologicalSex.male
        var dateOfBirth: Date?
        var guidelineChoice: GuidelineChoice = GuidelineChoice.who
        var weeklyGoalGrams: Double = 0
        var unitSystem: UnitSystem = UnitSystem.metric
        var currency: String = ""
        var abvPrecisionPermille: Int = 5
        var alcoholUnit: AlcoholUnit = AlcoholUnit.standardDrinks
        var modifiedDate: Date = Date(timeIntervalSince1970: 0)

        init() {}
    }

    @Model
    final class ConsumptionEvent {
        var uuid: UUID = UUID()
        var timestamp: Date = Date(timeIntervalSince1970: 0)
        var volumeMl: Double = 0
        var abv: Double = 0
        var quantity: Int = 1
        var enteredUnit: UnitSystem?
        var category: DrinkCategory = DrinkCategory.beer
        var icon: String = ""
        var template: SchemaV2.DrinkTemplate?
        var customName: String?
        var notes: String?
        var price: Double?
        var priceCurrency: String?
        var modifiedDate: Date = Date(timeIntervalSince1970: 0)

        init() {}
    }

    @Model
    final class DrinkTemplate {
        var uuid: UUID = UUID()
        var name: String = ""
        var category: DrinkCategory = DrinkCategory.beer
        var defaultVolumeMl: Double = 0
        var abv: Double = 0
        var icon: String = ""
        var colorHex: String = ""
        var isFavorite: Bool = false
        var isArchived: Bool = false
        var modifiedDate: Date = Date(timeIntervalSince1970: 0)

        @Relationship(deleteRule: .nullify, inverse: \SchemaV2.ConsumptionEvent.template)
        var events: [SchemaV2.ConsumptionEvent] = []

        init() {}
    }
}
