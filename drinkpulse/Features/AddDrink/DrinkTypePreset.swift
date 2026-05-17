import Foundation

struct DrinkTypePreset: Hashable, Identifiable {
    struct VolumeOption: Hashable {
        let label: String
        let volumeMl: Double
    }

    let category: DrinkCategory
    let name: String
    let icon: String
    let volumes: [VolumeOption]
    /// ABV values as plain fractions (0.05 = 5%).
    let abvValues: [Double]
    let defaultVolumeIndex: Int
    let defaultABVIndex: Int

    var id: DrinkCategory { category }

    var abvMin: Double { abvValues.first ?? 0 }
    var abvMax: Double { abvValues.last ?? 0 }

    static func == (lhs: DrinkTypePreset, rhs: DrinkTypePreset) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Generates ABV fractions from integer per-mille steps to avoid floating-point drift.
    /// e.g. abvRange(from: 30, through: 80, step: 5) → [0.030, 0.035, …, 0.080]
    static func abvRange(from low: Int, through high: Int, step: Int = 5) -> [Double] {
        stride(from: low, through: high, by: step).map { Double($0) / 1000 }
    }
}

extension DrinkTypePreset {
    static let all: [DrinkTypePreset] = [.beer, .wine, .champagne, .spirits, .cocktail, .cider, .custom]

    static func preset(for category: DrinkCategory) -> DrinkTypePreset {
        all.first { $0.category == category } ?? .custom
    }

    static let beer = DrinkTypePreset(
        category: .beer, name: "Beer", icon: "🍺",
        volumes: [
            .init(label: "Half · 284 ml",   volumeMl: 284),
            .init(label: "Can · 330 ml",    volumeMl: 330),
            .init(label: "Can · 440 ml",    volumeMl: 440),
            .init(label: "Bottle · 500 ml", volumeMl: 500),
            .init(label: "Pint · 568 ml",   volumeMl: 568),
            .init(label: "Large · 750 ml",  volumeMl: 750),
        ],
        abvValues: abvRange(from: 30, through: 120),   // 3.0 – 12.0 %
        defaultVolumeIndex: 4,   // Pint 568 ml
        defaultABVIndex: 4       // 5.0 %
    )

    static let wine = DrinkTypePreset(
        category: .wine, name: "Wine", icon: "🍷",
        volumes: [
            .init(label: "Small · 125 ml",  volumeMl: 125),
            .init(label: "Medium · 175 ml", volumeMl: 175),
            .init(label: "Large · 250 ml",  volumeMl: 250),
            .init(label: "Bottle · 750 ml", volumeMl: 750),
        ],
        abvValues: abvRange(from: 90, through: 160),   // 9.0 – 16.0 %
        defaultVolumeIndex: 1,   // Medium 175 ml
        defaultABVIndex: 8       // 13.0 %
    )

    static let champagne = DrinkTypePreset(
        category: .champagne, name: "Champagne", icon: "🥂",
        volumes: [
            .init(label: "Flute · 125 ml",  volumeMl: 125),
            .init(label: "Coupe · 180 ml",  volumeMl: 180),
            .init(label: "Glass · 200 ml",  volumeMl: 200),
        ],
        abvValues: abvRange(from: 100, through: 135),  // 10.0 – 13.5 %
        defaultVolumeIndex: 0,   // Flute 125 ml
        defaultABVIndex: 3       // 11.5 %
    )

    static let spirits = DrinkTypePreset(
        category: .spirits, name: "Spirits", icon: "🥃",
        volumes: [
            .init(label: "Single · 25 ml",  volumeMl: 25),
            .init(label: "Double · 50 ml",  volumeMl: 50),
            .init(label: "Triple · 75 ml",  volumeMl: 75),
        ],
        abvValues: abvRange(from: 350, through: 650, step: 10),  // 35.0 – 65.0 %
        defaultVolumeIndex: 1,   // Double 50 ml
        defaultABVIndex: 5       // 40.0 %
    )

    static let cocktail = DrinkTypePreset(
        category: .cocktail, name: "Cocktail", icon: "🍹",
        volumes: [
            .init(label: "Short · 100 ml",  volumeMl: 100),
            .init(label: "Medium · 150 ml", volumeMl: 150),
            .init(label: "Long · 200 ml",   volumeMl: 200),
            .init(label: "Tall · 250 ml",   volumeMl: 250),
        ],
        abvValues: abvRange(from: 80, through: 200),   // 8.0 – 20.0 %
        defaultVolumeIndex: 1,   // Medium 150 ml
        defaultABVIndex: 8       // 12.0 %
    )

    static let cider = DrinkTypePreset(
        category: .cider, name: "Cider", icon: "🍏",
        volumes: [
            .init(label: "Can · 330 ml",    volumeMl: 330),
            .init(label: "Can · 440 ml",    volumeMl: 440),
            .init(label: "Bottle · 500 ml", volumeMl: 500),
            .init(label: "Pint · 568 ml",   volumeMl: 568),
        ],
        abvValues: abvRange(from: 30, through: 90),    // 3.0 – 9.0 %
        defaultVolumeIndex: 3,   // Pint 568 ml
        defaultABVIndex: 4       // 5.0 %
    )

    static let custom = DrinkTypePreset(
        category: .custom, name: "Custom", icon: "🥤",
        volumes: [
            .init(label: "100 ml",  volumeMl: 100),
            .init(label: "200 ml",  volumeMl: 200),
            .init(label: "250 ml",  volumeMl: 250),
            .init(label: "330 ml",  volumeMl: 330),
            .init(label: "500 ml",  volumeMl: 500),
        ],
        abvValues: abvRange(from: 5, through: 500),    // 0.5 – 50.0 %
        defaultVolumeIndex: 2,   // 250 ml
        defaultABVIndex: 9       // 5.0 %
    )
}
