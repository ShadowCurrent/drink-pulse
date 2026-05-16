import Foundation
import SwiftData

enum BiologicalSex: String, Codable, Sendable {
    case male, female
}

enum GuidelineChoice: String, Codable, CaseIterable, Sendable {
    case who, de, uk, us, custom
}

enum UnitSystem: String, Codable, CaseIterable, Sendable {
    case metric, imperial
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

    init(
        bodyWeightKg: Double = 70.0,
        biologicalSex: BiologicalSex = .male,
        ageYears: Int = 30,
        guidelineChoice: GuidelineChoice = .who,
        weeklyGoalGrams: Double = 100.0,
        unitSystem: UnitSystem = .metric,
        currency: String = "USD"
    ) {
        self.bodyWeightKg = bodyWeightKg
        self.biologicalSex = biologicalSex
        self.ageYears = ageYears
        self.guidelineChoice = guidelineChoice
        self.weeklyGoalGrams = weeklyGoalGrams
        self.unitSystem = unitSystem
        self.currency = currency
    }
}

extension UserProfile {
    static var preview: UserProfile {
        UserProfile(bodyWeightKg: 80.0, biologicalSex: .male, ageYears: 32,
                    guidelineChoice: .who, weeklyGoalGrams: 100.0, unitSystem: .metric)
    }
}
