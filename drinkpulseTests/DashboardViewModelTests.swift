import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct DashboardViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func event(daysAgo: Int = 0, grams target: Double = 20.0, in context: ModelContext) -> ConsumptionEvent {
        let cal = Calendar.current
        let base = cal.startOfDay(for: Date.now).addingTimeInterval(12 * 3600) // noon
        let ts = cal.date(byAdding: .day, value: -daysAgo, to: base) ?? base
        // 500 ml × 0.05 × 0.8 = 20 g. Scale abv to hit target.
        let abv = target / (500 * 0.8)
        let e = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: abv,
                                 name: "Test", category: .beer, icon: "🍺")
        context.insert(e)
        return e
    }

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

    // MARK: - weekBarData

    @Test func weekBarData_alwaysSevenEntries() {
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.weekBarData.count == 7)
    }

    @Test func weekBarData_exactlyOneIsToday() {
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.weekBarData.filter(\.isToday).count == 1)
    }

    @Test func weekBarData_futureEntriesHaveZeroGrams() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 0, grams: 30, in: c.mainContext)]
        vm.now = .now
        let futureEntries = vm.weekBarData.filter(\.isFuture)
        #expect(futureEntries.allSatisfy { $0.grams == 0 })
    }

    @Test func weekBarData_todayEntryReflectsActualGrams() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 0, grams: 20, in: c.mainContext)]
        vm.now = .now
        let todayEntry = vm.weekBarData.first(where: \.isToday)
        #expect(todayEntry != nil)
        #expect(abs((todayEntry?.grams ?? 0) - 20) < 0.01)
    }

    @Test func weekBarData_todayHasZeroGramsWithNoEvents() {
        // Confirms today's bar starts at 0 — chart Y scale must not collapse to chartFloor.
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        let todayEntry = vm.weekBarData.first(where: \.isToday)
        #expect(todayEntry?.grams == 0)
    }

    @Test func weekBarData_todayGramsExceedsDailyLimit_whoMale() throws {
        // WHO male daily limit = 20 g. Insert 25 g today → strictly over limit.
        // Confirms the data inputs that barColor uses to choose amber over teal.
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 25, in: c.mainContext)]
        vm.now = .now
        let todayEntry = vm.weekBarData.first(where: \.isToday)!
        #expect(todayEntry.grams > vm.effectiveDailyLimitGrams)
        #expect(vm.effectiveDailyLimitGrams == 20)
    }

    @Test func weekBarData_todayGramsUpdateWhenEventsChange() throws {
        // Confirms the VM data layer updates correctly when events are replaced.
        // Any rendering failure after this is a SwiftUI/Charts issue, not a VM bug.
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.weekBarData.first(where: \.isToday)?.grams == 0)

        vm.events = [event(daysAgo: 0, grams: 30, in: c.mainContext)]
        let todayGrams = vm.weekBarData.first(where: \.isToday)?.grams ?? 0
        #expect(abs(todayGrams - 30) < 0.01)
    }

    // MARK: - riskLevel

    @Test func riskLevel_safe_whenNoEvents_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = []
        vm.now = .now
        #expect(vm.riskLevel == .safe)
    }

    @Test func riskLevel_caution_at60pct_whoMale() throws {
        // WHO male weekly = 100 g. 60 g = 60% → caution
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 60, in: c.mainContext)]
        vm.now = .now
        #expect(vm.riskLevel == .caution)
    }

    @Test func riskLevel_exceeded_at110pct_whoMale() throws {
        // WHO male weekly = 100 g. 110 g → exceeded
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 110, in: c.mainContext)]
        vm.now = .now
        #expect(vm.riskLevel == .exceeded)
    }

    @Test func riskLevel_safe_exactlyAt49pct_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 49, in: c.mainContext)]
        vm.now = .now
        #expect(vm.riskLevel == .safe)
    }

    // MARK: - currentStreakDays

    @Test func currentStreak_zeroWhenDrankToday() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 0, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.currentStreakDays == 0)
    }

    @Test func currentStreak_zeroWhenNoHistory() {
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.currentStreakDays == 0)
    }

    @Test func currentStreak_twoWhenDrankThreeDaysAgo() throws {
        // Day -3: drink. Day -2, -1: sober. Today: sober.
        // Streak counts consecutive sober days ending yesterday → 2
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 3, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.currentStreakDays == 2)
    }

    @Test func currentStreak_countsBrokenByDrinkYesterday() throws {
        // Yesterday had a drink → streak = 0 even if today is sober
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 1, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.currentStreakDays == 0)
    }

    // MARK: - sevenDayGrams

    @Test func sevenDayGrams_includesEventFromYesterday() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 1, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(abs(vm.sevenDayGrams - 20) < 0.01)
    }

    @Test func sevenDayGrams_includesEventFromDay6() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 6, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(abs(vm.sevenDayGrams - 20) < 0.01)
    }

    @Test func sevenDayGrams_excludesEventFromDay8() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 8, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.sevenDayGrams == 0)
    }

    @Test func riskLevel_cautionWhenYesterdayExceedsWith60pct() throws {
        // Verifies rolling-window: event from yesterday still counts toward weeklyPct.
        // WHO male weekly = 100 g. 60 g yesterday → 60% → caution.
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 1, grams: 60, in: c.mainContext)]
        vm.now = .now
        #expect(vm.riskLevel == .caution)
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

    // MARK: - effectiveDailyLimitGrams

    @Test func effectiveDailyLimit_usesActualDailyWhenNonZero() throws {
        // WHO male: dailyGrams = 20, weeklyGrams = 100
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(vm.effectiveDailyLimitGrams == vm.dailyLimitGrams)
    }

    @Test func effectiveDailyLimit_fallsBackToWeeklyOver7_forUK() throws {
        // UK guideline has dailyGrams == 0; fallback = weeklyGrams / 7
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .uk)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        #expect(vm.dailyLimitGrams == 0)
        #expect(abs(vm.effectiveDailyLimitGrams - vm.weeklyLimitGrams / 7) < 0.001)
    }

    // MARK: - soberDaysThisMonth

    @Test func soberDaysThisMonth_zeroWhenNoEvents() {
        // No entries → no tracking baseline → 0, not the number of days in the month.
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.soberDaysThisMonth == 0)
    }

    @Test func soberDaysThisMonth_zeroWhenFirstAndOnlyEntryIsTodayWithDrink() throws {
        // First entry = today (drinking). countFrom = today. Today not sober → 0.
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 0, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.soberDaysThisMonth == 0)
    }

    @Test func soberDaysThisMonth_excludesTodayIfDrank_withPriorHistory() throws {
        // Prior history from before this month + drink today.
        // countFrom = start of month; today has drink → dayOfMonth - 1 sober days.
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [
            event(daysAgo: 31, grams: 20, in: c.mainContext), // always in previous month
            event(daysAgo: 0,  grams: 20, in: c.mainContext),
        ]
        vm.now = .now
        let dayOfMonth = Calendar.current.component(.day, from: Date.now)
        #expect(vm.soberDaysThisMonth == dayOfMonth - 1)
    }

    @Test func soberDaysThisMonth_countsFromFirstEntryWhenInCurrentMonth() throws {
        // First entry = yesterday (drinking). countFrom = yesterday.
        // Yesterday not sober; today (no drink) is sober → exactly 1 sober day.
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 1, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.soberDaysThisMonth == 1)
    }
}
