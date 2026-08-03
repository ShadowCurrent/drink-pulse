import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// Pins the contract `EventRow` relies on today: a row needs exactly three unit
/// values, and a missing profile falls back to `.standardDrinks` / `.who` /
/// `.metric`. Finding A6-1.
@MainActor
struct RowUnitContextTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// The three fallbacks lifted verbatim from `EventRow`'s computed properties.
    @Test func init_nilProfile_usesEventRowFallbacks() {
        let ctx = RowUnitContext(nil)
        #expect(ctx.alcoholUnit == .standardDrinks)
        #expect(ctx.guideline == .who)
        #expect(ctx.unitSystem == .metric)
        #expect(ctx.density == AlcoholUnit.standardDrinks.density(for: .who))
    }

    /// A configured profile's three unit values pass through unchanged — no fallback
    /// leaks in. (`.grams` is the non-default `AlcoholUnit` case; the plan's `.units`
    /// case was retired in plan-0029 and folded into `.standardDrinks`.)
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

    /// The property that lets SwiftUI skip a row body when an unrelated profile field
    /// (body weight, date of birth, weekly goal) changes: two profiles differing only
    /// in those fields produce equal contexts.
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
