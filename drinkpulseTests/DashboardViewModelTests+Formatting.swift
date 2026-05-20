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

    // MARK: - greetingText

    @Test func greetingText_morningBeforeNoon() {
        let vm = DashboardViewModel()
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = 8; comps.minute = 0; comps.second = 0
        vm.now = Calendar.current.date(from: comps) ?? .now
        #expect(vm.greetingText == String(localized: "dashboard.greeting.morning"))
    }

    @Test func greetingText_afternoonBetweenNoonAnd6pm() {
        let vm = DashboardViewModel()
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = 14; comps.minute = 0; comps.second = 0
        vm.now = Calendar.current.date(from: comps) ?? .now
        #expect(vm.greetingText == String(localized: "dashboard.greeting.afternoon"))
    }

    @Test func greetingText_eveningAt6pmOrLater() {
        let vm = DashboardViewModel()
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = 19; comps.minute = 0; comps.second = 0
        vm.now = Calendar.current.date(from: comps) ?? .now
        #expect(vm.greetingText == String(localized: "dashboard.greeting.evening"))
    }

    // MARK: - alcoholUnit / guidelineChoice fallbacks

    @Test func alcoholUnit_fallsBackToUnits_whenNoProfile() {
        let vm = DashboardViewModel()
        vm.profile = nil
        #expect(vm.alcoholUnit == .units)
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
        #expect(result.contains(AlcoholUnit.grams.unitLabel))
    }

    @Test func formattedAlcohol_standardDrinks_whoGuideline() throws {
        let c = try makeContainer()
        // WHO: 1 standard drink = 10 g → 20 g = 2.0 drinks
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
        #expect(!result.contains(AlcoholUnit.grams.unitLabel))
    }

    // MARK: - formattedSpend (SB-5)

    @Test func formattedSpend_USD_containsAmountAndIsNonEmpty() throws {
        let c = try makeContainer()
        let profile = UserProfile(currency: "USD")
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        let result = vm.formattedSpend(10.0)
        #expect(!result.isEmpty)
        #expect(result.contains("10"))
    }

    @Test func formattedSpend_PLN_containsAmount() throws {
        let c = try makeContainer()
        let profile = UserProfile(currency: "PLN")
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        let result = vm.formattedSpend(25.0)
        #expect(!result.isEmpty)
        #expect(result.contains("25"))
    }
}
