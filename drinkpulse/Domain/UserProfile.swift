import Foundation
import SwiftData

@Model
final class UserProfile {
    // Single stored profile. The unique constraint was dropped for CloudKit
    // compatibility (plan-0023 / SchemaV2 — CloudKit forbids `@Attribute(.unique)`);
    // the singleton invariant is now enforced in code by `UserProfileStore`.
    // Inline default keeps the value stable when CloudKit materializes without init.
    private(set) var id: String = "singleton"

    // Every attribute carries an inline default: CloudKit never runs `init`, so a
    // value materialized from a CKRecord must still be valid. Init defaults (below)
    // stay at sensible product values and override these on app-side creation.
    var bodyWeightKg: Double = 0
    var biologicalSex: BiologicalSex = BiologicalSex.male
    var dateOfBirth: Date?
    var guidelineChoice: GuidelineChoice = GuidelineChoice.who
    var weeklyGoalGrams: Double = 0
    var unitSystem: UnitSystem = UnitSystem.metric
    var currency: String = ""
    /// ABV picker step in per-mille. 5 = 0.5 % steps, 1 = 0.1 % steps.
    var abvPrecisionPermille: Int = 5
    var alcoholUnit: AlcoholUnit = AlcoholUnit.standardDrinks

    /// Last-write-wins clock (plan-0023). Set to `.now` on create and on every edit;
    /// drives conflict resolution for the singleton (which has no `uuid`). Inline
    /// default is a sentinel — the V1→V2 migration backfills existing rows, and
    /// `init` sets `.now` on real creation.
    var modifiedDate: Date = Date(timeIntervalSince1970: 0)

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
        self.modifiedDate = .now
    }

    /// Stamp the LWW clock. Call after any edit to a profile field.
    func touch() {
        modifiedDate = .now
    }
}

extension UserProfile {
    static var preview: UserProfile {
        let dob = Calendar.current.date(byAdding: .year, value: -32, to: .now)
        return UserProfile(bodyWeightKg: 80.0, biologicalSex: .male, dateOfBirth: dob,
                           guidelineChoice: .who, weeklyGoalGrams: 100.0, unitSystem: .metric)
    }
}
