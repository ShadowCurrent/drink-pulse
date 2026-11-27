import Foundation
import SwiftData

@Model
final class UserProfile {
    private(set) var id: String = "singleton"

    var bodyWeightKg: Double = 0
    var biologicalSex: BiologicalSex = BiologicalSex.male
    var guidelineChoice: GuidelineChoice = GuidelineChoice.who
    var weeklyGoalGrams: Double = 0
    var unitSystem: UnitSystem = UnitSystem.metric
    var currency: String = ""
    var abvPrecisionPermille: Int = 5
    var alcoholUnit: AlcoholUnit = AlcoholUnit.standardDrinks

    var modifiedDate: Date = Date(timeIntervalSince1970: 0)

    init(
        bodyWeightKg: Double = 70.0,
        biologicalSex: BiologicalSex = .male,
        guidelineChoice: GuidelineChoice = .who,
        weeklyGoalGrams: Double = 100.0,
        unitSystem: UnitSystem = .metric,
        currency: String = "USD",
        abvPrecisionPermille: Int = 5,
        alcoholUnit: AlcoholUnit = .standardDrinks
    ) {
        self.bodyWeightKg = bodyWeightKg
        self.biologicalSex = biologicalSex
        self.guidelineChoice = guidelineChoice
        self.weeklyGoalGrams = weeklyGoalGrams
        self.unitSystem = unitSystem
        self.currency = currency
        self.abvPrecisionPermille = abvPrecisionPermille
        self.alcoholUnit = alcoholUnit
        self.modifiedDate = .now
    }

    func touch() {
        modifiedDate = .now
    }
}

extension UserProfile {
    static var preview: UserProfile {
        UserProfile(bodyWeightKg: 80.0, biologicalSex: .male,
                    guidelineChoice: .who, weeklyGoalGrams: 100.0, unitSystem: .metric)
    }
}
