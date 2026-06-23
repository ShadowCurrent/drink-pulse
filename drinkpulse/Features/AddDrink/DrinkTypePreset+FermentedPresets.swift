import Foundation

extension DrinkTypePreset {

    // All presets share the same wide ABV range (0.5 % – 100 %) so any drink
    // strength is selectable. Type-specific defaults are set via defaultABVIndex.
    // Index formula for step-5 range: index = (permille / 5) – 1
    // e.g. 5.0 % = 50 permille → index 9; 40.0 % = 400 permille → index 79.
    static let fullAbvRange = abvRange(from: 5, through: 1000)  // 0.5 – 100.0 %

    // Region-tag policy (plan-0030): each option is tagged to the unit system(s)
    // where its number is a natural round serving — round ml for .metric, round
    // US fl oz for .usCustomary, round imperial fl oz / pints for .imperial.
    // Multi-tag only where genuinely round in 2+ systems. Coverage invariant:
    // every category yields ≥1 entry per unit system. Convenience aliases:
    private static let m: Set<UnitSystem> = [.metric]
    private static let mu: Set<UnitSystem> = [.metric, .usCustomary]
    private static let mi: Set<UnitSystem> = [.metric, .imperial]
    private static let u: Set<UnitSystem> = [.usCustomary]
    private static let i: Set<UnitSystem> = [.imperial]

    // MARK: - Beer

