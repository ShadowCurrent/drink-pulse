import Foundation

extension DrinkTypePreset {

    private nonisolated static let m: Set<UnitSystem> = [.metric]
    private nonisolated static let u: Set<UnitSystem> = [.usCustomary]
    private nonisolated static let i: Set<UnitSystem> = [.imperial]
    private nonisolated static let mi: Set<UnitSystem> = [.metric, .imperial]

    // MARK: - Cocktail

    nonisolated static let cocktail = DrinkTypePreset(
        category: .cocktail, name: "Cocktail", icon: "🍹",
        volumes: [
            .init(descriptor: "Short",        volumeMl: 100, regions: m),
            .init(descriptor: "Coupe",        volumeMl: 114, regions: i),
            .init(descriptor: "Coupe",        volumeMl: 118, regions: u),
            .init(descriptor: "Small",        volumeMl: 125, regions: m),
            .init(descriptor: "Martini",      volumeMl: 142, regions: i),
            .init(descriptor: "Martini",      volumeMl: 148, regions: u),
            .init(descriptor: "Medium",       volumeMl: 150, regions: m),
            .init(descriptor: "Rocks",        volumeMl: 170, regions: i),
            .init(descriptor: "Rocks",        volumeMl: 177, regions: u),
            .init(descriptor: "Long",         volumeMl: 200, regions: m),
            .init(descriptor: "Highball",     volumeMl: 227, regions: i),
            .init(descriptor: "Highball",     volumeMl: 237, regions: u),
            .init(descriptor: "Tall",         volumeMl: 250, regions: m),
            .init(descriptor: "Collins",      volumeMl: 284, regions: i),
            .init(descriptor: "Collins",      volumeMl: 296, regions: u),
            .init(descriptor: "XL",           volumeMl: 300, regions: m),
            .init(descriptor: "Large",        volumeMl: 341, regions: i),
            .init(descriptor: "Tiki",         volumeMl: 355, regions: u),
            .init(descriptor: "Pitcher pour", volumeMl: 473, regions: u),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 200,
        defaultABVIndex: 29
    )

    // MARK: - Fortified wine

    nonisolated static let fortifiedWine = DrinkTypePreset(
        category: .fortifiedWine, name: "Fortified", icon: "🍾",
        volumes: [
            .init(descriptor: "Small",    volumeMl: 44, regions: u),
            .init(descriptor: "Standard", volumeMl: 50, regions: mi,
                  regionNames: [.imperial: "Sherry"]),
            .init(descriptor: "Pour",     volumeMl: 59, regions: u),
            .init(descriptor: "Large",    volumeMl: 60, regions: mi),
            .init(descriptor: "Aperitif", volumeMl: 75, regions: mi),
            .init(descriptor: "Port",     volumeMl: 89, regions: u),
            .init(descriptor: "Vermouth", volumeMl: 100, regions: mi),
            .init(descriptor: "Aperitif", volumeMl: 118, regions: u),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 75,
        defaultABVIndex: 35
    )

    // MARK: - Hot drink

    nonisolated static let hotDrink = DrinkTypePreset(
        category: .hotDrink, name: "Hot drink", icon: "☕",
        volumes: [
            .init(descriptor: "Toddy",     volumeMl: 142, regions: i),
            .init(descriptor: "Toddy",     volumeMl: 148, regions: u),
            .init(descriptor: "Toddy",     volumeMl: 150, regions: m),
            .init(descriptor: "Mug",       volumeMl: 200, regions: m),
            .init(descriptor: "Mug",       volumeMl: 227, regions: i),
            .init(descriptor: "Mug",       volumeMl: 237, regions: u),
            .init(descriptor: "Mulled",    volumeMl: 250, regions: mi),
            .init(descriptor: "Large mug", volumeMl: 284, regions: i),
            .init(descriptor: "Large mug", volumeMl: 296, regions: u),
            .init(descriptor: "Large",     volumeMl: 300, regions: mi),
            .init(descriptor: "Tankard",   volumeMl: 341, regions: i),
            .init(descriptor: "Tankard",   volumeMl: 355, regions: u),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 200,
        defaultABVIndex: 23
    )
}
