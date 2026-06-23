import Foundation

extension DrinkTypePreset {

    // All presets share the same wide ABV range (0.5 % – 100 %) so any drink
    // strength is selectable. Type-specific defaults are set via defaultABVIndex.
    // Index formula for step-5 range: index = (permille / 5) – 1
    // e.g. 5.0 % = 50 permille → index 9; 40.0 % = 400 permille → index 79.
    static let fullAbvRange = abvRange(from: 5, through: 1000)  // 0.5 – 100.0 %

    // Region-tag policy (plan-0031 — REVERSES the plan-0030 "round serving only"
    // rule; see domain.md). An option is tagged to a unit system when it is a
    // realistic serving there, even if its number is NOT a clean round value in
    // that unit: M-tier real measures (UK 125 ml wine = 4.4 imp oz) and X-tier
    // cross-borrows (355 ml → imperial, 568 ml → US/metric) are tagged on
    // purpose. The inline ml hint (see VolumeOption.label / isRoundServing) makes
    // a non-round oz read as intentional. `regionNames` overrides the displayed
    // name per system (568 = "Pint" / "Stovepipe"). Coverage invariant: every
    // category yields ≥1 entry per unit system. Convenience region aliases:
    private static let m: Set<UnitSystem> = [.metric]
    private static let u: Set<UnitSystem> = [.usCustomary]
    private static let i: Set<UnitSystem> = [.imperial]
    private static let mu: Set<UnitSystem> = [.metric, .usCustomary]
    private static let mi: Set<UnitSystem> = [.metric, .imperial]
    private static let ui: Set<UnitSystem> = [.usCustomary, .imperial]
    private static let mui: Set<UnitSystem> = [.metric, .usCustomary, .imperial]

    // MARK: - Beer

