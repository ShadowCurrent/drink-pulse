import Foundation
import SwiftData

enum BiologicalSex: String, Codable, Sendable {
    case male, female
}

enum GuidelineChoice: String, Codable, CaseIterable, Sendable {
    case who, de, uk, us, custom
}

enum UnitSystem: String, Codable, CaseIterable, Sendable {
    case metric       // millilitres
    case usCustomary  // US fluid ounces (1 fl oz = 29.5735 ml)
    case imperial     // Imperial fluid ounces (1 fl oz = 28.4131 ml)
}

enum AlcoholUnit: String, Codable, CaseIterable, Sendable {
    case grams
    case units          // UK standard: 1 unit = 10 ml pure ethanol = 7.89 g
    case standardDrinks // regional: 10 g/drink (WHO/DE/UK) or 14 g/drink (US)
}

extension AlcoholUnit {
    /// Scientific ethanol density at 20 °C (g/ml). The *physical* mass of pure
    /// alcohol — used for calories and (future) BAC, which must never shift when
    /// the user changes their display unit. Hand-verify before changing.
    nonisolated static let physicalDensityGramsPerMl = 0.789

    // Volume → mass density for *this display unit*. Deliberately unit-dependent so
    // the unit math lands on clean, hand-verified numbers:
    //   .grams          → 0.789 (scientific): 500 ml × 5 % = 19.725 g.
    //   .units (UK)     → 0.8:  500 ml × 5 % = 20.0 g = exactly 2.0 units (WHO/DE) / 2.5 UK.
    //   .standardDrinks → 0.789: 355 ml × 5 % = 14.0 g = exactly 1.0 US standard drink.
    // Physical mass (calories / future BAC) always uses `physicalDensityGramsPerMl`,
    // never this. Hand-verify before changing.
    /// Grams of pure alcohol per millilitre at 100 % ABV, for this display unit.
    nonisolated var densityGramsPerMl: Double {
        switch self {
        case .grams:          return Self.physicalDensityGramsPerMl
        case .units:          return 0.8
        case .standardDrinks: return Self.physicalDensityGramsPerMl
        }
    }

    // Grams per regional unit — hand-verify before changing:
    //   UK (NHS):  1 unit  = 10 ml pure ethanol; with the 0.8 g/ml display density = 8.0 g.
    //   DE / WHO:  1 unit  = 10 g pure alcohol
    //   US (NIAAA): 1 drink = 14 g pure alcohol
    // Standard drinks uses the same thresholds but always rounds to WHO (10 g) for non-US,
    // so the two options only differ meaningfully on the UK guideline.
    /// Grams of pure alcohol per one displayed unit, for the given guideline.
    /// `.grams` is the identity (1 g per "unit").
    nonisolated func gramsPerUnit(for guideline: GuidelineChoice) -> Double {
        switch self {
        case .grams:
            return 1.0
        case .units:
            switch guideline {
            case .uk:                return 8.0   // 10 ml ethanol × 0.8 display density
            case .us:                return 14.0  // NIAAA standard drink
            case .who, .de, .custom: return 10.0  // European standard
            }
        case .standardDrinks:
            return guideline == .us ? 14.0 : 10.0
        }
    }

    /// Renders a *mass in grams* (computed with the appropriate display density) to
    /// the user's unit, one decimal place.
    nonisolated func formattedValue(_ massGrams: Double, guideline: GuidelineChoice) -> String {
        String(format: "%.1f", massGrams / gramsPerUnit(for: guideline))
    }

    nonisolated var unitLabel: String {
        switch self {
        case .grams:          return String(localized: "unit.g")
        case .units:          return String(localized: "unit.units")
        case .standardDrinks: return String(localized: "unit.standardDrinks")
        }
    }

    nonisolated var displayName: String {
        switch self {
        case .grams:          return String(localized: "settings.alcoholUnit.grams")
        case .units:          return String(localized: "settings.alcoholUnit.units")
        case .standardDrinks: return String(localized: "settings.alcoholUnit.standardDrinks")
        }
    }
}

@Model
final class UserProfile {
    // Enforces a single stored profile; fetch by this value in the repository.
    @Attribute(.unique) private(set) var id: String = "singleton"

    var bodyWeightKg: Double
    var biologicalSex: BiologicalSex
    var dateOfBirth: Date?
    var guidelineChoice: GuidelineChoice
    var weeklyGoalGrams: Double
    var unitSystem: UnitSystem
    var currency: String
    /// ABV picker step in per-mille. 5 = 0.5 % steps, 1 = 0.1 % steps.
    var abvPrecisionPermille: Int = 5
    var alcoholUnit: AlcoholUnit = AlcoholUnit.units

    var ageYears: Int? {
        guard let dob = dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: .now).year
    }

    init(
        bodyWeightKg: Double = 70.0,
        biologicalSex: BiologicalSex = .male,
        dateOfBirth: Date? = nil,
        guidelineChoice: GuidelineChoice = .who,
        weeklyGoalGrams: Double = 100.0,
        unitSystem: UnitSystem = .metric,
        currency: String = "USD",
        abvPrecisionPermille: Int = 5,
        alcoholUnit: AlcoholUnit = .units
    ) {
        self.bodyWeightKg = bodyWeightKg
        self.biologicalSex = biologicalSex
        self.dateOfBirth = dateOfBirth
        self.guidelineChoice = guidelineChoice
        self.weeklyGoalGrams = weeklyGoalGrams
        self.unitSystem = unitSystem
        self.currency = currency
        self.abvPrecisionPermille = abvPrecisionPermille
        self.alcoholUnit = alcoholUnit
    }
}

extension UserProfile {
    static var preview: UserProfile {
        let dob = Calendar.current.date(byAdding: .year, value: -32, to: .now)
        return UserProfile(bodyWeightKg: 80.0, biologicalSex: .male, dateOfBirth: dob,
                           guidelineChoice: .who, weeklyGoalGrams: 100.0, unitSystem: .metric)
    }
}
