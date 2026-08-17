import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct RowUnitContextTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func init_nilProfile_usesEventRowFallbacks() {
        let ctx = RowUnitContext(nil)
        #expect(ctx.alcoholUnit == .standardDrinks)
        #expect(ctx.guideline == .who)
        #expect(ctx.unitSystem == .metric)
        #expect(ctx.density == AlcoholUnit.standardDrinks.density(for: .who))
    }

    @Test func init_profile_carriesProfileUnitsUnchanged() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .uk, unitSystem: .imperial, alcoholUnit: .grams)
        c.mainContext.insert(profile)

        let ctx = RowUnitContext(profile)
        #expect(ctx.alcoholUnit == .grams)
        #expect(ctx.guideline == .uk)
        #expect(ctx.unitSystem == .imperial)
        #expect(ctx.density == AlcoholUnit.grams.density(for: .uk))
    }

    @Test func equality_profilesDifferingOnlyInBodyMetrics_compareEqual() throws {
        let c = try makeContainer()
        let a = UserProfile(bodyWeightKg: 70, dateOfBirth: Date(timeIntervalSince1970: 0),
                            guidelineChoice: .de, weeklyGoalGrams: 100,
                            unitSystem: .usCustomary, alcoholUnit: .standardDrinks)
        let b = UserProfile(bodyWeightKg: 95, dateOfBirth: Date(timeIntervalSince1970: 1_000_000),
                            guidelineChoice: .de, weeklyGoalGrams: 250,
                            unitSystem: .usCustomary, alcoholUnit: .standardDrinks)
        c.mainContext.insert(a)
        c.mainContext.insert(b)

        #expect(RowUnitContext(a) == RowUnitContext(b))
    }
}
