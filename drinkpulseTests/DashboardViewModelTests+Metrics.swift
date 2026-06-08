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

    // MARK: - todayPct

    @Test func todayPct_isZero_whenNoEvents() {
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.todayPct == 0)
    }

    @Test func todayPct_isCorrect_atHalfDailyLimit() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 10, in: c.mainContext)] // WHO male daily = 20g
        vm.now = .now
        #expect(abs(vm.todayPct - 0.5) < 0.001)
    }

    @Test func todayPct_exceedsOne_whenOverDailyLimit() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 30, in: c.mainContext)] // 30g > 20g limit
        vm.now = .now
        #expect(vm.todayPct > 1.0)
    }

    @Test func todayPct_usesEffectiveDailyLimit_forUKGuideline() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .uk)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // UK: daily = 0, weekly = 110.46 g, effective daily = 110.46/7 = 15.78 g
        // Consume exactly half: 15.78/2 = 7.89 g → todayPct = 0.5
        vm.events = [event(daysAgo: 0, grams: 7.89, in: c.mainContext)]
        vm.now = .now
        #expect(abs(vm.todayPct - 0.5) < 0.001)
    }

    // MARK: - todayDisplayPct (arc agrees with rounded "X / Y unit" copy)

    @Test func todayDisplayPct_agreesWithRoundedUnits() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .units)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // 9.86 g pure alcohol displays as "1.0 units" (9.86/10 → 1.0) against the
        // 2.0-unit (20 g) WHO daily limit. The arc must read 50%, not 49%.
        vm.events = [event(daysAgo: 0, grams: 9.86, in: c.mainContext)]
        vm.now = .now
        #expect(vm.alcoholUnit == .units)
        #expect(abs(vm.todayDisplayPct - 0.5) < 0.0001)
        // The raw-gram pct intentionally differs here (this is the reported mismatch).
        #expect(Int((vm.todayPct * 100).rounded()) == 49)
    }

    @Test func todayDisplayPct_agreesWithRoundedStandardDrinks() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who,
                                  alcoholUnit: .standardDrinks)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // WHO standard drink = 10 g. 9.86 g → "1.0 drinks" against the 2.0-drink
        // (20 g) limit → arc 50%, same as units mode.
        vm.events = [event(daysAgo: 0, grams: 9.86, in: c.mainContext)]
        vm.now = .now
        #expect(vm.alcoholUnit == .standardDrinks)
        #expect(abs(vm.todayDisplayPct - 0.5) < 0.0001)
        #expect(Int((vm.todayPct * 100).rounded()) == 49)
    }

    @Test func todayDisplayPct_standardDrinks_usGuideline() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .us,
                                  alcoholUnit: .standardDrinks)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // US standard drink = 14 g, US male daily limit = 28 g (2.0 drinks).
        // 13.7 g → 0.978 → "1.0 drinks" → arc 50% (raw grams would be 49%).
        vm.events = [event(daysAgo: 0, grams: 13.7, in: c.mainContext)]
        vm.now = .now
        #expect(abs(vm.todayDisplayPct - 0.5) < 0.0001)
        #expect(Int((vm.todayPct * 100).rounded()) == 49)
    }

    @Test func todayDisplayPct_matchesRawPct_inGramsMode() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        // In grams mode the displayed value isn't rounded to whole units, so the
        // display pct tracks the raw pct (both 49%).
        vm.events = [event(daysAgo: 0, grams: 9.8, in: c.mainContext)]
        vm.now = .now
        #expect(Int((vm.todayDisplayPct * 100).rounded()) == 49)
    }

    // MARK: - weeklyGrams

    @Test func weeklyGrams_sumsCurrentCalendarWeekOnly() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
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
