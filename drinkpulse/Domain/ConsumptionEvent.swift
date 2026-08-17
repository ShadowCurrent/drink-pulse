import Foundation
import SwiftData

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

    var template: DrinkTemplate?

    var customName: String?
    var notes: String?
    var price: Double?
    var priceCurrency: String?

    var modifiedDate: Date = Date(timeIntervalSince1970: 0)

    var healthKitUUID: UUID?

    func alcoholGrams(density: Double) -> Double {
        volumeMl * Double(quantity) * abv * density
    }

    var pureAlcoholGrams: Double {
        alcoholGrams(density: AlcoholUnit.physicalDensityGramsPerMl)
    }

    init(
        consumptionDate: Date = .now,
        volumeMl: Double,
        abv: Double,
        quantity: Int = 1,
        enteredUnit: UnitSystem? = nil,
        category: DrinkCategory,
        icon: String,
        template: DrinkTemplate? = nil,
        customName: String? = nil,
        notes: String? = nil,
        price: Double? = nil,
        priceCurrency: String? = nil,
        creationDate: Date? = nil
    ) {
        self.uuid = UUID()
        self.consumptionDate = consumptionDate
        self.creationDate = creationDate ?? consumptionDate
        self.volumeMl = volumeMl
        self.abv = abv
        self.quantity = quantity
        self.enteredUnit = enteredUnit
        self.category = category
        self.icon = icon
        self.template = template
        self.customName = customName
        self.notes = notes
        self.price = price
        self.priceCurrency = priceCurrency
        self.modifiedDate = .now
    }

    func touch() {
        modifiedDate = .now
    }
}

extension ConsumptionEvent {
    func duplicated(consumptionDate: Date = .now) -> ConsumptionEvent {
        ConsumptionEvent(
            consumptionDate: consumptionDate,
            volumeMl: volumeMl,
            abv: abv,
            quantity: quantity,
            enteredUnit: enteredUnit,
            category: category,
            icon: icon,
            template: template,
            customName: customName,
            notes: notes,
            price: price,
            priceCurrency: priceCurrency
        )
    }
}

extension ConsumptionEvent {
    func displayName(in unitSystem: UnitSystem) -> String {
        let base = baseName(in: unitSystem)
        return quantity > 1 ? "\(base) ×\(quantity)" : base
    }

    private func baseName(in unitSystem: UnitSystem) -> String {
        if let custom = customName?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            return custom
        }
        let resolvedUnit = enteredUnit ?? unitSystem
        let preset = DrinkTypePreset.preset(for: category)
        if let match = preset.volumes.first(where: { abs($0.volumeMl - volumeMl) < 0.5 }) {
            let name = match.name(in: resolvedUnit).trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                return name
            }
        }
        return resolvedUnit.formatVolume(volumeMl)
    }
}

extension ConsumptionEvent {
    static var previewBeer: ConsumptionEvent {
        ConsumptionEvent(volumeMl: 568, abv: 0.05, category: .beer, icon: "🍺")
    }
    static var previewWine: ConsumptionEvent {
        let twoHoursAgo = Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now
        return ConsumptionEvent(consumptionDate: twoHoursAgo, volumeMl: 175, abv: 0.135,
                                category: .wine, icon: "🍷")
    }
    static var previewSpirits: ConsumptionEvent {
        let priorEvening = Calendar.current.date(byAdding: .hour, value: -20, to: .now) ?? .now
        return ConsumptionEvent(consumptionDate: priorEvening, volumeMl: 50, abv: 0.40,
                                category: .spirits, icon: "🥃")
    }
}
