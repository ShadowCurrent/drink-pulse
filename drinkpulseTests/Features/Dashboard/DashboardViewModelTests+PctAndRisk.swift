import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
extension DashboardViewModelTests {

    // MARK: - todayPct

    @Test func todayPct_zeroWhenNoEvents_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = []
        vm.now = .now
        #expect(vm.todayPct == 0)
    }

    @Test func todayPct_halfWhenAtHalfDailyLimit_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 10, in: c.mainContext)]
        vm.now = .now
        #expect(abs(vm.todayPct - 0.5) < 0.01)
    }

    @Test func todayPct_exceedsOneWhenOverDailyLimit_rawNotClamped() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 40, in: c.mainContext)]
        vm.now = .now
        #expect(vm.todayPct > 1.0)
        #expect(abs(vm.todayPct - 2.0) < 0.01)
    }

    // MARK: - todayRiskLevel

    @Test func todayRiskLevel_safe_at49pct_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 9.8, in: c.mainContext)]
        vm.now = .now
        #expect(vm.todayRiskLevel == .safe)
    }

    @Test func todayRiskLevel_caution_at75pct_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 15, in: c.mainContext)]
        vm.now = .now
        #expect(vm.todayRiskLevel == .caution)
    }

    @Test func todayRiskLevel_caution_atExactDailyLimit_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.todayRiskLevel == .caution)
    }

    @Test func todayRiskLevel_exceeded_overDailyLimit_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 20.1, in: c.mainContext)]
        vm.now = .now
        #expect(vm.todayRiskLevel == .exceeded)
    }

    // MARK: - fraction / riskLevel (exact; used by overview rows & week-chart bars)

    @Test func fraction_isExactRatio_modeMassVsLimit() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .standardDrinks)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(abs(vm.fraction(consumedGrams: 20, limitGrams: 20) - 1.0) < 1e-9)
        #expect(abs(vm.fraction(consumedGrams: 10, limitGrams: 20) - 0.5) < 1e-9)
    }

    @Test func riskLevel_caution_atExactLimit() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .standardDrinks)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(vm.riskLevel(consumedGrams: 20, limitGrams: 20) == .caution)
        #expect(vm.riskLevel(consumedGrams: 20.1, limitGrams: 20) == .exceeded)
        #expect(vm.riskLevel(consumedGrams: 9, limitGrams: 20) == .safe)
    }

    @Test func fraction_isZero_whenLimitIsZero() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .standardDrinks)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(vm.fraction(consumedGrams: 10, limitGrams: 0) == 0)
    }

    // MARK: - effectiveRiskLevel

    @Test func effectiveRiskLevel_exceededWhenDailyExceeded_weeklyLow() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 40, in: c.mainContext)]
        vm.now = .now
        #expect(vm.effectiveRiskLevel == .exceeded)
    }

    @Test func effectiveRiskLevel_exceededWhenWeeklyExceeded_dailyLow() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = (1...6).map { event(daysAgo: $0, grams: 25, in: c.mainContext) }
        vm.now = .now
        #expect(vm.effectiveRiskLevel == .exceeded)
    }

    @Test func effectiveRiskLevel_safeWhenBothLow() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 8, in: c.mainContext)]
        vm.now = .now
        #expect(vm.effectiveRiskLevel == .safe)
    }
}
