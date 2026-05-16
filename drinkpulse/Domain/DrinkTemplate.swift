import Foundation
import SwiftData

enum DrinkCategory: String, Codable, CaseIterable, Sendable {
    case beer, wine, spirits, cocktail, custom
}

@Model
final class DrinkTemplate {
    var name: String
    var category: DrinkCategory
    var defaultVolumeMl: Double
    /// Plain fraction, e.g. 0.05 for 5% ABV.
    var abv: Double
    var icon: String
    var colorHex: String
    var isFavorite: Bool
    var isArchived: Bool

    @Relationship(deleteRule: .nullify, inverse: \ConsumptionEvent.template)
    var events: [ConsumptionEvent] = []

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

extension DrinkTemplate {
    static var previewBeer: DrinkTemplate {
        DrinkTemplate(name: "Lager", category: .beer, defaultVolumeMl: 500, abv: 0.05,
                      icon: "mug.fill", colorHex: "#F5A623")
    }
    static var previewWine: DrinkTemplate {
        DrinkTemplate(name: "Red Wine", category: .wine, defaultVolumeMl: 150, abv: 0.135,
                      icon: "wineglass.fill", colorHex: "#8B0000")
    }
    static var previewSpirits: DrinkTemplate {
        DrinkTemplate(name: "Whisky", category: .spirits, defaultVolumeMl: 40, abv: 0.40,
                      icon: "drop.fill", colorHex: "#D4A017")
    }
    static var previewCocktail: DrinkTemplate {
        DrinkTemplate(name: "Mojito", category: .cocktail, defaultVolumeMl: 250, abv: 0.12,
                      icon: "cup.and.saucer.fill", colorHex: "#2ECC71")
    }
}
