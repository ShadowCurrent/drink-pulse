import Foundation

nonisolated struct ProfileRecord: Codable, Equatable {
    var bodyWeightKg: Double
    var biologicalSex: BiologicalSex
    var dateOfBirth: Date?
    var guidelineChoice: GuidelineChoice
    var weeklyGoalGrams: Double
    var unitSystem: UnitSystem
    var currency: String
    var abvPrecisionPermille: Int
    var alcoholUnit: AlcoholUnit

    @MainActor
    init(from profile: UserProfile) {
        bodyWeightKg          = profile.bodyWeightKg
        biologicalSex         = profile.biologicalSex
        dateOfBirth           = profile.dateOfBirth
        guidelineChoice       = profile.guidelineChoice
        weeklyGoalGrams       = profile.weeklyGoalGrams
        unitSystem            = profile.unitSystem
        currency              = profile.currency
        abvPrecisionPermille  = profile.abvPrecisionPermille
        alcoholUnit           = profile.alcoholUnit
    }

    @MainActor
    func apply(to profile: UserProfile) {
        profile.bodyWeightKg         = bodyWeightKg
        profile.biologicalSex        = biologicalSex
        profile.dateOfBirth          = dateOfBirth
        profile.guidelineChoice      = guidelineChoice
        profile.weeklyGoalGrams      = weeklyGoalGrams
        profile.unitSystem           = unitSystem
        profile.currency             = currency
        profile.abvPrecisionPermille = abvPrecisionPermille
        profile.alcoholUnit          = alcoholUnit
    }
}
