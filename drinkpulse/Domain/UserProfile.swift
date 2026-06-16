import Foundation
import SwiftData

enum BiologicalSex: String, Codable, Sendable {
    case male, female
}

enum GuidelineChoice: String, Codable, CaseIterable, Sendable {
    case who, de, uk, us, au, ca, custom
}

enum UnitSystem: String, Codable, CaseIterable, Sendable {
    case metric       // millilitres
    case usCustomary  // US fluid ounces (1 fl oz = 29.5735 ml)
    case imperial     // Imperial fluid ounces (1 fl oz = 28.4131 ml)
}

enum AlcoholUnit: String, Codable, CaseIterable, Sendable {
    case grams
    case standardDrinks // regional: guideline-specific std drink size and density

    /// Decode fallback (plan-0029): the retired `"units"` case and any unknown raw
    /// value map to `.standardDrinks` (UK now folds into standard drinks at 8 g/0.8).
    /// This is the lightweight, additive-compatible migration for the stored
    /// SwiftData property and for imported `ProfileRecord`s — no store wipe.
    nonisolated init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AlcoholUnit(rawValue: raw) ?? .standardDrinks
    }
}

extension AlcoholUnit {
    /// Scientific ethanol density at 20 °C (g/ml). The *physical* mass of pure
    /// alcohol — used for calories and (future) BAC, which must never shift when
    /// the user changes their display unit. Hand-verify before changing.
    nonisolated static let physicalDensityGramsPerMl = 0.789

    // Volume → mass density for *this display mode AND guideline* (plan-0029 / ADR-0006).
    // Deliberately keyed so the unit math lands on clean, hand-verified numbers:
    //   .grams                → 0.789 (scientific): 500 ml × 5 % = 19.725 g, all guidelines.
    //   .standardDrinks, US/CA → 0.789 (their std drink is mass-defined: US 14 g, CA 13.45 g),
    //                            so each country's reference beer reads exactly 1.0
    //                            (US 355 ml = 14.0 g; CA 341 ml = 13.45 g).
    //   .standardDrinks, other → 0.8 (EU/UK unit convention): EU 500 ml × 5 % = 20.0 g =
    //                            exactly 2.0 (WHO/DE/AU) / 2.5 UK.
    // Physical mass (calories / future BAC) always uses `physicalDensityGramsPerMl`,
    // never this. Hand-verify before changing.
    /// Grams of pure alcohol per millilitre at 100 % ABV, for this display mode and guideline.
    nonisolated func density(for guideline: GuidelineChoice) -> Double {
        switch self {
        case .grams:
            return Self.physicalDensityGramsPerMl
        case .standardDrinks:
            switch guideline {
            case .us, .ca: return Self.physicalDensityGramsPerMl  // mass-defined std drink
            case .who, .de, .uk, .au, .custom: return 0.8         // EU/UK unit convention
            }
        }
    }

    // Grams per regional unit — hand-verify before changing:
    //   UK (NHS):  1 unit  = 10 ml pure ethanol; with the 0.8 g/ml display density = 8.0 g.
    //   DE / WHO / AU:  1 standard drink = 10 g pure alcohol
    //   US (NIAAA): 1 drink = 14 g pure alcohol (355 ml × 5% × 0.789 = 14.0 g)
    //   CA (Health Canada): 1 standard drink = 13.45 g (341 ml × 5% × 0.789 = 13.45 g)
    /// Grams of pure alcohol per one displayed unit, for the given guideline.
    /// `.grams` is the identity (1 g per "unit").
    nonisolated func gramsPerUnit(for guideline: GuidelineChoice) -> Double {
        switch self {
        case .grams:
            return 1.0
        case .standardDrinks:
            switch guideline {
            case .uk:                          return 8.0    // 10 ml ethanol × 0.8 display density
            case .us:                          return 14.0   // NIAAA: 14 g/drink
            case .ca:                          return 13.45  // Health Canada: 13.45 g/drink
            case .who, .de, .au, .custom:      return 10.0   // 10 g/drink (WHO/DE/AU standard)
            }
        }
    }

    /// Renders a *mass in grams* (computed with the appropriate display density) to
    /// the user's unit, one decimal place.
    nonisolated func formattedValue(_ massGrams: Double, guideline: GuidelineChoice) -> String {
        String(format: "%.1f", massGrams / gramsPerUnit(for: guideline))
    }

    /// Short unit label, guideline-aware (plan-0029, sub-decision #1): in
    /// `.standardDrinks` mode the UK reads "units"; every other guideline reads
    /// "standard drinks". `.grams` always reads "g".
    nonisolated func unitLabel(for guideline: GuidelineChoice) -> String {
        switch self {
        case .grams:
            return String(localized: "unit.g")
        case .standardDrinks:
            return guideline == .uk
                ? String(localized: "unit.units")
                : String(localized: "unit.standardDrinks")
        }
    }

    nonisolated var displayName: String {
        switch self {
        case .grams:          return String(localized: "settings.alcoholUnit.grams")
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
    var alcoholUnit: AlcoholUnit = AlcoholUnit.standardDrinks

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
        alcoholUnit: AlcoholUnit = .standardDrinks
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
