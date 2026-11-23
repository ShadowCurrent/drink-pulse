import Foundation

/// The families the Add Drink type list is sectioned into (plan 0047, D0047-1). `.cognac` is not
/// listed: it shares the "Brandy & Cognac" row with `.brandy` (D0047-2) but stays a category so
/// existing events keep resolving.
enum DrinkTypeGroup: CaseIterable {
    case beerCider, wine, spirits, mixed

    var title: String {
        switch self {
        case .beerCider: String(localized: "addDrink.section.beerCider")
        case .wine: String(localized: "addDrink.section.wine")
        case .spirits: String(localized: "addDrink.section.spirits")
        case .mixed: String(localized: "addDrink.section.mixed")
        }
    }

    var presets: [DrinkTypePreset] {
        switch self {
        case .beerCider: [.beer, .cider]
        case .wine: [.wine, .champagne, .fortifiedWine]
        case .spirits: [.vodka, .whiskey, .tequila, .brandy, .spirits, .liqueur, .shot]
        case .mixed: [.cocktail, .alcopop, .hotDrink, .custom]
        }
    }

    /// The group's presets whose name contains `query` (case- and diacritic-insensitive, locale
    /// aware). A blank query matches everything.
    func presets(matching query: String) -> [DrinkTypePreset] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return presets }
        return presets.filter { $0.name.localizedStandardContains(trimmed) }
    }

    /// The category whose row represents `category` in the list: `.cognac` is shown as the
    /// Brandy & Cognac row, every other category as itself.
    static func pickerCategory(for category: DrinkCategory) -> DrinkCategory {
        category == .cognac ? .brandy : category
    }
}
