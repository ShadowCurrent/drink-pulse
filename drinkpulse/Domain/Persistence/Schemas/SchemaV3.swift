import Foundation
import SwiftData

/// The schema as shipped after the `timestamp` → `consumptionDate` rename +
/// `creationDate` addition (plan-0023 follow-up) — now **frozen**.
///
/// V3 differs from `SchemaV2` only on `ConsumptionEvent`: `timestamp` renamed to
/// **`consumptionDate`** (via `@Attribute(originalName: "timestamp")`, so the
/// existing column maps over) and a new non-optional **`creationDate`**.
/// `UserProfile` / `DrinkTemplate` are unchanged from V2.
///
/// Per ADR-0009's snapshot-on-divergence rule, this is now a self-contained copy
/// of the model definitions as they shipped at V3 — frozen here when the live
/// classes diverged into `SchemaV4` (plan-0036: add `ConsumptionEvent.healthKitUUID`).
/// The structure must stay schema-identical to the shipped V3 so its version hash
/// matches stores already on V3 — **do not edit**.
enum SchemaV3: VersionedSchema {
    nonisolated static var versionIdentifier: Schema.Version {
        Schema.Version(3, 0, 0)
    }

    nonisolated static var models: [any PersistentModel.Type] {
        [SchemaV3.DrinkTemplate.self, SchemaV3.ConsumptionEvent.self, SchemaV3.UserProfile.self]
    }

    // MARK: - Frozen models (verbatim shipped-V3 shape)

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
        @Attribute(originalName: "timestamp")
        var consumptionDate: Date = Date(timeIntervalSince1970: 0)
        var creationDate: Date = Date(timeIntervalSince1970: 0)
        var volumeMl: Double = 0
        var abv: Double = 0
        var quantity: Int = 1
        var enteredUnit: UnitSystem?
        var category: DrinkCategory = DrinkCategory.beer
        var icon: String = ""
        var template: SchemaV3.DrinkTemplate?
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

        @Relationship(deleteRule: .nullify, inverse: \SchemaV3.ConsumptionEvent.template)
        var events: [SchemaV3.ConsumptionEvent] = []

        init() {}
    }
}
