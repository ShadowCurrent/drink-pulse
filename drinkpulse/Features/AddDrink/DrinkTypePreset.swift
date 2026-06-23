import Foundation

struct DrinkTypePreset: Hashable, Identifiable {
    /// A quick-pick serving size. `volumeMl` is the canonical, exact value;
    /// `descriptor` carries NO number (the number is composed at display time
    /// from the active `UnitSystem`). `regions` tags which unit modes list this
    /// option for NEW drinks. `regionNames` overrides the displayed name per
    /// unit system (so one 568 ml option reads "Pint" in metric/imperial but
    /// "Stovepipe" in US) — see plan-0031 / ADR-0007.
    struct VolumeOption: Hashable {
        let descriptor: String
        let volumeMl: Double
        let regions: Set<UnitSystem>
        /// Per-region display-name overrides. Defaulted empty so the existing
        /// memberwise call sites compile unchanged.
        var regionNames: [UnitSystem: String] = [:]

        /// The serving name shown in `unitSystem` — the region override if any,
        /// else the default `descriptor`.
        func name(in unitSystem: UnitSystem) -> String {
            regionNames[unitSystem] ?? descriptor
        }

        /// Composed picker label, e.g. `"Can · 12 oz"`, `"Pint · 1 pint"`, or
        /// `"Small · 4.4 oz · 125 ml"` (inline ml hint for a non-round serving).
        /// Per-region name + serving-volume label + optional hint (plan-0031).
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
    /// ABV values as plain fractions (0.05 = 5%).
    let abvValues: [Double]
    /// Canonical default serving volume (ml). The default selection resolves by ml,
    /// not by array index, so it stays stable across unit switches.
    let defaultVolumeMl: Double
    let defaultABVIndex: Int
    /// Per-unit-system default serving overrides for culturally-native sizes
    /// (e.g. UK beer defaults to 1 pint = 568 ml). When a unit system has no
    /// entry here, `defaultVolumeMl` applies. Defaulted empty so existing
    /// memberwise initializers compile unchanged (plan-0031 follow-up).
    var regionDefaults: [UnitSystem: Double] = [:]

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

    /// The default serving ml for the given unit system: the per-region override
    /// (`regionDefaults`) when present, else the canonical `defaultVolumeMl` — in
    /// both cases snapped to the nearest native option if the preferred value is
    /// not itself tagged for the system. Pins the coverage invariant's "default is
    /// a tagged entry" requirement.
    func defaultVolumeMl(for unitSystem: UnitSystem) -> Double {
        let preferred = regionDefaults[unitSystem] ?? defaultVolumeMl
        let options = volumes(for: unitSystem)
        if options.contains(where: { $0.volumeMl == preferred }) {
            return preferred
        }
        return nearestVolumeMl(to: preferred, in: unitSystem)
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
