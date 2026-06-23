import Foundation

extension DrinkTypePreset {

    // All spirit sub-types share the same international shot-size volume list.
    // Region-tag policy (plan-0031, see FermentedPresets / domain.md): UK pub
    // measures are tagged imperial as real (non-round) oz measures (M-tier), the
    // US 1.5 oz shot is cross-borrowed into imperial AND metric (X-tier), and
    // three options carry per-region names (Nip→Pony, US shot→Shot, US double→
    // Neat in US). Coverage invariant holds: ≥1 entry per unit system.
    private static let mu: Set<UnitSystem> = [.metric, .usCustomary]
    private static let mi: Set<UnitSystem> = [.metric, .imperial]
    private static let mui: Set<UnitSystem> = [.metric, .usCustomary, .imperial]

    private static let shotVolumes: [VolumeOption] = [
        .init(descriptor: "EU single",    volumeMl: 20, regions: [.metric]),
        .init(descriptor: "Single",       volumeMl: 25, regions: mi),    // 0.9 oz UK single
        .init(descriptor: "Nip",          volumeMl: 30, regions: mu,     // 1 oz / Pony (US)
              regionNames: [.usCustomary: "Pony"]),
        .init(descriptor: "Irish single", volumeMl: 35, regions: mi),    // 1.2 oz UK measure
        .init(descriptor: "Nordic",       volumeMl: 40, regions: [.metric]),
        .init(descriptor: "US shot",      volumeMl: 44, regions: mui,    // 1.5 oz / Shot (US)
              regionNames: [.usCustomary: "Shot"]),
        .init(descriptor: "Double",       volumeMl: 50, regions: mi),    // 1.8 oz UK double
        .init(descriptor: "US double",    volumeMl: 59, regions: [.usCustomary],  // 2 oz / Neat (US)
              regionNames: [.usCustomary: "Neat"]),
        .init(descriptor: "Irish double", volumeMl: 70, regions: mi),    // 2.5 oz UK measure
        .init(descriptor: "Triple",       volumeMl: 75, regions: mi),    // 2.6 imp oz
        .init(descriptor: "Double",       volumeMl: 89, regions: [.usCustomary]), // 3 oz US double
    ]

    // MARK: - Spirits (generic)

    static let spirits = DrinkTypePreset(
        category: .spirits, name: "Spirits", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 50,     // Double (metric)
        defaultABVIndex: 79      // 40.0 %
    )

    // MARK: - Brandy

    static let brandy = DrinkTypePreset(
        category: .brandy, name: "Brandy", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 40,     // Nordic (metric)
        defaultABVIndex: 75      // 38.0 %
    )

    // MARK: - Cognac

    static let cognac = DrinkTypePreset(
        category: .cognac, name: "Cognac", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 40,     // Nordic (metric)
        defaultABVIndex: 79      // 40.0 %
    )

    // MARK: - Vodka

    static let vodka = DrinkTypePreset(
        category: .vodka, name: "Vodka", icon: "🍸",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 40,     // Nordic (metric)
        defaultABVIndex: 74      // 37.5 %
    )

    // MARK: - Whiskey

    static let whiskey = DrinkTypePreset(
        category: .whiskey, name: "Whiskey", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 40,     // Nordic (metric)
        defaultABVIndex: 79      // 40.0 %
    )

    // MARK: - Tequila

    static let tequila = DrinkTypePreset(
        category: .tequila, name: "Tequila", icon: "🌵",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 40,     // Nordic (metric)
        defaultABVIndex: 75      // 38.0 %
    )

    // MARK: - Shot

    static let shot = DrinkTypePreset(
        category: .shot, name: "Shot", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 40,     // Nordic (metric)
        defaultABVIndex: 79      // 40.0 %
    )

    // MARK: - Liqueur

    static let liqueur = DrinkTypePreset(
        category: .liqueur, name: "Liqueur", icon: "🫗",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeMl: 50,     // Double (metric)
        defaultABVIndex: 39      // 20.0 %
    )
}
