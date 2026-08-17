import Foundation

extension DrinkTypePreset {

    nonisolated static let fullAbvRange = abvRange(from: 5, through: 1000)

    private nonisolated static let m: Set<UnitSystem> = [.metric]
    private nonisolated static let u: Set<UnitSystem> = [.usCustomary]
    private nonisolated static let i: Set<UnitSystem> = [.imperial]
    private nonisolated static let mu: Set<UnitSystem> = [.metric, .usCustomary]
    private nonisolated static let mi: Set<UnitSystem> = [.metric, .imperial]
    private nonisolated static let ui: Set<UnitSystem> = [.usCustomary, .imperial]
    private nonisolated static let mui: Set<UnitSystem> = [.metric, .usCustomary, .imperial]

    // MARK: - Beer

    nonisolated static let beer = DrinkTypePreset(
        category: .beer, name: "Beer", icon: "🍺",
        volumes: [
            .init(descriptor: "Taster",      volumeMl: 148, regions: u),
            .init(descriptor: "Third",       volumeMl: 189, regions: i),
            .init(descriptor: "Stange",      volumeMl: 200, regions: m),
            .init(descriptor: "Small glass", volumeMl: 250, regions: m),
            .init(descriptor: "Half-pint",   volumeMl: 284, regions: mi),
            .init(descriptor: "Pot AU",      volumeMl: 285, regions: m),
            .init(descriptor: "Short pour",  volumeMl: 296, regions: u),
            .init(descriptor: "0.3 L",       volumeMl: 300, regions: m),
            .init(descriptor: "Can",         volumeMl: 330, regions: mi),
            .init(descriptor: "Can",         volumeMl: 355, regions: ui),
            .init(descriptor: "Schooner",    volumeMl: 379, regions: i),
            .init(descriptor: "0.4 L",       volumeMl: 400, regions: m),
            .init(descriptor: "Schooner AU", volumeMl: 425, regions: m),
            .init(descriptor: "Big can",     volumeMl: 440, regions: mi),
            .init(descriptor: "Pint",        volumeMl: 473, regions: u),
            .init(descriptor: "Bottle",      volumeMl: 500, regions: mui),
            .init(descriptor: "Pint",        volumeMl: 568, regions: mui,
                  regionNames: [.usCustomary: "Stovepipe"]),
            .init(descriptor: "Bomber",      volumeMl: 651, regions: u),
            .init(descriptor: "Large bottle", volumeMl: 660, regions: mi),
            .init(descriptor: "Big can",     volumeMl: 710, regions: u),
            .init(descriptor: "Bomber",      volumeMl: 750, regions: m),
            .init(descriptor: "Crowler",     volumeMl: 946, regions: u),
            .init(descriptor: "Mug",         volumeMl: 1000, regions: m),
            .init(descriptor: "Stein",       volumeMl: 1136, regions: i),
            .init(descriptor: "Forty",       volumeMl: 1183, regions: u),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 500,
        defaultABVIndex: 9,
        regionDefaults: [.imperial: 568]
    )

    // MARK: - Wine

    nonisolated static let wine = DrinkTypePreset(
        category: .wine, name: "Wine", icon: "🍷",
        volumes: [
            .init(descriptor: "Taste",    volumeMl: 59, regions: u),
            .init(descriptor: "Small",    volumeMl: 89, regions: u),
            .init(descriptor: "Tasting",  volumeMl: 100, regions: m),
            .init(descriptor: "Small",    volumeMl: 125, regions: mi),
            .init(descriptor: "Pour",     volumeMl: 148, regions: u),
            .init(descriptor: "Standard", volumeMl: 150, regions: m),
            .init(descriptor: "Medium",   volumeMl: 175, regions: mi),
            .init(descriptor: "Generous", volumeMl: 177, regions: u),
            .init(descriptor: "Large",    volumeMl: 237, regions: u),
            .init(descriptor: "Large",    volumeMl: 250, regions: mi),
            .init(descriptor: "Half btl", volumeMl: 375, regions: mi),
            .init(descriptor: "Carafe",   volumeMl: 500, regions: mi),
            .init(descriptor: "Bottle",   volumeMl: 750, regions: mui),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 150,
        defaultABVIndex: 24
    )

    // MARK: - Champagne

    nonisolated static let champagne = DrinkTypePreset(
        category: .champagne, name: "Champagne", icon: "🥂",
        volumes: [
            .init(descriptor: "Toast",  volumeMl: 89, regions: u),
            .init(descriptor: "Toast",  volumeMl: 100, regions: mi),
            .init(descriptor: "Flute",  volumeMl: 118, regions: u),
            .init(descriptor: "Flute",  volumeMl: 125, regions: mi),
            .init(descriptor: "Pour",   volumeMl: 148, regions: u),
            .init(descriptor: "Large",  volumeMl: 150, regions: mi),
            .init(descriptor: "Coupe",  volumeMl: 177, regions: u),
            .init(descriptor: "Coupe",  volumeMl: 180, regions: m),
            .init(descriptor: "Glass",  volumeMl: 200, regions: mi),
            .init(descriptor: "Bottle", volumeMl: 750, regions: mui),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 125,
        defaultABVIndex: 23
    )

    // MARK: - Cider

    nonisolated static let cider = DrinkTypePreset(
        category: .cider, name: "Cider", icon: "🍏",
        volumes: [
            .init(descriptor: "Half-pint",   volumeMl: 284, regions: mi),
            .init(descriptor: "Can",         volumeMl: 330, regions: mi),
            .init(descriptor: "Can",         volumeMl: 355, regions: u),
            .init(descriptor: "Big can",     volumeMl: 440, regions: mi),
            .init(descriptor: "Pint",        volumeMl: 473, regions: u),
            .init(descriptor: "Bottle",      volumeMl: 500, regions: mui),
            .init(descriptor: "Pint",        volumeMl: 568, regions: mui,
                  regionNames: [.usCustomary: "Stovepipe"]),
            .init(descriptor: "Big can",     volumeMl: 710, regions: u),
            .init(descriptor: "Large bottle", volumeMl: 750, regions: m),
            .init(descriptor: "Flagon",      volumeMl: 1136, regions: i),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 500,
        defaultABVIndex: 8
    )

    // MARK: - Alcopop

    nonisolated static let alcopop = DrinkTypePreset(
        category: .alcopop, name: "Alcopop", icon: "🫧",
        volumes: [
            .init(descriptor: "Can",    volumeMl: 250, regions: mi),
            .init(descriptor: "Bottle", volumeMl: 275, regions: mi),
            .init(descriptor: "Can",    volumeMl: 330, regions: mi),
            .init(descriptor: "Can",    volumeMl: 355, regions: u),
            .init(descriptor: "Tallboy", volumeMl: 473, regions: u),
            .init(descriptor: "Large",  volumeMl: 500, regions: mi),
            .init(descriptor: "Big can", volumeMl: 710, regions: u),
        ],
        abvValues: fullAbvRange,
        defaultVolumeMl: 275,
        defaultABVIndex: 9
    )

    // MARK: - Custom

    static func customVolumes(for unitSystem: UnitSystem) -> [VolumeOption] {
        switch unitSystem {
        case .metric:
            return stride(from: 10, through: 1000, by: 10).map {
                .init(descriptor: "", volumeMl: Double($0), regions: [.metric])
            }
        case .usCustomary, .imperial:
            let perOz = unitSystem.mlPerFluidOunce ?? UnitSystem.mlPerUSFluidOunce
            return stride(from: 5, through: 340, by: 5).map { halfOzStep in
                let oz = Double(halfOzStep) / 10.0
                return .init(descriptor: "", volumeMl: oz * perOz, regions: [unitSystem])
            }
        }
    }

    nonisolated static let custom = DrinkTypePreset(
        category: .custom, name: "Custom", icon: "🥤",
        volumes: stride(from: 10, through: 1000, by: 10).map {
            .init(descriptor: "", volumeMl: Double($0),
                  regions: [.metric, .usCustomary, .imperial])
        },
        abvValues: fullAbvRange,
        defaultVolumeMl: 250,
        defaultABVIndex: 9
    )
}
