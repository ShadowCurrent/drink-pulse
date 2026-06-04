import Foundation

extension DrinkTypePreset {

    // All presets share the same wide ABV range (0.5 % – 100 %) so any drink
    // strength is selectable. Type-specific defaults are set via defaultABVIndex.
    // Index formula for step-5 range: index = (permille / 5) – 1
    // e.g. 5.0 % = 50 permille → index 9; 40.0 % = 400 permille → index 79.
    static let fullAbvRange = abvRange(from: 5, through: 1000)  // 0.5 – 100.0 %

    // MARK: - Beer

    static let beer = DrinkTypePreset(
        category: .beer, name: "Beer", icon: "🍺",
        volumes: [
            .init(label: "Stange · 200 ml",       volumeMl: 200),
            .init(label: "Small glass · 250 ml",  volumeMl: 250),
            .init(label: "Half-pint UK · 284 ml", volumeMl: 284),
            .init(label: "Pot AU · 285 ml",       volumeMl: 285),
            .init(label: "0.3 L · 300 ml",        volumeMl: 300),
            .init(label: "Can · 330 ml",          volumeMl: 330),
            .init(label: "US can · 355 ml",       volumeMl: 355),
            .init(label: "0.4 L · 400 ml",        volumeMl: 400),
            .init(label: "Schooner AU · 425 ml",  volumeMl: 425),
            .init(label: "Big can · 440 ml",      volumeMl: 440),
            .init(label: "US pint · 473 ml",      volumeMl: 473),
            .init(label: "Bottle · 500 ml",       volumeMl: 500),
            .init(label: "Pint UK · 568 ml",      volumeMl: 568),
            .init(label: "Large bottle · 660 ml", volumeMl: 660),
            .init(label: "Bomber · 750 ml",       volumeMl: 750),
            .init(label: "Mug · 1 L",             volumeMl: 1000),
        ],
        abvValues: fullAbvRange,
        defaultVolumeIndex: 11,  // Bottle 500 ml
        defaultABVIndex: 9       // 5.0 %
    )

    // MARK: - Wine

    static let wine = DrinkTypePreset(
        category: .wine, name: "Wine", icon: "🍷",
        volumes: [
            .init(label: "Tasting · 100 ml",  volumeMl: 100),
            .init(label: "Small · 125 ml",    volumeMl: 125),
            .init(label: "US pour · 148 ml",  volumeMl: 148),
            .init(label: "Standard · 150 ml", volumeMl: 150),
            .init(label: "Medium · 175 ml",   volumeMl: 175),
            .init(label: "Large · 250 ml",    volumeMl: 250),
            .init(label: "Half btl · 375 ml", volumeMl: 375),
            .init(label: "Carafe · 500 ml",   volumeMl: 500),
            .init(label: "Bottle · 750 ml",   volumeMl: 750),
        ],
        abvValues: fullAbvRange,
        defaultVolumeIndex: 3,   // Standard 150 ml
        defaultABVIndex: 24      // 12.5 %
    )

    // MARK: - Champagne

    static let champagne = DrinkTypePreset(
        category: .champagne, name: "Champagne", icon: "🥂",
        volumes: [
            .init(label: "Toast · 100 ml",  volumeMl: 100),
            .init(label: "Flute · 125 ml",  volumeMl: 125),
            .init(label: "Large · 150 ml",  volumeMl: 150),
            .init(label: "Coupe · 180 ml",  volumeMl: 180),
            .init(label: "Glass · 200 ml",  volumeMl: 200),
            .init(label: "Bottle · 750 ml", volumeMl: 750),
        ],
        abvValues: fullAbvRange,
        defaultVolumeIndex: 1,   // Flute 125 ml
        defaultABVIndex: 23      // 12.0 %
    )

    // MARK: - Cider

    static let cider = DrinkTypePreset(
        category: .cider, name: "Cider", icon: "🍏",
        volumes: [
            .init(label: "Half-pint · 284 ml",    volumeMl: 284),
            .init(label: "Can · 330 ml",          volumeMl: 330),
            .init(label: "Big can · 440 ml",      volumeMl: 440),
            .init(label: "US pint · 473 ml",      volumeMl: 473),
            .init(label: "Bottle · 500 ml",       volumeMl: 500),
            .init(label: "Pint · 568 ml",         volumeMl: 568),
            .init(label: "Large bottle · 750 ml", volumeMl: 750),
        ],
        abvValues: fullAbvRange,
        defaultVolumeIndex: 4,   // Bottle 500 ml
        defaultABVIndex: 8       // 4.5 %
    )

    // MARK: - Alcopop

    static let alcopop = DrinkTypePreset(
        category: .alcopop, name: "Alcopop", icon: "🫧",
        volumes: [
            .init(label: "Can · 250 ml",    volumeMl: 250),
            .init(label: "Bottle · 275 ml", volumeMl: 275),
            .init(label: "Can · 330 ml",    volumeMl: 330),
            .init(label: "Large · 500 ml",  volumeMl: 500),
        ],
        abvValues: fullAbvRange,
        defaultVolumeIndex: 1,   // Bottle 275 ml
        defaultABVIndex: 9       // 5.0 %
    )

    // MARK: - Cocktail

    static let cocktail = DrinkTypePreset(
        category: .cocktail, name: "Cocktail", icon: "🍹",
        volumes: [
            .init(label: "Short · 100 ml",  volumeMl: 100),
            .init(label: "Small · 125 ml",  volumeMl: 125),
            .init(label: "Medium · 150 ml", volumeMl: 150),
            .init(label: "Long · 200 ml",   volumeMl: 200),
            .init(label: "Tall · 250 ml",   volumeMl: 250),
            .init(label: "XL · 300 ml",     volumeMl: 300),
        ],
        abvValues: fullAbvRange,
        defaultVolumeIndex: 3,   // Long 200 ml
        defaultABVIndex: 29      // 15.0 %
    )

    // MARK: - Fortified wine

    static let fortifiedWine = DrinkTypePreset(
        category: .fortifiedWine, name: "Fortified", icon: "🍾",
        volumes: [
            .init(label: "Standard · 50 ml",  volumeMl: 50),
            .init(label: "Large · 60 ml",     volumeMl: 60),
            .init(label: "Aperitif · 75 ml",  volumeMl: 75),
            .init(label: "Vermouth · 100 ml", volumeMl: 100),
        ],
        abvValues: fullAbvRange,
        defaultVolumeIndex: 2,   // Aperitif 75 ml
        defaultABVIndex: 35      // 18.0 %
    )

    // MARK: - Hot drink

    static let hotDrink = DrinkTypePreset(
        category: .hotDrink, name: "Hot drink", icon: "☕",
        volumes: [
            .init(label: "Toddy · 150 ml",  volumeMl: 150),
            .init(label: "Mug · 200 ml",    volumeMl: 200),
            .init(label: "Mulled · 250 ml", volumeMl: 250),
            .init(label: "Large · 300 ml",  volumeMl: 300),
        ],
        abvValues: fullAbvRange,
        defaultVolumeIndex: 1,   // Mug 200 ml
        defaultABVIndex: 23      // 12.0 %
    )

    // MARK: - Custom

    static let custom = DrinkTypePreset(
        category: .custom, name: "Custom", icon: "🥤",
        volumes: stride(from: 10, through: 1000, by: 10).map {
            .init(label: "\($0) ml", volumeMl: $0)
        },
        abvValues: fullAbvRange,
        defaultVolumeIndex: 24,  // 250 ml
        defaultABVIndex: 9       // 5.0 %
    )
}
