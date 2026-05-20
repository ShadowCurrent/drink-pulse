import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
extension DashboardViewModelTests {

    // MARK: - todayCaloriesKcal

    @Test func todayCaloriesKcal_20g_gives_142kcal() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 0, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.todayCaloriesKcal == 142)
    }

    @Test func todayCaloriesKcal_zeroGrams_givesZero() {
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.todayCaloriesKcal == 0)
    }

    // MARK: - todayDrinkCount

    @Test func todayDrinkCount_zeroWithNoEventsToday() {
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.todayDrinkCount == 0)
    }

    @Test func todayDrinkCount_countsOnlyTodayEvents() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [
            event(daysAgo: 0, grams: 20, in: c.mainContext),
            event(daysAgo: 0, grams: 20, in: c.mainContext),
            event(daysAgo: 1, grams: 20, in: c.mainContext),
        ]
        vm.now = .now
        #expect(vm.todayDrinkCount == 2)
    }

    // MARK: - todaySpend (SB-6)

    @Test func todaySpend_nilWhenAllEventsHaveNilPrice() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 0, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.todaySpend == nil)
    }

    @Test func todaySpend_sumsNonNilPricesOnly() throws {
        let c = try makeContainer()
        let ts = Calendar.current.startOfDay(for: .now).addingTimeInterval(12 * 3600)
        let e1 = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: 0.05,
                                  name: "Beer", category: .beer, icon: "🍺", price: 5.0)
        let e2 = ConsumptionEvent(timestamp: ts, volumeMl: 175, abv: 0.135,
                                  name: "Wine", category: .wine, icon: "🍷", price: nil)
        let e3 = ConsumptionEvent(timestamp: ts, volumeMl: 50, abv: 0.40,
                                  name: "Spirit", category: .spirits, icon: "🥃", price: 8.0)
        c.mainContext.insert(e1); c.mainContext.insert(e2); c.mainContext.insert(e3)
        let vm = DashboardViewModel()
        vm.events = [e1, e2, e3]
        vm.now = .now
        #expect(vm.todaySpend == 13.0)
    }

    @Test func todaySpend_excludesYesterdayEvents() throws {
        let c = try makeContainer()
        let ts = Calendar.current.startOfDay(for: .now).addingTimeInterval(-12 * 3600)
        let e = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: 0.05,
                                 name: "Beer", category: .beer, icon: "🍺", price: 5.0)
        c.mainContext.insert(e)
        let vm = DashboardViewModel()
        vm.events = [e]
        vm.now = .now
        #expect(vm.todaySpend == nil)
    }

    // MARK: - thirtyDayGrams

    @Test func thirtyDayGrams_includesEventFromDay29() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 29, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(abs(vm.thirtyDayGrams - 20) < 0.01)
    }

    @Test func thirtyDayGrams_excludesEventFromDay31() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 31, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.thirtyDayGrams == 0)
    }

    // MARK: - thirtyDayLimitGrams

    @Test func thirtyDayLimitGrams_isWeeklyLimitScaledTo30Days() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // WHO male weekly = 100 g → 30-day = 100 × 30 / 7 ≈ 428.57 g
        #expect(abs(vm.thirtyDayLimitGrams - 100.0 * 30 / 7) < 0.001)
    }

    // MARK: - effectiveDailyLimitGrams

    @Test func effectiveDailyLimit_usesActualDailyWhenNonZero() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(vm.effectiveDailyLimitGrams == vm.dailyLimitGrams)
    }

    @Test func effectiveDailyLimit_fallsBackToWeeklyOver7_forUK() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .uk)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(vm.dailyLimitGrams == 0)
        #expect(abs(vm.effectiveDailyLimitGrams - vm.weeklyLimitGrams / 7) < 0.001)
    }

    // MARK: - weeklyGrams

    @Test func weeklyGrams_sumsCurrentCalendarWeekOnly() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        // 8 days ago is always in a previous calendar week
        vm.events = [
            event(daysAgo: 0, grams: 30, in: c.mainContext),
            event(daysAgo: 8, grams: 50, in: c.mainContext),
        ]
        vm.now = .now
        #expect(abs(vm.weeklyGrams - 30) < 0.01)
    }

    // MARK: - limits custom guideline (SB-2)

    @Test func limits_customGuideline_usesWeeklyGoal() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .custom, weeklyGoalGrams: 140)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(vm.weeklyLimitGrams == 140)
        #expect(abs(vm.dailyLimitGrams - 140.0 / 7) < 0.001)
    }

    @Test func limits_customGuideline_zeroGoal_doesNotReturnZeroWeeklyLimit() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .custom, weeklyGoalGrams: 0)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(vm.weeklyLimitGrams > 0)
    }

    @Test func riskLevel_notSafe_whenDrinking_customGuidelineZeroGoal() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .custom, weeklyGoalGrams: 0)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 50, in: c.mainContext)]
        vm.now = .now
        #expect(vm.riskLevel != .safe)
    }
}
