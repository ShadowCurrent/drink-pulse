import Foundation

// Cocktail / fortified wine / hot drink presets. Split out of
// DrinkTypePreset+FermentedPresets.swift to keep both files under the 300-line
// ceiling (plan-0031 expanded the serving inventory). Region-tag policy and the
// inline-ml-hint behaviour are documented in FermentedPresets.swift / domain.md.
extension DrinkTypePreset {

    private static let m: Set<UnitSystem> = [.metric]
    private static let u: Set<UnitSystem> = [.usCustomary]
    private static let i: Set<UnitSystem> = [.imperial]
    private static let mi: Set<UnitSystem> = [.metric, .imperial]

    // MARK: - Cocktail

    static let cocktail = DrinkTypePreset(
        category: .cocktail, name: "Cocktail", icon: "🍹",
        volumes: [
            .init(descriptor: "Short",        volumeMl: 100, regions: m),
            .init(descriptor: "Coupe",        volumeMl: 114, regions: i),   // 4 oz
            .init(descriptor: "Coupe",        volumeMl: 118, regions: u),   // 4 oz
            .init(descriptor: "Small",        volumeMl: 125, regions: m),
            .init(descriptor: "Martini",      volumeMl: 142, regions: i),   // 5 oz
            .init(descriptor: "Martini",      volumeMl: 148, regions: u),   // 5 oz
            .init(descriptor: "Medium",       volumeMl: 150, regions: m),
            .init(descriptor: "Rocks",        volumeMl: 170, regions: i),   // 6 oz
            .init(descriptor: "Rocks",        volumeMl: 177, regions: u),   // 6 oz
            .init(descriptor: "Long",         volumeMl: 200, regions: m),
            .init(descriptor: "Highball",     volumeMl: 227, regions: i),   // 8 oz
            .init(descriptor: "Highball",     volumeMl: 237, regions: u),   // 8 oz
            .init(descriptor: "Tall",         volumeMl: 250, regions: m),
            .init(descriptor: "Collins",      volumeMl: 284, regions: i),   // 10 oz
            .init(descriptor: "Collins",      volumeMl: 296, regions: u),   // 10 oz
            .init(descriptor: "XL",           volumeMl: 300, regions: m),
            .init(descriptor: "Large",        volumeMl: 341, regions: i),   // 12 oz
            .init(descriptor: "Tiki",         volumeMl: 355, regions: u),   // 12 oz
            .init(descriptor: "Pitcher pour", volumeMl: 473, regions: u),   // 16 oz
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 200,    // Long (metric)
        defaultABVIndex: 29      // 15.0 %
    )

    // MARK: - Fortified wine

    static let fortifiedWine = DrinkTypePreset(
        category: .fortifiedWine, name: "Fortified", icon: "🍾",
        volumes: [
            .init(descriptor: "Small",    volumeMl: 44, regions: u),     // 1.5 oz
            .init(descriptor: "Standard", volumeMl: 50, regions: mi,     // 1.8 oz UK Sherry measure
                  regionNames: [.imperial: "Sherry"]),
            .init(descriptor: "Pour",     volumeMl: 59, regions: u),     // 2 oz
            .init(descriptor: "Large",    volumeMl: 60, regions: mi),    // 2.1 imp oz
            .init(descriptor: "Aperitif", volumeMl: 75, regions: mi),    // 2.6 oz UK measure
            .init(descriptor: "Port",     volumeMl: 89, regions: u),     // 3 oz
            .init(descriptor: "Vermouth", volumeMl: 100, regions: mi),   // 3.5 oz UK measure
            .init(descriptor: "Aperitif", volumeMl: 118, regions: u),    // 4 oz
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 75,     // Aperitif (metric)
        defaultABVIndex: 35      // 18.0 %
    )

    // MARK: - Hot drink

    static let hotDrink = DrinkTypePreset(
        category: .hotDrink, name: "Hot drink", icon: "☕",
        volumes: [
            .init(descriptor: "Toddy",     volumeMl: 142, regions: i),   // 5 oz
            .init(descriptor: "Toddy",     volumeMl: 148, regions: u),   // 5 oz
            .init(descriptor: "Toddy",     volumeMl: 150, regions: m),
            .init(descriptor: "Mug",       volumeMl: 200, regions: m),
            .init(descriptor: "Mug",       volumeMl: 227, regions: i),   // 8 oz
            .init(descriptor: "Mug",       volumeMl: 237, regions: u),   // 8 oz
            .init(descriptor: "Mulled",    volumeMl: 250, regions: mi),  // 8.8 imp oz
            .init(descriptor: "Large mug", volumeMl: 284, regions: i),   // 10 oz
            .init(descriptor: "Large mug", volumeMl: 296, regions: u),   // 10 oz
            .init(descriptor: "Large",     volumeMl: 300, regions: mi),  // 10.6 imp oz
            .init(descriptor: "Tankard",   volumeMl: 341, regions: i),   // 12 oz
            .init(descriptor: "Tankard",   volumeMl: 355, regions: u),   // 12 oz
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 200,    // Mug (metric)
        defaultABVIndex: 23      // 12.0 %
    )
}