    static let beer = DrinkTypePreset(
        category: .beer, name: "Beer", icon: "🍺",
        volumes: [
            .init(descriptor: "Stange",      volumeMl: 200, regions: m),
            .init(descriptor: "Small glass", volumeMl: 250, regions: m),
            .init(descriptor: "Half-pint",   volumeMl: 284, regions: i),   // 10.0 imperial fl oz
            .init(descriptor: "Pot AU",      volumeMl: 285, regions: m),
            .init(descriptor: "0.3 L",       volumeMl: 300, regions: m),
            .init(descriptor: "Can",         volumeMl: 330, regions: m),
            .init(descriptor: "US can",      volumeMl: 355, regions: u),   // 12.0 US fl oz
            .init(descriptor: "0.4 L",       volumeMl: 400, regions: m),
            .init(descriptor: "Schooner AU", volumeMl: 425, regions: m),
            .init(descriptor: "Big can",     volumeMl: 440, regions: m),
            .init(descriptor: "US pint",     volumeMl: 473, regions: u),   // 16.0 US fl oz
            .init(descriptor: "Bottle",      volumeMl: 500, regions: m),
            .init(descriptor: "Pint",        volumeMl: 568, regions: i),   // 20.0 imperial fl oz
            .init(descriptor: "Large bottle", volumeMl: 660, regions: m),
            .init(descriptor: "Bomber",      volumeMl: 750, regions: m),
            .init(descriptor: "Mug",         volumeMl: 1000, regions: m),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 500,    // Bottle (metric); US/imperial resolve to nearest native
        defaultABVIndex: 9       // 5.0 %
    )

    // MARK: - Wine

    static let wine = DrinkTypePreset(
        category: .wine, name: "Wine", icon: "🍷",
        volumes: [
            .init(descriptor: "Tasting",  volumeMl: 100, regions: m),
            .init(descriptor: "Small",    volumeMl: 125, regions: m),
            .init(descriptor: "US pour",  volumeMl: 148, regions: u),    // 5.0 US fl oz
            .init(descriptor: "Standard", volumeMl: 150, regions: m),
            .init(descriptor: "Imperial pour", volumeMl: 142, regions: i), // 5.0 imperial fl oz
            .init(descriptor: "Medium",   volumeMl: 175, regions: m),
            .init(descriptor: "Large",    volumeMl: 250, regions: m),
            .init(descriptor: "Half btl", volumeMl: 375, regions: m),
            .init(descriptor: "Carafe",   volumeMl: 500, regions: m),
            .init(descriptor: "Bottle",   volumeMl: 750, regions: m),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 150,    // Standard (metric)
        defaultABVIndex: 24      // 12.5 %
    )

    // MARK: - Champagne

    static let champagne = DrinkTypePreset(
        category: .champagne, name: "Champagne", icon: "🥂",
        volumes: [
            .init(descriptor: "Toast",  volumeMl: 100, regions: m),
            .init(descriptor: "Flute",  volumeMl: 125, regions: m),
            .init(descriptor: "US flute", volumeMl: 118, regions: u),   // 4.0 US fl oz
            .init(descriptor: "Imperial flute", volumeMl: 114, regions: i), // 4.0 imperial fl oz
            .init(descriptor: "Large",  volumeMl: 150, regions: m),
            .init(descriptor: "Coupe",  volumeMl: 180, regions: m),
            .init(descriptor: "Glass",  volumeMl: 200, regions: m),
            .init(descriptor: "Bottle", volumeMl: 750, regions: m),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 125,    // Flute (metric)
        defaultABVIndex: 23      // 12.0 %
    )

    // MARK: - Cider

    static let cider = DrinkTypePreset(
        category: .cider, name: "Cider", icon: "🍏",
        volumes: [
            .init(descriptor: "Half-pint",   volumeMl: 284, regions: i),  // 10.0 imperial fl oz
            .init(descriptor: "Can",         volumeMl: 330, regions: m),
            .init(descriptor: "US can",      volumeMl: 355, regions: u),  // 12.0 US fl oz
            .init(descriptor: "Big can",     volumeMl: 440, regions: m),
            .init(descriptor: "US pint",     volumeMl: 473, regions: u),  // 16.0 US fl oz
            .init(descriptor: "Bottle",      volumeMl: 500, regions: m),
            .init(descriptor: "Pint",        volumeMl: 568, regions: i),  // 20.0 imperial fl oz
            .init(descriptor: "Large bottle", volumeMl: 750, regions: m),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 500,    // Bottle (metric)
        defaultABVIndex: 8       // 4.5 %
    )

    // MARK: - Alcopop

    static let alcopop = DrinkTypePreset(
        category: .alcopop, name: "Alcopop", icon: "🫧",
        volumes: [
            .init(descriptor: "Can",    volumeMl: 250, regions: m),
            .init(descriptor: "Bottle", volumeMl: 275, regions: m),
            .init(descriptor: "US can", volumeMl: 355, regions: u),    // 12.0 US fl oz
            .init(descriptor: "Half-pint", volumeMl: 284, regions: i), // 10.0 imperial fl oz
            .init(descriptor: "Can",    volumeMl: 330, regions: m),
            .init(descriptor: "Large",  volumeMl: 500, regions: m),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 275,    // Bottle (metric)
        defaultABVIndex: 9       // 5.0 %
    )

    // MARK: - Cocktail

    static let cocktail = DrinkTypePreset(
        category: .cocktail, name: "Cocktail", icon: "🍹",
        volumes: [
            .init(descriptor: "Short",  volumeMl: 100, regions: m),
            .init(descriptor: "Small",  volumeMl: 125, regions: m),
            .init(descriptor: "Medium", volumeMl: 150, regions: m),
            .init(descriptor: "US pour", volumeMl: 148, regions: u),   // 5.0 US fl oz
            .init(descriptor: "Imperial pour", volumeMl: 142, regions: i), // 5.0 imperial fl oz
            .init(descriptor: "Long",   volumeMl: 200, regions: m),
            .init(descriptor: "US tall", volumeMl: 237, regions: u),   // 8.0 US fl oz
            .init(descriptor: "Imperial tall", volumeMl: 227, regions: i), // 8.0 imperial fl oz
            .init(descriptor: "Tall",   volumeMl: 250, regions: m),
            .init(descriptor: "XL",     volumeMl: 300, regions: m),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 200,    // Long (metric)
        defaultABVIndex: 29      // 15.0 %
    )

    // MARK: - Fortified wine

    static let fortifiedWine = DrinkTypePreset(
        category: .fortifiedWine, name: "Fortified", icon: "🍾",
        volumes: [
            .init(descriptor: "Standard", volumeMl: 50, regions: m),
            .init(descriptor: "US pour",  volumeMl: 59, regions: u),   // 2.0 US fl oz
            .init(descriptor: "Imperial pour", volumeMl: 57, regions: i), // 2.0 imperial fl oz
            .init(descriptor: "Large",    volumeMl: 60, regions: m),
            .init(descriptor: "Aperitif", volumeMl: 75, regions: m),
            .init(descriptor: "Vermouth", volumeMl: 100, regions: m),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 75,     // Aperitif (metric)
        defaultABVIndex: 35      // 18.0 %
    )

    // MARK: - Hot drink

    static let hotDrink = DrinkTypePreset(
        category: .hotDrink, name: "Hot drink", icon: "☕",
        volumes: [
            .init(descriptor: "Toddy",  volumeMl: 150, regions: m),
            .init(descriptor: "US pour", volumeMl: 148, regions: u),   // 5.0 US fl oz
            .init(descriptor: "Imperial pour", volumeMl: 142, regions: i), // 5.0 imperial fl oz
            .init(descriptor: "Mug",    volumeMl: 200, regions: m),
            .init(descriptor: "US mug", volumeMl: 237, regions: u),    // 8.0 US fl oz
            .init(descriptor: "Imperial mug", volumeMl: 227, regions: i), // 8.0 imperial fl oz
            .init(descriptor: "Mulled", volumeMl: 250, regions: m),
            .init(descriptor: "Large",  volumeMl: 300, regions: m),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 200,    // Mug (metric)
        defaultABVIndex: 23      // 12.0 %
    )

    // MARK: - Custom

    /// Custom serving wheel. In metric, 10 ml steps. In oz modes the rows are
    /// 0.5 fl oz steps (canonical ml computed from the oz step) so the wheel reads
    /// in the active unit (plan-0030). All entries are tagged for every system so
    /// the filtered list always matches the active unit's stepping.
    static func customVolumes(for unitSystem: UnitSystem) -> [VolumeOption] {
        switch unitSystem {
        case .metric:
            return stride(from: 10, through: 1000, by: 10).map {
                .init(descriptor: "", volumeMl: Double($0), regions: [.metric])
            }
        case .usCustomary, .imperial:
            let perOz = unitSystem.mlPerFluidOunce ?? UnitSystem.mlPerUSFluidOunce
            // 0.5 fl oz steps, ~0.5 .. ~34 fl oz (covers the 10–1000 ml range).
            return stride(from: 5, through: 340, by: 5).map { halfOzStep in
                let oz = Double(halfOzStep) / 10.0
                return .init(descriptor: "", volumeMl: oz * perOz, regions: [unitSystem])
            }
        }
    }

    static let custom = DrinkTypePreset(
        category: .custom, name: "Custom", icon: "🥤",
        volumes: stride(from: 10, through: 1000, by: 10).map {
            .init(descriptor: "", volumeMl: Double($0),
                  regions: [.metric, .usCustomary, .imperial])
        },
        abvValues: fullAbvRange,
        defaultVolumeMl: 250,    // 250 ml
        defaultABVIndex: 9       // 5.0 %
    )
}
