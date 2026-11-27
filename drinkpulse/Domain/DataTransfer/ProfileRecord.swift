import Foundation

/// Profile part of an export bundle. Backups written before 2026-11-27 (bundle version 2)
/// may still carry a date of birth; the synthesized decoder ignores keys it does not know,
/// so those backups import unchanged and the bundle version stays 2 (quick 261127-l7y).
nonisolated struct ProfileRecord: Codable, Equatable {
    var bodyWeightKg: Double
    var biologicalSex: BiologicalSex
    var guidelineChoice: GuidelineChoice
    var weeklyGoalGrams: Double
    var unitSystem: UnitSystem
    var currency: String
    var abvPrecisionPermille: Int
    var alcoholUnit: AlcoholUnit
    var modifiedDate: Date?

    @MainActor
    init(from profile: UserProfile) {
        bodyWeightKg          = profile.bodyWeightKg
        biologicalSex         = profile.biologicalSex
        guidelineChoice       = profile.guidelineChoice
        weeklyGoalGrams       = profile.weeklyGoalGrams
        unitSystem            = profile.unitSystem
        currency              = profile.currency
        abvPrecisionPermille  = profile.abvPrecisionPermille
        alcoholUnit           = profile.alcoholUnit
        modifiedDate          = profile.modifiedDate
    }

    @MainActor
    func apply(to profile: UserProfile) {
        profile.bodyWeightKg         = bodyWeightKg
        profile.biologicalSex        = biologicalSex
        profile.guidelineChoice      = guidelineChoice
        profile.weeklyGoalGrams      = weeklyGoalGrams
        profile.unitSystem           = unitSystem
        profile.currency             = currency
        profile.abvPrecisionPermille = abvPrecisionPermille
        profile.alcoholUnit          = alcoholUnit
        profile.modifiedDate         = modifiedDate ?? .now
    }
}
