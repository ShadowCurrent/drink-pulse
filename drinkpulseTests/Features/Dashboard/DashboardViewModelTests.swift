import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct DashboardViewModelTests {

    func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func event(daysAgo: Int = 0, grams target: Double = 20.0, in context: ModelContext) -> ConsumptionEvent {
        let cal = Calendar.current
        let base = cal.startOfDay(for: Date.now).addingTimeInterval(12 * 3600) // noon
        let ts = cal.date(byAdding: .day, value: -daysAgo, to: base) ?? base
        // 500 ml × abv × 0.789 = target g → abv = target / 394.5
        let abv = target / (500 * 0.789)
        let e = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: abv,
                                 name: "Test", category: .beer, icon: "🍺")
        context.insert(e)
        return e
    }

    // The `event` helper bakes 0.789 (physical) density, so a grams-mode profile makes
    // todayGrams/sevenDayGrams etc. equal the requested target exactly. Tests asserting
    // exact gram sums use this; unit-conversion behaviour is covered separately.
    @discardableResult
    func gramsProfile(in context: ModelContext) -> UserProfile {
        let p = UserProfile(guidelineChoice: .who, alcoholUnit: .grams)
        context.insert(p)
        return p
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
        vm.profile = gramsProfile(in: c.mainContext)
        vm.events = [event(daysAgo: 0, grams: 20, in: c.mainContext)]
        vm.now = .now
        let todayEntry = vm.weekBarData.first(where: \.isToday)
        #expect(todayEntry != nil)
        #expect(abs((todayEntry?.grams ?? 0) - 20) < 0.01)
    }

    @Test func weekBarData_todayHasZeroGramsWithNoEvents() {
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        let todayEntry = vm.weekBarData.first(where: \.isToday)
        #expect(todayEntry?.grams == 0)
    }

    @Test func weekBarData_todayGramsExceedsDailyLimit_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
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
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.profile = gramsProfile(in: c.mainContext)
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
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = []
        vm.now = .now
        #expect(vm.riskLevel == .safe)
    }

    @Test func riskLevel_caution_at60pct_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 60, in: c.mainContext)] // 60 / 100 = 60%
        vm.now = .now
        #expect(vm.riskLevel == .caution)
    }

    @Test func riskLevel_exceeded_at110pct_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 110, in: c.mainContext)] // 110 / 100 = 110%
        vm.now = .now
        #expect(vm.riskLevel == .exceeded)
    }

    @Test func riskLevel_safe_exactlyAt49pct_whoMale() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 49, in: c.mainContext)] // 49 / 100 = 49%
        vm.now = .now
        #expect(vm.riskLevel == .safe)
    }

    @Test func riskLevel_cautionWhenYesterdayExceedsWith60pct() throws {
        let c = try makeContainer()
        let profile = UserProfile(biologicalSex: .male, guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        let vm = DashboardViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 1, grams: 60, in: c.mainContext)] // 60 / 100 = 60%
        vm.now = .now
        #expect(vm.riskLevel == .caution)
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
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 3, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.currentStreakDays == 2)
    }

    @Test func currentStreak_countsBrokenByDrinkYesterday() throws {
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
        vm.profile = gramsProfile(in: c.mainContext)
        vm.events = [event(daysAgo: 1, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(abs(vm.sevenDayGrams - 20) < 0.01)
    }

    @Test func sevenDayGrams_includesEventFromDay6() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.profile = gramsProfile(in: c.mainContext)
        vm.events = [event(daysAgo: 6, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(abs(vm.sevenDayGrams - 20) < 0.01)
    }

    @Test func sevenDayGrams_excludesEventFromDay7() throws {
        // Today = day 1; day 7 = 6 days ago is the last included day.
        // An event 7 days ago is outside the window.
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 7, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.sevenDayGrams == 0)
    }

    @Test func sevenDayGrams_excludesEventFromDay8() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 8, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.sevenDayGrams == 0)
    }

    // MARK: - soberDaysThisMonth

    @Test func soberDaysThisMonth_zeroWhenNoEvents() {
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.soberDaysThisMonth == 0)
    }

    @Test func soberDaysThisMonth_zeroWhenFirstAndOnlyEntryIsTodayWithDrink() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 0, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.soberDaysThisMonth == 0)
    }

    @Test func soberDaysThisMonth_excludesTodayIfDrank_withPriorHistory() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [
            event(daysAgo: 31, grams: 20, in: c.mainContext),
            event(daysAgo: 0,  grams: 20, in: c.mainContext),
        ]
        vm.now = .now
        let dayOfMonth = Calendar.current.component(.day, from: Date.now)
        #expect(vm.soberDaysThisMonth == dayOfMonth - 1)
    }

    @Test func soberDaysThisMonth_countsFromFirstEntryWhenInCurrentMonth() throws {
        let c = try makeContainer()
        let vm = DashboardViewModel()
        vm.events = [event(daysAgo: 1, grams: 20, in: c.mainContext)]
        vm.now = .now
        #expect(vm.soberDaysThisMonth == 1)
    }

}
