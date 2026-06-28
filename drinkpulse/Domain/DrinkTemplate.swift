import Foundation
import SwiftData

@Model
final class DrinkTemplate {
    /// Stable record identity (plan-0023). NOT `@Attribute(.unique)`; de-dup by
    /// `uuid` lives in app code (`RecordDeduplicator`).
    var uuid: UUID = UUID()

    // Inline defaults on every attribute for CloudKit (plan-0023 / SchemaV2):
    // CloudKit materializes without running `init`.
    var name: String = ""
    var category: DrinkCategory = DrinkCategory.beer
    var defaultVolumeMl: Double = 0
    /// Plain fraction, e.g. 0.05 for 5% ABV.
    var abv: Double = 0
    var icon: String = ""
    var colorHex: String = ""
    var isFavorite: Bool = false
    var isArchived: Bool = false

    /// Last-write-wins clock (plan-0023). Set to `.now` on create and on every edit.
    /// Sentinel inline default; migration backfills, `init` sets `.now`.
    var modifiedDate: Date = Date(timeIntervalSince1970: 0)

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
        self.uuid = UUID()
        self.name = name
        self.category = category
        self.defaultVolumeMl = defaultVolumeMl
        self.abv = abv
        self.icon = icon
        self.colorHex = colorHex
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.modifiedDate = .now
    }

    /// Stamp the LWW clock. Call after any edit to a template's fields.
    func touch() {
        modifiedDate = .now
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
    static var previewChampagne: DrinkTemplate {
        DrinkTemplate(name: "Champagne", category: .champagne, defaultVolumeMl: 125, abv: 0.12,
                      icon: "bubbles.and.sparkles", colorHex: "#F0D060")
    }
    static var previewSpirits: DrinkTemplate {
        DrinkTemplate(name: "Whisky", category: .spirits, defaultVolumeMl: 40, abv: 0.40,
                      icon: "drop.fill", colorHex: "#D4A017")
    }
    static var previewCocktail: DrinkTemplate {
        DrinkTemplate(name: "Mojito", category: .cocktail, defaultVolumeMl: 250, abv: 0.12,
                      icon: "cup.and.saucer.fill", colorHex: "#2ECC71")
    }
    static var previewCider: DrinkTemplate {
        DrinkTemplate(name: "Cider", category: .cider, defaultVolumeMl: 440, abv: 0.05,
                      icon: "apple.logo", colorHex: "#A8D5A2")
    }
}
