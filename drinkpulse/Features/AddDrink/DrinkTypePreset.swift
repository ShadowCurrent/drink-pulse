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
    nonisolated static func abvRange(from low: Int, through high: Int, step: Int = 5) -> [Double] {
        stride(from: low, through: high, by: step).map { Double($0) / 1000 }
    }
}

extension DrinkTypePreset {
    static let all: [DrinkTypePreset] = [
        .beer, .wine, .champagne, .cider, .alcopop,
        .spirits, .brandy, .cognac, .vodka, .whiskey, .tequila, .shot, .liqueur,
        .cocktail, .fortifiedWine, .hotDrink, .custom,
    ]

    static func preset(for category: DrinkCategory) -> DrinkTypePreset {
        switch category {
        case .beer:          return .beer
        case .wine:          return .wine
        case .champagne:     return .champagne
        case .cider:         return .cider
        case .alcopop:       return .alcopop
        case .spirits:       return .spirits
        case .brandy:        return .brandy
        case .cognac:        return .cognac
        case .vodka:         return .vodka
        case .whiskey:       return .whiskey
        case .tequila:       return .tequila
        case .shot:          return .shot
        case .liqueur:       return .liqueur
        case .cocktail:      return .cocktail
        case .fortifiedWine: return .fortifiedWine
        case .hotDrink:      return .hotDrink
        case .custom:        return .custom
        }
    }
}
