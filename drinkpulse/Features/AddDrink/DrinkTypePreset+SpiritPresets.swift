import Foundation

extension DrinkTypePreset {

    private nonisolated static let mu: Set<UnitSystem> = [.metric, .usCustomary]
    private nonisolated static let mi: Set<UnitSystem> = [.metric, .imperial]
    private nonisolated static let mui: Set<UnitSystem> = [.metric, .usCustomary, .imperial]

    private nonisolated static let shotVolumes: [VolumeOption] = [
        .init(descriptor: "EU single",    volumeMl: 20, regions: [.metric]),
        .init(descriptor: "Single",       volumeMl: 25, regions: mi),
        .init(descriptor: "Nip",          volumeMl: 30, regions: mu,
              regionNames: [.usCustomary: "Pony"]),
        .init(descriptor: "Irish single", volumeMl: 35, regions: mi),
        .init(descriptor: "Nordic",       volumeMl: 40, regions: [.metric]),
        .init(descriptor: "US shot",      volumeMl: 44, regions: mui,
              regionNames: [.usCustomary: "Shot"]),
        .init(descriptor: "Double",       volumeMl: 50, regions: mi),
        .init(descriptor: "US double",    volumeMl: 59, regions: [.usCustomary],
              regionNames: [.usCustomary: "Neat"]),
        .init(descriptor: "Irish double", volumeMl: 70, regions: mi),
        .init(descriptor: "Triple",       volumeMl: 75, regions: mi),
        .init(descriptor: "Double",       volumeMl: 89, regions: [.usCustomary]),
    ]

    // MARK: - Spirits (generic)

    nonisolated static let spirits = DrinkTypePreset(
        category: .spirits, name: "Spirits", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 50,
        defaultABVIndex: 79
    )

    // MARK: - Brandy

    nonisolated static let brandy = DrinkTypePreset(
        category: .brandy, name: "Brandy", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 40,
        defaultABVIndex: 75
    )

    // MARK: - Cognac

    nonisolated static let cognac = DrinkTypePreset(
        category: .cognac, name: "Cognac", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 40,
        defaultABVIndex: 79
    )

    // MARK: - Vodka

    nonisolated static let vodka = DrinkTypePreset(
        category: .vodka, name: "Vodka", icon: "🍸",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 40,
        defaultABVIndex: 74
    )

    // MARK: - Whiskey

    nonisolated static let whiskey = DrinkTypePreset(
        category: .whiskey, name: "Whiskey", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 40,
        defaultABVIndex: 79
    )

    // MARK: - Tequila

    nonisolated static let tequila = DrinkTypePreset(
        category: .tequila, name: "Tequila", icon: "🌵",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 40,
        defaultABVIndex: 75
    )

    // MARK: - Shot

    nonisolated static let shot = DrinkTypePreset(
        category: .shot, name: "Shot", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 40,
        defaultABVIndex: 79
    )

    // MARK: - Liqueur

    nonisolated static let liqueur = DrinkTypePreset(
        category: .liqueur, name: "Liqueur", icon: "🫗",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 50,
        defaultABVIndex: 39
    )
}
