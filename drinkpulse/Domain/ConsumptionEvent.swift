import Foundation
import SwiftData

@Model
final class ConsumptionEvent {
    var timestamp: Date
    var volumeMl: Double
    /// Plain fraction, e.g. 0.05 for 5% ABV.
    var abv: Double

    // Snapshot of template fields captured at log time — never mutated after insert.
    var name: String
    var category: DrinkCategory
    var icon: String

    var template: DrinkTemplate?

    var notes: String?
    var location: String?
    var price: Double?

    var pureAlcoholGrams: Double {
        volumeMl * abv * 0.789
    }

    init(
        timestamp: Date = .now,
        volumeMl: Double,
        abv: Double,
        name: String,
        category: DrinkCategory,
        icon: String,
        template: DrinkTemplate? = nil,
        notes: String? = nil,
        location: String? = nil,
        price: Double? = nil
    ) {
        self.timestamp = timestamp
        self.volumeMl = volumeMl
        self.abv = abv
        self.name = name
        self.category = category
        self.icon = icon
        self.template = template
        self.notes = notes
        self.location = location
        self.price = price
    }
}

extension ConsumptionEvent {
    static var previewBeer: ConsumptionEvent {
        ConsumptionEvent(volumeMl: 568, abv: 0.05, name: "Beer", category: .beer, icon: "mug.fill")
    }
    static var previewWine: ConsumptionEvent {
        let twoHoursAgo = Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now
        return ConsumptionEvent(timestamp: twoHoursAgo, volumeMl: 175, abv: 0.135,
                                name: "Wine", category: .wine, icon: "wineglass.fill")
    }
    static var previewSpirits: ConsumptionEvent {
        let priorEvening = Calendar.current.date(byAdding: .hour, value: -20, to: .now) ?? .now
        return ConsumptionEvent(timestamp: priorEvening, volumeMl: 50, abv: 0.40,
                                name: "Whisky", category: .spirits, icon: "drop.fill")
    }
}
