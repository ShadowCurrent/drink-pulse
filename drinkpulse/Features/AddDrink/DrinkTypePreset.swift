import Foundation

struct DrinkTypePreset: Hashable, Identifiable {
    struct VolumeOption: Hashable {
        let descriptor: String
        let volumeMl: Double
        let regions: Set<UnitSystem>
        var regionNames: [UnitSystem: String] = [:]

        nonisolated func name(in unitSystem: UnitSystem) -> String {
            regionNames[unitSystem] ?? descriptor
        }

        func label(in unitSystem: UnitSystem) -> String {
            let base = "\(name(in: unitSystem)) · \(unitSystem.servingVolumeLabel(volumeMl))"
            if let hint = unitSystem.servingMlHint(volumeMl) {
                return "\(base) · \(hint)"
            }
            return base
        }
    }

    let category: DrinkCategory
    let name: String
    let icon: String
    let volumes: [VolumeOption]
    let abvValues: [Double]
    let defaultVolumeMl: Double
    let defaultABVIndex: Int
    var regionDefaults: [UnitSystem: Double] = [:]

    var id: DrinkCategory { category }
    var abvMin: Double { abvValues.first ?? 0 }
    var abvMax: Double { abvValues.last ?? 0 }

    static func == (lhs: DrinkTypePreset, rhs: DrinkTypePreset) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    func volumes(for unitSystem: UnitSystem) -> [VolumeOption] {
        volumes.filter { $0.regions.contains(unitSystem) }
    }

    func nearestVolumeMl(to ml: Double, in unitSystem: UnitSystem) -> Double {
        let options = volumes(for: unitSystem)
        guard let nearest = options.min(by: {
            abs($0.volumeMl - ml) < abs($1.volumeMl - ml)
        }) else {
            return defaultVolumeMl
        }
        return nearest.volumeMl
    }

    func defaultVolumeMl(for unitSystem: UnitSystem) -> Double {
        let preferred = regionDefaults[unitSystem] ?? defaultVolumeMl
        let options = volumes(for: unitSystem)
        if options.contains(where: { $0.volumeMl == preferred }) {
            return preferred
        }
        return nearestVolumeMl(to: preferred, in: unitSystem)
    }

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

    nonisolated static func preset(for category: DrinkCategory) -> DrinkTypePreset {
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
