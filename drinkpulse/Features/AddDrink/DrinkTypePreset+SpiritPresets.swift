import Foundation

extension DrinkTypePreset {

    // All spirit sub-types share the same international shot-size volume list.
    private static let shotVolumes: [VolumeOption] = [
        .init(label: "EU single · 20 ml",   volumeMl: 20),
        .init(label: "Single · 25 ml",       volumeMl: 25),
        .init(label: "Nip · 30 ml",          volumeMl: 30),
        .init(label: "Irish single · 35 ml", volumeMl: 35),
        .init(label: "Nordic · 40 ml",       volumeMl: 40),  // index 4
        .init(label: "US shot · 44 ml",      volumeMl: 44),
        .init(label: "Double · 50 ml",       volumeMl: 50),  // index 6
        .init(label: "US double · 60 ml",    volumeMl: 60),
        .init(label: "Irish double · 70 ml", volumeMl: 70),
        .init(label: "Triple · 75 ml",       volumeMl: 75),
    ]

    // MARK: - Spirits (generic)

    static let spirits = DrinkTypePreset(
        category: .spirits, name: "Spirits", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeIndex: 6,   // Double 50 ml
        defaultABVIndex: 79      // 40.0 %
    )

    // MARK: - Brandy

    static let brandy = DrinkTypePreset(
        category: .brandy, name: "Brandy", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeIndex: 4,   // Nordic 40 ml
        defaultABVIndex: 75      // 38.0 %
    )

    // MARK: - Cognac

    static let cognac = DrinkTypePreset(
        category: .cognac, name: "Cognac", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeIndex: 4,   // Nordic 40 ml
        defaultABVIndex: 79      // 40.0 %
    )

    // MARK: - Vodka

    static let vodka = DrinkTypePreset(
        category: .vodka, name: "Vodka", icon: "🍸",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeIndex: 4,   // Nordic 40 ml
        defaultABVIndex: 74      // 37.5 %
    )

    // MARK: - Whiskey

    static let whiskey = DrinkTypePreset(
        category: .whiskey, name: "Whiskey", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeIndex: 4,   // Nordic 40 ml
        defaultABVIndex: 79      // 40.0 %
    )

    // MARK: - Tequila

    static let tequila = DrinkTypePreset(
        category: .tequila, name: "Tequila", icon: "🌵",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeIndex: 4,   // Nordic 40 ml
        defaultABVIndex: 75      // 38.0 %
    )

    // MARK: - Shot

    static let shot = DrinkTypePreset(
        category: .shot, name: "Shot", icon: "🥃",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeIndex: 4,   // Nordic 40 ml
        defaultABVIndex: 79      // 40.0 %
    )

    // MARK: - Liqueur

    static let liqueur = DrinkTypePreset(
        category: .liqueur, name: "Liqueur", icon: "🫗",
        volumes: shotVolumes,
        abvValues: fullAbvRange,
        defaultVolumeIndex: 6,   // Double 50 ml
        defaultABVIndex: 39      // 20.0 %
    )
}
