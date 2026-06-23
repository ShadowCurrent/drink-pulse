import Foundation

extension DrinkTypePreset {

    // All spirit sub-types share the same international shot-size volume list.
    // Region-tag policy as in FermentedPresets: metric = round ml, US = round US
    // fl oz, imperial = round imperial fl oz. The 44 ml US shot is the 1.5 fl oz
    // anchor; native US/imperial servings are added so every unit mode is covered.
    private static let shotVolumes: [VolumeOption] = [
        .init(descriptor: "EU single",     volumeMl: 20, regions: [.metric]),
        .init(descriptor: "Single",        volumeMl: 25, regions: [.metric]),
        .init(descriptor: "Imperial single", volumeMl: 28, regions: [.imperial]),   // 1.0 imperial fl oz
        .init(descriptor: "Nip",           volumeMl: 30, regions: [.metric]),
        .init(descriptor: "Irish single",  volumeMl: 35, regions: [.metric]),
        .init(descriptor: "Nordic",        volumeMl: 40, regions: [.metric]),
        .init(descriptor: "Imperial double", volumeMl: 57, regions: [.imperial]),   // 2.0 imperial fl oz
        .init(descriptor: "US shot",       volumeMl: 44, regions: [.usCustomary]),  // 1.5 US fl oz
        .init(descriptor: "Double",        volumeMl: 50, regions: [.metric]),
        .init(descriptor: "US double",     volumeMl: 59, regions: [.usCustomary]),  // 2.0 US fl oz
        .init(descriptor: "Irish double",  volumeMl: 70, regions: [.metric]),
        .init(descriptor: "Triple",        volumeMl: 75, regions: [.metric]),
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
