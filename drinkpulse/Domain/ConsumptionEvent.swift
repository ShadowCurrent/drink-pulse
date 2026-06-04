import Foundation
import SwiftData

@Model
final class ConsumptionEvent {
    var timestamp: Date
    var volumeMl: Double
    /// Plain fraction, e.g. 0.05 for 5% ABV.
    var abv: Double

    // Deprecated: snapshot of template name. No longer used for display; derived via
    // displayName from category + volumeMl. Will be removed in plan-0023 (CloudKit migration).
    var name: String
    var category: DrinkCategory
    var icon: String

    var template: DrinkTemplate?

    var customName: String?
    var notes: String?
    var price: Double?

    var pureAlcoholGrams: Double {
        volumeMl * abv * 0.8
    }

    init(
        timestamp: Date = .now,
        volumeMl: Double,
        abv: Double,
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
    var displayName: String {
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
