import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
extension DashboardViewModelTests {

    // MARK: - guidelineDisplayName (SB-1)

    @Test func guidelineDisplayName_matchesLocalized_forAllCases() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        for choice in GuidelineChoice.allCases {
            let profile = UserProfile(guidelineChoice: choice)
            c.mainContext.insert(profile)
            vm.profile = profile
            #expect(
                vm.guidelineDisplayName == choice.displayName,
                "Mismatch for \(choice): got '\(vm.guidelineDisplayName)', expected '\(choice.displayName)'"
            )
            c.mainContext.delete(profile)
        }
    }

    // MARK: - alcoholUnit / guidelineChoice fallbacks

    @Test func alcoholUnit_fallsBackToStandardDrinks_whenNoProfile() {
        let vm = DashboardViewModel()
        vm.profile = nil
        #expect(vm.alcoholUnit == .standardDrinks)
    }

    @Test func guidelineChoice_fallsBackToWHO_whenNoProfile() {
        let vm = DashboardViewModel()
        vm.profile = nil
        #expect(vm.guidelineChoice == .who)
    }

    // MARK: - formattedAlcohol / formattedNumber (SB-5)

    @Test func formattedAlcohol_gramsUnit_includesValueAndLabel() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        let result = vm.formattedAlcohol(20.0)
        #expect(result.contains("20.0"))
        #expect(result.contains(AlcoholUnit.grams.unitLabel(for: .who)))
    }

    @Test func formattedAlcohol_standardDrinks_whoGuideline() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .who, alcoholUnit: .standardDrinks)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        let result = vm.formattedAlcohol(20.0)
        #expect(result.contains("2.0"))
    }

    @Test func formattedNumber_returnsValueWithoutLabel() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        let result = vm.formattedNumber(20.0)
        #expect(result == "20.0")
        #expect(!result.contains(AlcoholUnit.grams.unitLabel(for: .who)))
    }

    // MARK: - limitRuleCaption (plan 0046 review)

    @Test func test_limitRuleCaption_isDailyLimit_whenGuidelineHasDailyLimit() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(vm.limitRuleCaption == "Daily limit")
    }

    /// UK has no daily limit; the rule sits at weekly / 7, a daily average.
    @Test func test_limitRuleCaption_isDailyAverage_whenGuidelineHasNoDailyLimit() throws {
        let c = try makeContainer()
        // Only UK: a custom goal derives its daily limit as weekly / 7 (`effectiveLimits`).
        for choice in [GuidelineChoice.uk] {
            let profile = UserProfile(guidelineChoice: choice)
            c.mainContext.insert(profile)
            let vm = DashboardViewModel()
            vm.profile = profile
            #expect(vm.dailyLimitGrams == 0)
            #expect(vm.limitRuleCaption == "Daily average", "for \(choice)")
        }
    }
}
