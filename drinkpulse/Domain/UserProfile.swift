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
    case units          // UK standard: 1 unit = 10 ml pure ethanol ≈ 7.89 g
    case standardDrinks // regional: 10 g/drink (WHO/DE/UK) or 14 g/drink (US)
}

extension AlcoholUnit {
    // Derivation for .units: pureAlcoholGrams = volumeMl × abv × 0.789
    //   → volumeMl × abv / 10 = pureAlcoholGrams / (0.789 × 10) = pureAlcoholGrams / 7.89
    // Matches the existing formula in HistoryView / DrinkDetailInputView.
    // Hand-verify before changing.
    func formattedValue(_ pureAlcoholGrams: Double, guideline: GuidelineChoice) -> String {
        switch self {
        case .grams:
            return String(format: "%.1f", pureAlcoholGrams)
        case .units:
            return String(format: "%.2f", pureAlcoholGrams / 7.89)
        case .standardDrinks:
            let gramsPerDrink: Double = guideline == .us ? 14.0 : 10.0
            return String(format: "%.2f", pureAlcoholGrams / gramsPerDrink)
        }
    }

    var unitLabel: String {
        switch self {
        case .grams:          return String(localized: "unit.g")
        case .units:          return String(localized: "unit.units")
        case .standardDrinks: return String(localized: "unit.standardDrinks")
        }
    }

    var displayName: String {
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
    var ageYears: Int
    var guidelineChoice: GuidelineChoice
    var weeklyGoalGrams: Double
    var unitSystem: UnitSystem
    var currency: String
    /// ABV picker step in per-mille. 5 = 0.5 % steps, 1 = 0.1 % steps.
    var abvPrecisionPermille: Int
    var alcoholUnit: AlcoholUnit

    init(
        bodyWeightKg: Double = 70.0,
        biologicalSex: BiologicalSex = .male,
        ageYears: Int = 30,
        guidelineChoice: GuidelineChoice = .who,
        weeklyGoalGrams: Double = 100.0,
        unitSystem: UnitSystem = .metric,
        currency: String = "USD",
        abvPrecisionPermille: Int = 5,
        alcoholUnit: AlcoholUnit = .units
    ) {
        self.bodyWeightKg = bodyWeightKg
        self.biologicalSex = biologicalSex
        self.ageYears = ageYears
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
        UserProfile(bodyWeightKg: 80.0, biologicalSex: .male, ageYears: 32,
                    guidelineChoice: .who, weeklyGoalGrams: 100.0, unitSystem: .metric)
    }
}
