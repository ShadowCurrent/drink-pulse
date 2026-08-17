import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    nonisolated static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    nonisolated static var models: [any PersistentModel.Type] {
        [SchemaV1.DrinkTemplate.self, SchemaV1.ConsumptionEvent.self, SchemaV1.UserProfile.self]
    }

    // MARK: - Frozen models (verbatim pre-0023 shape)

    @Model
    final class UserProfile {
        @Attribute(.unique) private(set) var id: String = "singleton"

        var bodyWeightKg: Double
        var biologicalSex: BiologicalSex
        var dateOfBirth: Date?
        var guidelineChoice: GuidelineChoice
        var weeklyGoalGrams: Double
        var unitSystem: UnitSystem
        var currency: String
        var abvPrecisionPermille: Int = 5
        var alcoholUnit: AlcoholUnit = AlcoholUnit.standardDrinks

        init(
            bodyWeightKg: Double = 70.0,
            biologicalSex: BiologicalSex = .male,
            dateOfBirth: Date? = nil,
            guidelineChoice: GuidelineChoice = .who,
            weeklyGoalGrams: Double = 100.0,
            unitSystem: UnitSystem = .metric,
            currency: String = "USD",
            abvPrecisionPermille: Int = 5,
            alcoholUnit: AlcoholUnit = .standardDrinks
        ) {
            self.bodyWeightKg = bodyWeightKg
            self.biologicalSex = biologicalSex
            self.dateOfBirth = dateOfBirth
            self.guidelineChoice = guidelineChoice
            self.weeklyGoalGrams = weeklyGoalGrams
            self.unitSystem = unitSystem
            self.currency = currency
            self.abvPrecisionPermille = abvPrecisionPermille
            self.alcoholUnit = alcoholUnit
        }
    }

    @Model
    final class ConsumptionEvent {
        var timestamp: Date
        var volumeMl: Double
        var abv: Double
        var quantity: Int = 1
        var enteredUnit: UnitSystem?
        var name: String
        var category: DrinkCategory
        var icon: String
        var template: SchemaV1.DrinkTemplate?
        var customName: String?
        var notes: String?
        var price: Double?
        var priceCurrency: String?

        init(
            timestamp: Date = .now,
            volumeMl: Double,
            abv: Double,
            quantity: Int = 1,
            enteredUnit: UnitSystem? = nil,
            name: String,
            category: DrinkCategory,
            icon: String,
            template: SchemaV1.DrinkTemplate? = nil,
            customName: String? = nil,
            notes: String? = nil,
            price: Double? = nil,
            priceCurrency: String? = nil
        ) {
            self.timestamp = timestamp
            self.volumeMl = volumeMl
            self.abv = abv
            self.quantity = quantity
            self.enteredUnit = enteredUnit
            self.name = name
            self.category = category
            self.icon = icon
            self.template = template
            self.customName = customName
            self.notes = notes
            self.price = price
            self.priceCurrency = priceCurrency
        }
    }

    @Model
    final class DrinkTemplate {
        var name: String
        var category: DrinkCategory
        var defaultVolumeMl: Double
        var abv: Double
        var icon: String
        var colorHex: String
        var isFavorite: Bool
        var isArchived: Bool

        @Relationship(deleteRule: .nullify, inverse: \SchemaV1.ConsumptionEvent.template)
        var events: [SchemaV1.ConsumptionEvent] = []

        init(
            name: String,
            category: DrinkCategory,
            defaultVolumeMl: Double,
            abv: Double,
            icon: String,
            colorHex: String,
            isFavorite: Bool = false,
            isArchived: Bool = false
        ) {
            self.name = name
            self.category = category
            self.defaultVolumeMl = defaultVolumeMl
            self.abv = abv
            self.icon = icon
            self.colorHex = colorHex
            self.isFavorite = isFavorite
            self.isArchived = isArchived
        }
    }
}
