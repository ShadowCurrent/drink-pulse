import Foundation

struct DrinkTypePreset: Hashable, Identifiable {
    /// A quick-pick serving size. `volumeMl` is the canonical, exact value;
    /// `descriptor` carries NO number (the number is composed at display time
    /// from the active `UnitSystem`). `regions` tags which unit modes list this
    /// option for NEW drinks — see plan-0030.
    struct VolumeOption: Hashable {
        let descriptor: String
        let volumeMl: Double
        let regions: Set<UnitSystem>

        /// Composed label for the active unit system, e.g. `"Can · 12 oz"`.
        /// UI concern (not a domain rule): descriptor + formatted volume.
        func label(for unitSystem: UnitSystem) -> String {
            "\(descriptor) · \(unitSystem.formatVolume(volumeMl))"
        }
    }

    let category: DrinkCategory
    let name: String
    let icon: String
    let volumes: [VolumeOption]
    /// ABV values as plain fractions (0.05 = 5%).
    let abvValues: [Double]
    /// Canonical default serving volume (ml). The default selection resolves by ml,
    /// not by array index, so it stays stable across unit switches.
    let defaultVolumeMl: Double
    let defaultABVIndex: Int

    var id: DrinkCategory { category }
    var abvMin: Double { abvValues.first ?? 0 }
    var abvMax: Double { abvValues.last ?? 0 }

    static func == (lhs: DrinkTypePreset, rhs: DrinkTypePreset) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Serving options listed for NEW drinks in the given unit system
    /// (region-native entries only). Guaranteed non-empty by the coverage
    /// invariant — every category tags ≥1 entry per unit system.
    func volumes(for unitSystem: UnitSystem) -> [VolumeOption] {
        volumes.filter { $0.regions.contains(unitSystem) }
    }

    /// Resolves a canonical ml to the nearest listed option's ml for the given
    /// unit system, so a selection survives a unit switch by re-snapping to the
    /// closest native row. Returns the region default when no options match.
    func nearestVolumeMl(to ml: Double, in unitSystem: UnitSystem) -> Double {
        let options = volumes(for: unitSystem)
        guard let nearest = options.min(by: {
            abs($0.volumeMl - ml) < abs($1.volumeMl - ml)
        }) else {
            return defaultVolumeMl
        }
        return nearest.volumeMl
    }

    /// The default serving ml for the given unit system: the region default if it
    /// is native to that system, otherwise the nearest native option. Pins the
    /// coverage invariant's "default is a tagged entry" requirement.
    func defaultVolumeMl(for unitSystem: UnitSystem) -> Double {
        let options = volumes(for: unitSystem)
        if options.contains(where: { $0.volumeMl == defaultVolumeMl }) {
            return defaultVolumeMl
        }
        return nearestVolumeMl(to: defaultVolumeMl, in: unitSystem)
    }

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
