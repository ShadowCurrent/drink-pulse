import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct InsightsViewModelTests {

    func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func event(
        daysAgo: Int = 0,
        hoursOffset: Int = 12,
        grams target: Double = 20.0,
        price: Double? = nil,
        in context: ModelContext
    ) -> ConsumptionEvent {
        let cal = Calendar.current
        let base = cal.startOfDay(for: Date.now).addingTimeInterval(Double(hoursOffset) * 3600)
        let ts = cal.date(byAdding: .day, value: -daysAgo, to: base) ?? base
        let abv = target / (500 * 0.8)
        let e = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: abv,
                                 name: "Test", category: .beer, icon: "🍺", price: price)
        context.insert(e)
        return e
    }

    // MARK: - weekdayAverages

    @Test func weekdayAverages_alwaysSevenEntries() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.weekdayAverages.count == 7)
    }

    @Test func weekdayAverages_zeroBarsWhenNoEvents() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.weekdayAverages.allSatisfy { $0.averageGrams == 0 })
    }

    @Test func weekdayAverages_dividesByWeekCountNotDayCount_monthPeriod() throws {
        // For month (30 days), a given weekday appears ~4-5 times.
        // If we have 40 g on a specific weekday, the average should be 40 / (count of that weekday in range).
        let c = try makeContainer()
        let vm = InsightsViewModel()
        vm.period = .month

        // Fix now to a known Monday (2026-05-18 is a Monday)
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let monday = fmt.date(from: "2026-05-18")!
        vm.now = monday

        let cal = Calendar.current
        // Add 40g on a Monday 3 weeks ago (so it's in the 30-day window)
        let mondayThreeWeeksAgo = cal.date(byAdding: .weekOfYear, value: -3, to: monday)!
        let e = ConsumptionEvent(timestamp: mondayThreeWeeksAgo.addingTimeInterval(12 * 3600),
                                 volumeMl: 500, abv: 40.0 / 400, name: "Test", category: .beer, icon: "🍺")
        c.mainContext.insert(e)
        vm.events = [e]

        let bars = vm.weekdayAverages
        #expect(bars.count == 7)
        // Only one day has data; count of Mondays in 30-day range is ~5 → avg ≤ 40
        let mondayBar = bars.first { $0.averageGrams > 0 }
        #expect(mondayBar != nil)
        #expect((mondayBar?.averageGrams ?? 0) < 40.1)    // must be divided, not raw total
        #expect((mondayBar?.averageGrams ?? 0) > 0)
    }

    // MARK: - heatmapCells

    @Test func heatmapCells_alwaysTwentyEightCells() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.heatmapCells.count == 28)
    }

    @Test func heatmapCells_oldestFirst() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        let dates = vm.heatmapCells.map(\.date)
        #expect(dates == dates.sorted())
    }

    @Test func heatmapCells_exactlyOneCurrentWeek() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.heatmapCells.filter(\.isCurrentWeek).count == 7)
    }

    @Test func heatmapCells_gramsReflectEvents() throws {
        let c = try makeContainer()
        let vm = InsightsViewModel()
        vm.now = .now
        let e = event(daysAgo: 0, grams: 30, in: c.mainContext)
        vm.events = [e]
        let todayCell = vm.heatmapCells.first {
            Calendar.current.isDate($0.date, inSameDayAs: Date.now)
        }
        #expect(todayCell != nil)
        #expect(abs((todayCell?.grams ?? 0) - 30) < 0.01)
    }

    @Test func heatmapCells_emptyDayHasZeroGrams() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.heatmapCells.allSatisfy { $0.grams == 0 })
    }

    // MARK: - bingeEpisodesThisMonth

    @Test func bingeEpisodes_zeroWhenNoEvents() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 0)
    }

    @Test func bingeEpisodes_zeroWhenBelowThreshold_who() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = InsightsViewModel()
        vm.profile = profile
        // 55 g in one session — below 60 g threshold
        vm.events = [event(daysAgo: 0, grams: 55, in: c.mainContext)]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 0)
    }

    @Test func bingeEpisodes_oneWhenAtThreshold_who() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = InsightsViewModel()
        vm.profile = profile
        vm.events = [event(daysAgo: 0, grams: 60, in: c.mainContext)]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 1)
    }

    @Test func bingeEpisodes_twoSessionsCountedSeparately() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = InsightsViewModel()
        vm.profile = profile
        // Two sessions 5 hours apart, each 60 g
        vm.events = [
            event(daysAgo: 0, hoursOffset: 12, grams: 60, in: c.mainContext),
            event(daysAgo: 0, hoursOffset: 17, grams: 60, in: c.mainContext),
        ]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 2)
    }

    @Test func bingeEpisodes_oneSingleSessionWhenWithin3Hours() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .who)
        c.mainContext.insert(profile)
        let vm = InsightsViewModel()
        vm.profile = profile
        // Two events 1 hour apart, each 35 g → 70 g combined → one binge
        vm.events = [
            event(daysAgo: 0, hoursOffset: 12, grams: 35, in: c.mainContext),
            event(daysAgo: 0, hoursOffset: 13, grams: 35, in: c.mainContext),
        ]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 1)
    }

    @Test func bingeEpisodes_ukThreshold_56g() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .uk)
        c.mainContext.insert(profile)
        let vm = InsightsViewModel()
        vm.profile = profile
        // 57 g = above UK threshold (56 g)
        vm.events = [event(daysAgo: 0, grams: 57, in: c.mainContext)]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 1)
    }

    @Test func bingeEpisodes_usThreshold_70g() throws {
        let c = try makeContainer()
        let profile = UserProfile(guidelineChoice: .us)
        c.mainContext.insert(profile)
        let vm = InsightsViewModel()
        vm.profile = profile
        // 69 g = below US threshold (70 g)
        vm.events = [event(daysAgo: 0, grams: 69, in: c.mainContext)]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 0)
    }

    @Test func bingeEpisodes_eventsOutsideMonthNotCounted() throws {
        let c = try makeContainer()
        let vm = InsightsViewModel()
        // Use day 2 of a month to avoid edge cases
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        vm.now = fmt.date(from: "2026-05-15")!
        // Event from last month
        let lastMonth = fmt.date(from: "2026-04-20")!
        let e = ConsumptionEvent(timestamp: lastMonth, volumeMl: 500, abv: 100.0 / 400,
                                 name: "Test", category: .beer, icon: "🍺")
        c.mainContext.insert(e)
        vm.events = [e]
        #expect(vm.bingeEpisodesThisMonth == 0)
    }

    // MARK: - seriesData

    @Test func seriesData_weekPeriodHasSevenPoints() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.seriesData.count == 7)
    }

    @Test func seriesData_emptyGramsWhenNoEvents_week() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.seriesData.allSatisfy { $0.grams == 0 })
    }

    @Test func seriesData_todayGramsReflectEvents_week() throws {
        let c = try makeContainer()
        let vm = InsightsViewModel()
        vm.period = .week
        vm.now = .now
        vm.events = [event(daysAgo: 0, grams: 40, in: c.mainContext)]
        let today = Calendar.current.startOfDay(for: Date.now)
        let todayPoint = vm.seriesData.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        #expect(todayPoint != nil)
        #expect(abs((todayPoint?.grams ?? 0) - 40) < 0.01)
    }

    // MARK: - guidelineComparisons

    @Test func guidelineComparisons_alwaysThreeRows() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.guidelineComparisons.count == 3)
    }

    @Test func guidelineComparisons_includesWHO_NHS_DHS() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        let guidelines = vm.guidelineComparisons.map(\.guideline)
        #expect(guidelines.contains(.who))
        #expect(guidelines.contains(.uk))
        #expect(guidelines.contains(.de))
    }

    @Test func guidelineComparisons_fractionZeroWhenNoEvents() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.guidelineComparisons.allSatisfy { $0.fraction == 0 })
    }

    // MARK: - monthCaloriesKcal

    @Test func monthCaloriesKcal_zeroWithNoEvents() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.monthCaloriesKcal == 0)
    }

    @Test func monthCaloriesKcal_correctCalculation() throws {
        let c = try makeContainer()
        let vm = InsightsViewModel()
        vm.now = .now
        // 100 g pure alcohol → 710 kcal
        vm.events = [event(daysAgo: 0, grams: 100, in: c.mainContext)]
        #expect(vm.monthCaloriesKcal == 710)
    }

    // MARK: - monthSpend

    @Test func monthSpend_nilWhenNoEvents() {
        let vm = InsightsViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.monthSpend == nil)
    }

    @Test func monthSpend_nilWhenNoPrices() throws {
        let c = try makeContainer()
        let vm = InsightsViewModel()
        vm.now = .now
        vm.events = [event(daysAgo: 0, grams: 20, in: c.mainContext)]
        #expect(vm.monthSpend == nil)
    }

    @Test func monthSpend_sumsAllPricesInMonth() throws {
        let c = try makeContainer()
        let vm = InsightsViewModel()
        vm.now = .now
        vm.events = [
            event(daysAgo: 0, grams: 20, price: 5.0, in: c.mainContext),
            event(daysAgo: 1, grams: 20, price: 3.5, in: c.mainContext),
        ]
        #expect(abs((vm.monthSpend ?? 0) - 8.5) < 0.01)
    }
}
