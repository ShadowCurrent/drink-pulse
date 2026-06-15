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
        vm.profile = gramsProfile(in: c.mainContext)
        vm.events = [event(daysAgo: 29, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(abs(vm.thirtyDayGrams - 20) < 0.01)
    }

    @Test func thirtyDayGrams_excludesEventFromDay30() throws {
        // Today = day 1; day 30 = 29 days ago is the last included day.
        // An event 30 days ago is outside the window.
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 30, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.thirtyDayGrams == 0)
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
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // WHO male weekly = 100 g (daily×5; plan-0028 fix) → 30-day = 100 × 30 / 7 ≈ 428.57 g
        #expect(abs(vm.thirtyDayLimitGrams - 100.0 * 30 / 7) < 0.001)
    }

    // MARK: - effectiveDailyLimitGrams

    @Test func effectiveDailyLimit_usesActualDailyWhenNonZero() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(vm.effectiveDailyLimitGrams == vm.dailyLimitGrams)
    }

    @Test func effectiveDailyLimit_fallsBackToWeeklyOver7_forUK() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .uk, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(vm.dailyLimitGrams == 0)
        #expect(abs(vm.effectiveDailyLimitGrams - vm.weeklyLimitGrams / 7) < 0.001)
    }

    // MARK: - todayPct

    @Test func todayPct_isZero_whenNoEvents() {
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.todayPct == 0)
    }

    @Test func todayPct_isCorrect_atHalfDailyLimit() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 10, in: c.mainContext)] // WHO male daily = 20g
        vm.now = .now
        #expect(abs(vm.todayPct - 0.5) < 0.001)
    }

    @Test func todayPct_exceedsOne_whenOverDailyLimit() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 30, in: c.mainContext)] // 30g > 20g limit
        vm.now = .now
        #expect(vm.todayPct > 1.0)
    }

    @Test func todayPct_usesEffectiveDailyLimit_forUKGuideline() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .uk, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // UK: daily = 0, weekly = 112 g (14 × 8.0), effective daily = 112/7 = 16.0 g.
        // Consume exactly half: 8.0 g → todayPct = 0.5 (grams mode).
        vm.events = [event(daysAgo: 0, grams: 8.0, in: c.mainContext)]
        vm.now = .now
        #expect(abs(vm.todayPct - 0.5) < 0.001)
    }

    // MARK: - todayPct exactness across display units (plan-0025: clean math, no drift)

    @Test func todayPct_unitsMode_oneBeerIs100PctOfWHODaily() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .units)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // 500 ml × 5 % at 0.8 g/ml = 20.0 g mode-mass = exactly the 20 g WHO daily limit.
        let e = ConsumptionEvent(timestamp: .now, volumeMl: 500, abv: 0.05,
                                 name: "Beer", category: .beer, icon: "🍺")
        c.mainContext.insert(e)
        vm.events = [e]
        vm.now = .now
        #expect(abs(vm.todayGrams - 20.0) < 1e-9)
        #expect(abs(vm.todayPct - 1.0) < 1e-9)
        #expect(vm.formattedNumber(vm.todayGrams) == "2.0")
        #expect(vm.todayRiskLevel == .caution) // 100 % is caution, not exceeded
    }

    @Test func todayPct_unitsMode_tenBeersIs1000Pct() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .units)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        let e = ConsumptionEvent(timestamp: .now, volumeMl: 500, abv: 0.05, quantity: 10,
                                 name: "Beer", category: .beer, icon: "🍺")
        c.mainContext.insert(e)
        vm.events = [e]
        vm.now = .now
        #expect(abs(vm.todayGrams - 200.0) < 1e-9)
        #expect(abs(vm.todayPct - 10.0) < 1e-9)
        #expect(vm.formattedNumber(vm.todayGrams) == "20.0")
    }

    @Test func todayPct_gramsMode_oneBeerIs98Point6Pct() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // Grams mode keeps scientific 0.789: 500 ml × 5 % = 19.725 g, 98.6 % of 20 g.
        let e = ConsumptionEvent(timestamp: .now, volumeMl: 500, abv: 0.05,
                                 name: "Beer", category: .beer, icon: "🍺")
        c.mainContext.insert(e)
        vm.events = [e]
        vm.now = .now
        #expect(abs(vm.todayGrams - 19.725) < 1e-9)
        #expect(abs(vm.todayPct - 0.98625) < 1e-6)
        #expect(vm.formattedNumber(vm.todayGrams) == "19.7")
    }

    @Test func todayCalories_sameAcrossDisplayUnits() throws {
        // Calories use physical 0.789 regardless of the chosen display unit.
        let c1 = try makeContainer()
        let c2 = try makeContainer()
        let unitsP = UserProfile(guidelineChoice: .who, alcoholUnit: .units)
        let gramsP = UserProfile(guidelineChoice: .who, alcoholUnit: .grams)
        c1.mainContext.insert(unitsP)
        c2.mainContext.insert(gramsP)
        let e1 = ConsumptionEvent(timestamp: .now, volumeMl: 500, abv: 0.05,
                                  name: "Beer", category: .beer, icon: "🍺")
        let e2 = ConsumptionEvent(timestamp: .now, volumeMl: 500, abv: 0.05,
                                  name: "Beer", category: .beer, icon: "🍺")
        c1.mainContext.insert(e1)
        c2.mainContext.insert(e2)
        let unitsVM = DashboardViewModel(); unitsVM.profile = unitsP; unitsVM.events = [e1]; unitsVM.now = .now
        let gramsVM = DashboardViewModel(); gramsVM.profile = gramsP; gramsVM.events = [e2]; gramsVM.now = .now
        #expect(unitsVM.todayCaloriesKcal == gramsVM.todayCaloriesKcal)
        #expect(unitsVM.todayCaloriesKcal == 140) // 19.725 g × 7.1 ≈ 140
    }

    // MARK: - weeklyGrams

    @Test func weeklyGrams_sumsCurrentCalendarWeekOnly() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.profile = gramsProfile(in: c.mainContext)
        // 8 days ago is always in a previous calendar week, regardless of firstWeekday
        vm.events = [
            event(daysAgo: 0, grams: 30, in: c.mainContext),
            event(daysAgo: 8, grams: 50, in: c.mainContext),
        ]
        vm.now = .now
        #expect(abs(vm.weeklyGrams - 30) < 0.01)
    }

    // MARK: - weeklyGrams locale-aware (Sunday-first vs Monday-first)

    // Pin now = Wed 2026-05-27 and event = Sun 2026-05-24 (noon).
    // Sun-first week: 05-24…05-30 → event IS in the current week.
    // Mon-first week: 05-25…05-31 → event falls in the PREVIOUS week.

    private func calendar(firstWeekday: Int) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = firstWeekday
        return cal
    }

    private func eventOnDate(_ components: DateComponents, grams: Double, in context: ModelContext) -> ConsumptionEvent {
        let ts = Calendar.current.date(from: components)!.addingTimeInterval(12 * 3600)
        let abv = grams / (500 * 0.789)
        let e = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: abv,
                                 name: "Test", category: .beer, icon: "🍺")
        context.insert(e)
        return e
    }

    @Test func weeklyGrams_includesPrecedingSunday_whenWeekStartsSunday() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.profile = gramsProfile(in: c.mainContext)
        vm.calendar = calendar(firstWeekday: 1) // Sunday-first
        vm.now = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 27))!
        vm.events = [eventOnDate(DateComponents(year: 2026, month: 5, day: 24), grams: 20, in: c.mainContext)]
        #expect(abs(vm.weeklyGrams - 20) < 0.01)
    }

    @Test func weeklyGrams_excludesPrecedingSunday_whenWeekStartsMonday() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.calendar = calendar(firstWeekday: 2) // Monday-first
        vm.now = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 27))!
        vm.events = [eventOnDate(DateComponents(year: 2026, month: 5, day: 24), grams: 20, in: c.mainContext)]
        #expect(vm.weeklyGrams == 0)
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
