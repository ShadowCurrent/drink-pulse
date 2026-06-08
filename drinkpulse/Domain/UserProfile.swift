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
    // Grams per regional unit — hand-verify before changing:
    //   UK (NHS):  1 unit  = 10 ml pure ethanol = 10 × 0.789 = 7.89 g
    //   DE / WHO:  1 unit  = 10 g pure alcohol
    //   US (NIAAA): 1 drink = 14 g pure alcohol
    // Standard drinks uses the same thresholds but always rounds to WHO (10 g) for non-US,
    // so the two options only differ meaningfully on the UK guideline.
    /// Grams of pure alcohol per one displayed unit, for the given guideline.
    /// `.grams` is the identity (1 g per "unit"). Values unchanged — see table above.
    nonisolated func gramsPerUnit(for guideline: GuidelineChoice) -> Double {
        switch self {
        case .grams:
            return 1.0
        case .units:
            switch guideline {
            case .uk:                return 7.89  // 10 ml ethanol × 0.789
            case .us:                return 14.0  // NIAAA standard drink
            case .who, .de, .custom: return 10.0  // European standard
            }
        case .standardDrinks:
            return guideline == .us ? 14.0 : 10.0
        }
    }

    nonisolated func formattedValue(_ pureAlcoholGrams: Double, guideline: GuidelineChoice) -> String {
        String(format: "%.1f", pureAlcoholGrams / gramsPerUnit(for: guideline))
    }

    /// The numeric value as actually shown to the user: converted to this unit and
    /// rounded to one decimal place (matching `formattedValue`). Use this — not raw
    /// grams — when a derived figure (e.g. a progress percentage) must agree with the
    /// displayed "X / Y unit" copy.
    nonisolated func displayValue(_ pureAlcoholGrams: Double, guideline: GuidelineChoice) -> Double {
        let converted = pureAlcoholGrams / gramsPerUnit(for: guideline)
        return (converted * 10).rounded() / 10
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
