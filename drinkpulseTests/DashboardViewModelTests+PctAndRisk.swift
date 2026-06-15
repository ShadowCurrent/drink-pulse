import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
extension DashboardViewModelTests {

    // MARK: - todayPct

    @Test func todayPct_zeroWhenNoEvents_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = []
        vm.now = .now
        #expect(vm.todayPct == 0)
    }

    @Test func todayPct_halfWhenAtHalfDailyLimit_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // WHO male daily limit = 20 g; half = 10 g
        vm.events = [event(daysAgo: 0, grams: 10, in: c.mainContext)]
        vm.now = .now
        #expect(abs(vm.todayPct - 0.5) < 0.01)
    }

    @Test func todayPct_exceedsOneWhenOverDailyLimit_rawNotClamped() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // WHO male daily limit = 20 g; 40 g = 200%
        vm.events = [event(daysAgo: 0, grams: 40, in: c.mainContext)]
        vm.now = .now
        #expect(vm.todayPct > 1.0)
        #expect(abs(vm.todayPct - 2.0) < 0.01)
    }

    // MARK: - todayRiskLevel

    @Test func todayRiskLevel_safe_at49pct_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 9.8, in: c.mainContext)]
        vm.now = .now
        #expect(vm.todayRiskLevel == .safe)
    }

    @Test func todayRiskLevel_caution_at75pct_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 15, in: c.mainContext)]
        vm.now = .now
        #expect(vm.todayRiskLevel == .caution)
    }

    @Test func todayRiskLevel_caution_atExactDailyLimit_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // WHO male daily limit = 20 g; exactly 100% → caution, not exceeded
        vm.events = [event(daysAgo: 0, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.todayRiskLevel == .caution)
    }

    @Test func todayRiskLevel_exceeded_overDailyLimit_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // WHO male daily limit = 20 g; 20.1 g > 100% → exceeded
        vm.events = [event(daysAgo: 0, grams: 20.1, in: c.mainContext)]
        vm.now = .now
        #expect(vm.todayRiskLevel == .exceeded)
    }

    // MARK: - displayPct / displayRiskLevel
    // (overview rows & week-chart bars must agree with the rounded "X / Y unit" copy)

    @Test func displayPct_reads100Pct_whenRoundedUnitsEqualLimit_whoUnits() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .units)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // 19.6 g displays as "2.0 units" against the 2.0-unit (20 g) daily limit.
        // The badge must read 100 %, not the raw-gram 98 % that was reported.
        let pct = vm.displayPct(consumedGrams: 19.6, limitGrams: vm.effectiveDailyLimitGrams)
        #expect(Int(pct * 100) == 100)
        #expect(Int(19.6 / vm.effectiveDailyLimitGrams * 100) == 98) // the reported mismatch
    }

    @Test func displayRiskLevel_caution_whenRoundedUnitsAtLimit_whoUnits() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .units)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // 19.6 g → 2.0 units == 2.0-unit limit → 100 % → caution (≤ 1.0), not exceeded.
        #expect(vm.displayRiskLevel(consumedGrams: 19.6, limitGrams: vm.effectiveDailyLimitGrams) == .caution)
    }

    @Test func displayPct_matchesRawPct_inGramsMode() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // Grams mode rounds only to 0.1 g, so the display pct tracks the raw pct.
        let pct = vm.displayPct(consumedGrams: 9.8, limitGrams: vm.effectiveDailyLimitGrams)
        #expect(abs(pct - 0.49) < 0.005)
    }

    @Test func displayPct_isZero_whenLimitIsZero() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .units)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(vm.displayPct(consumedGrams: 10, limitGrams: 0) == 0)
    }

    // MARK: - effectiveRiskLevel

    @Test func effectiveRiskLevel_exceededWhenDailyExceeded_weeklyLow() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // 40 g today -> daily exceeded; 40 g this week < weekly limit (100 g)
        vm.events = [event(daysAgo: 0, grams: 40, in: c.mainContext)]
        vm.now = .now
        #expect(vm.effectiveRiskLevel == .exceeded)
    }

    @Test func effectiveRiskLevel_exceededWhenWeeklyExceeded_dailyLow() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // spread 150 g over 7 days (no day > daily limit) -> weekly exceeded
        vm.events = (1...6).map { event(daysAgo: $0, grams: 25, in: c.mainContext) }
        vm.now = .now
        #expect(vm.effectiveRiskLevel == .exceeded)
    }

    @Test func effectiveRiskLevel_safeWhenBothLow() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 8, in: c.mainContext)]
        vm.now = .now
        #expect(vm.effectiveRiskLevel == .safe)
    }
}