    static let beer = DrinkTypePreset(
        category: .beer, name: "Beer", icon: "🍺",
        volumes: [
            .init(descriptor: "Taster",      volumeMl: 148, regions: u),    // 5 oz
            .init(descriptor: "Third",       volumeMl: 189, regions: i),    // ⅓ pint
            .init(descriptor: "Stange",      volumeMl: 200, regions: m),
            .init(descriptor: "Small glass", volumeMl: 250, regions: m),
            .init(descriptor: "Half-pint",   volumeMl: 284, regions: mi),   // ½ pint, borrowed to metric
            .init(descriptor: "Pot AU",      volumeMl: 285, regions: m),
            .init(descriptor: "Short pour",  volumeMl: 296, regions: u),    // 10 oz
            .init(descriptor: "0.3 L",       volumeMl: 300, regions: m),
            .init(descriptor: "Can",         volumeMl: 330, regions: mi),   // UK can, 11.6 imp oz
            .init(descriptor: "Can",         volumeMl: 355, regions: ui),   // 12 oz US / 12.5 oz imp
            .init(descriptor: "Schooner",    volumeMl: 379, regions: i),    // ⅔ pint
            .init(descriptor: "0.4 L",       volumeMl: 400, regions: m),
            .init(descriptor: "Schooner AU", volumeMl: 425, regions: m),
            .init(descriptor: "Big can",     volumeMl: 440, regions: mi),   // UK big can, 15.5 imp oz
            .init(descriptor: "Pint",        volumeMl: 473, regions: u),    // 16 oz (US pint)
            .init(descriptor: "Bottle",      volumeMl: 500, regions: mui),  // 16.9 oz US / 17.6 imp
            .init(descriptor: "Pint",        volumeMl: 568, regions: mui,   // 1 pint / Stovepipe
                  regionNames: [.usCustomary: "Stovepipe"]),
            .init(descriptor: "Bomber",      volumeMl: 651, regions: u),    // 22 oz
            .init(descriptor: "Large bottle", volumeMl: 660, regions: mi),  // UK bottle, 23.2 imp oz
            .init(descriptor: "Big can",     volumeMl: 710, regions: u),    // 24 oz
            .init(descriptor: "Bomber",      volumeMl: 750, regions: m),
            .init(descriptor: "Crowler",     volumeMl: 946, regions: u),    // 32 oz
            .init(descriptor: "Mug",         volumeMl: 1000, regions: m),
            .init(descriptor: "Stein",       volumeMl: 1136, regions: i),   // 2 pints
            .init(descriptor: "Forty",       volumeMl: 1183, regions: u),   // 40 oz
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 500,    // Bottle (metric/US); imperial defaults to 1 pint
        defaultABVIndex: 9,      // 5.0 %
        regionDefaults: [.imperial: 568]   // UK beer = 1 pint
    )

    // MARK: - Wine

    static let wine = DrinkTypePreset(
        category: .wine, name: "Wine", icon: "🍷",
        volumes: [
            .init(descriptor: "Taste",    volumeMl: 59, regions: u),     // 2 oz
            .init(descriptor: "Small",    volumeMl: 89, regions: u),     // 3 oz
            .init(descriptor: "Tasting",  volumeMl: 100, regions: m),
            .init(descriptor: "Small",    volumeMl: 125, regions: mi),   // 4.4 oz UK measure
            .init(descriptor: "Pour",     volumeMl: 148, regions: u),    // 5 oz
            .init(descriptor: "Standard", volumeMl: 150, regions: m),
            .init(descriptor: "Medium",   volumeMl: 175, regions: mi),   // 6.2 oz UK measure
            .init(descriptor: "Generous", volumeMl: 177, regions: u),    // 6 oz
            .init(descriptor: "Large",    volumeMl: 237, regions: u),    // 8 oz
            .init(descriptor: "Large",    volumeMl: 250, regions: mi),   // 8.8 oz UK measure
            .init(descriptor: "Half btl", volumeMl: 375, regions: mi),   // 13.2 imp oz
            .init(descriptor: "Carafe",   volumeMl: 500, regions: mi),   // 17.6 imp oz
            .init(descriptor: "Bottle",   volumeMl: 750, regions: mui),  // cross-borrow
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 150,    // Standard (metric)
        defaultABVIndex: 24      // 12.5 %
    )

    // MARK: - Champagne

    static let champagne = DrinkTypePreset(
        category: .champagne, name: "Champagne", icon: "🥂",
        volumes: [
            .init(descriptor: "Toast",  volumeMl: 89, regions: u),     // 3 oz
            .init(descriptor: "Toast",  volumeMl: 100, regions: mi),   // 3.5 oz UK measure
            .init(descriptor: "Flute",  volumeMl: 118, regions: u),    // 4 oz
            .init(descriptor: "Flute",  volumeMl: 125, regions: mi),   // 4.4 oz UK measure
            .init(descriptor: "Pour",   volumeMl: 148, regions: u),    // 5 oz
            .init(descriptor: "Large",  volumeMl: 150, regions: mi),   // 5.3 imp oz
            .init(descriptor: "Coupe",  volumeMl: 177, regions: u),    // 6 oz
            .init(descriptor: "Coupe",  volumeMl: 180, regions: m),
            .init(descriptor: "Glass",  volumeMl: 200, regions: mi),   // 7 imp oz
            .init(descriptor: "Bottle", volumeMl: 750, regions: mui),  // cross-borrow
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 125,    // Flute (metric)
        defaultABVIndex: 23      // 12.0 %
    )

    // MARK: - Cider

    static let cider = DrinkTypePreset(
        category: .cider, name: "Cider", icon: "🍏",
        volumes: [
            .init(descriptor: "Half-pint",   volumeMl: 284, regions: mi),  // ½ pint, borrowed to metric
            .init(descriptor: "Can",         volumeMl: 330, regions: mi),  // UK can, 11.6 imp oz
            .init(descriptor: "Can",         volumeMl: 355, regions: u),   // 12 oz
            .init(descriptor: "Big can",     volumeMl: 440, regions: mi),  // UK big can, 15.5 imp oz
            .init(descriptor: "Pint",        volumeMl: 473, regions: u),   // 16 oz (US pint)
            .init(descriptor: "Bottle",      volumeMl: 500, regions: mui), // cross-borrow
            .init(descriptor: "Pint",        volumeMl: 568, regions: mui,  // 1 pint / Stovepipe
                  regionNames: [.usCustomary: "Stovepipe"]),
            .init(descriptor: "Big can",     volumeMl: 710, regions: u),   // 24 oz
            .init(descriptor: "Large bottle", volumeMl: 750, regions: m),
            .init(descriptor: "Flagon",      volumeMl: 1136, regions: i),  // 2 pints
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 500,    // Bottle (metric)
        defaultABVIndex: 8       // 4.5 %
    )

    // MARK: - Alcopop

    static let alcopop = DrinkTypePreset(
        category: .alcopop, name: "Alcopop", icon: "🫧",
        volumes: [
            .init(descriptor: "Can",    volumeMl: 250, regions: mi),   // 8.8 oz UK measure
            .init(descriptor: "Bottle", volumeMl: 275, regions: mi),   // 9.7 oz UK measure
            .init(descriptor: "Can",    volumeMl: 330, regions: mi),   // UK can, 11.6 imp oz
            .init(descriptor: "Can",    volumeMl: 355, regions: u),    // 12 oz
            .init(descriptor: "Tallboy", volumeMl: 473, regions: u),   // 16 oz
            .init(descriptor: "Large",  volumeMl: 500, regions: mi),   // 17.6 oz UK measure
            .init(descriptor: "Big can", volumeMl: 710, regions: u),   // 24 oz
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 275,    // Bottle (metric)
        defaultABVIndex: 9       // 5.0 %
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
