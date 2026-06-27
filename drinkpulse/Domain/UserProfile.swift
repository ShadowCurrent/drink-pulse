import Foundation
import SwiftData

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
