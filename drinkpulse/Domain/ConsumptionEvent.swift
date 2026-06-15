import Foundation
import SwiftData

@Model
final class ConsumptionEvent {
    var timestamp: Date
    /// Volume of a **single** portion in millilitres. The number of portions logged
    /// in one entry lives in `quantity` — never fold the count into this value.
    var volumeMl: Double
    /// Plain fraction, e.g. 0.05 for 5% ABV.
    var abv: Double
    /// Number of identical single portions in this one log (e.g. "Bottle ×10").
    /// Defaulted so the SwiftData migration is lightweight on existing stores.
    var quantity: Int = 1

    // Deprecated: snapshot of template name. No longer used for display; derived via
    // displayName from category + volumeMl. Will be removed in plan-0023 (CloudKit migration).
    var name: String
    var category: DrinkCategory
    var icon: String

    var template: DrinkTemplate?

    var customName: String?
    var notes: String?
    var price: Double?

    /// Pure-alcohol mass (g) for a given density, counting every portion:
    /// `volumeMl × quantity × abv × density`. The display layer passes the active
    /// unit's `densityGramsPerMl`; physical figures (calories / BAC) pass 0.789.
    func alcoholGrams(density: Double) -> Double {
        volumeMl * Double(quantity) * abv * density
    }

    /// Physical pure-alcohol mass (scientific 0.789 density). Used for calories and
    /// future BAC — never shifts with the user's chosen display unit.
    var pureAlcoholGrams: Double {
        alcoholGrams(density: AlcoholUnit.physicalDensityGramsPerMl)
    }

    init(
        timestamp: Date = .now,
        volumeMl: Double,
        abv: Double,
        quantity: Int = 1,
        name: String,
        category: DrinkCategory,
        icon: String,
        template: DrinkTemplate? = nil,
        customName: String? = nil,
        notes: String? = nil,
        price: Double? = nil
    ) {
        self.timestamp = timestamp
        self.volumeMl = volumeMl
        self.abv = abv
        self.quantity = quantity
        self.name = name
        self.category = category
        self.icon = icon
        self.template = template
        self.customName = customName
        self.notes = notes
        self.price = price
    }
}

extension ConsumptionEvent {
    /// User-facing name. Resolves the single-portion preset (unambiguous now that
    /// `volumeMl` is per-portion) and appends "×N" when more than one was logged.
    var displayName: String {
        quantity > 1 ? "\(baseName) ×\(quantity)" : baseName
    }

    private var baseName: String {
        if let custom = customName?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            return custom
        }
        let preset = DrinkTypePreset.preset(for: category)
        if let match = preset.volumes.min(by: { abs($0.volumeMl - volumeMl) < abs($1.volumeMl - volumeMl) }) {
            let parts = match.label.components(separatedBy: " · ")
            if parts.count >= 2, let labelPart = parts.first {
                return labelPart.trimmingCharacters(in: .whitespaces)
            }
        }
        return preset.name
    }
}

extension ConsumptionEvent {
    static var previewBeer: ConsumptionEvent {
        ConsumptionEvent(volumeMl: 568, abv: 0.05, name: "Beer", category: .beer, icon: "🍺")
    }
    static var previewWine: ConsumptionEvent {
        let twoHoursAgo = Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now
        return ConsumptionEvent(timestamp: twoHoursAgo, volumeMl: 175, abv: 0.135,
                                name: "Wine", category: .wine, icon: "🍷")
    }
    static var previewSpirits: ConsumptionEvent {
        let priorEvening = Calendar.current.date(byAdding: .hour, value: -20, to: .now) ?? .now
        return ConsumptionEvent(timestamp: priorEvening, volumeMl: 50, abv: 0.40,
                                name: "Whisky", category: .spirits, icon: "🥃")
    }
}
