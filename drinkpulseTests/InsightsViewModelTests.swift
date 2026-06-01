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

    func makeVM() -> InsightsViewModel {
        InsightsViewModel()
    }

    func event(
        daysAgo: Int = 0,
        hoursOffset: Int = 12,
        grams target: Double = 20.0,
        price: Double? = nil,
        relativeTo now: Date = .now,
        in context: ModelContext
    ) -> ConsumptionEvent {
        let cal = Calendar.current
        let base = cal.startOfDay(for: now).addingTimeInterval(Double(hoursOffset) * 3600)
        let ts = cal.date(byAdding: .day, value: -daysAgo, to: base) ?? base
        let abv = target / (500 * 0.8)
        let e = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: abv,
                                 name: "Test", category: .beer, icon: "🍺", price: price)
        context.insert(e)
        return e
    }

    // MARK: - weekdayAverages

    @Test func weekdayAverages_alwaysSevenEntries() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.weekdayAverages.count == 7)
    }

    @Test func weekdayAverages_zeroBarsWhenNoEvents() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.weekdayAverages.allSatisfy { $0.averageGrams == 0 })
    }

    @Test func weekdayAverages_dividesByWeekCountNotDayCount_monthPeriod() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .month

        // Fix now to a known Monday (2026-05-18)
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let monday = fmt.date(from: "2026-05-18")!
        vm.now = monday

        let cal = Calendar.current
        // Add 40 g on a Monday 3 weeks ago (within the 90-day weekday window)
        let mondayThreeWeeksAgo = cal.date(byAdding: .weekOfYear, value: -3, to: monday)!
        let e = ConsumptionEvent(
            timestamp: mondayThreeWeeksAgo.addingTimeInterval(12 * 3600),
            volumeMl: 500, abv: 40.0 / 400, name: "Test", category: .beer, icon: "🍺"
        )
        c.mainContext.insert(e)
        vm.events = [e]

        let bars = vm.weekdayAverages
        #expect(bars.count == 7)
        // 40 g divided by the count of Mondays in the 90-day window must be < 40 g
        let mondayBar = bars.first { $0.averageGrams > 0 }
        #expect(mondayBar != nil)
        #expect((mondayBar?.averageGrams ?? 0) < 40.1)
        #expect((mondayBar?.averageGrams ?? 0) > 0)
    }

    // MARK: - heatmapCells

    @Test func heatmapCells_alwaysEightyFourCells() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        #expect(vm.heatmapCells.count == 84)
    }

    @Test func heatmapCells_oldestFirst() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        let dates = vm.heatmapCells.map(\.date)
        #expect(dates == dates.sorted())
    }

    @Test func heatmapCells_newestWeekMarkedAsCurrent() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        #expect(vm.heatmapCells.filter(\.isCurrentWeek).count == 7)
    }

    @Test func heatmapCells_gramsReflectRealEvents() throws {
        let c = try makeContainer()
        let vm = makeVM()
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
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        #expect(vm.heatmapCells.allSatisfy { $0.grams == 0 })
    }

    @Test func heatmapCells_futureCellsMarkedAsFuture() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        let today = Calendar.current.startOfDay(for: .now)
        let futureCells = vm.heatmapCells.filter(\.isFuture)
        #expect(futureCells.allSatisfy { $0.date > today })
        let nonFutureCells = vm.heatmapCells.filter { !$0.isFuture }
        #expect(nonFutureCells.allSatisfy { $0.date <= today })
    }

    // MARK: - bingeEpisodes (day-based: days where total ≥ 60 g)

    @Test func bingeEpisodes_zeroWhenNoEvents() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 0)
    }

    @Test func bingeEpisodes_zeroWhenBelowThreshold() throws {
        let c = try makeContainer()
        let vm = makeVM()
        // 59 g on one day — below the 60 g threshold
        vm.events = [event(daysAgo: 0, grams: 59, in: c.mainContext)]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 0)
    }

    @Test func bingeEpisodes_oneWhenAtThreshold() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.events = [event(daysAgo: 0, grams: 60, in: c.mainContext)]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 1)
    }

    @Test func bingeEpisodes_twoDaysAboveThreshold_countsBoth() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .month
        // Pin to mid-month (2026-05-15, Friday) so daysAgo:1 (May 14) stays in May.
        let pinned = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        vm.now = pinned
        // Two separate days each with ≥ 60 g → 2 binge days
        vm.events = [
            event(daysAgo: 0, grams: 60, relativeTo: pinned, in: c.mainContext),
            event(daysAgo: 1, grams: 60, relativeTo: pinned, in: c.mainContext),
        ]
        #expect(vm.bingeEpisodesThisMonth == 2)
    }

    @Test func bingeEpisodes_multipleDrinksOnSameDay_combinedForThreshold() throws {
        let c = try makeContainer()
        let vm = makeVM()
        // Two events on the same day: 35 + 35 = 70 g → 1 binge day
        vm.events = [
            event(daysAgo: 0, hoursOffset: 12, grams: 35, in: c.mainContext),
            event(daysAgo: 0, hoursOffset: 13, grams: 35, in: c.mainContext),
        ]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 1)
    }

    @Test func bingeEpisodes_eventOutsideActivePeriodNotCounted() throws {
        let c = try makeContainer()
        let vm = makeVM()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        vm.now = fmt.date(from: "2026-05-15")!
        // Event from April 20 — outside the current week (May 11–17)
        let lastMonth = fmt.date(from: "2026-04-20")!
        let e = ConsumptionEvent(timestamp: lastMonth, volumeMl: 500, abv: 100.0 / 400,
                                 name: "Test", category: .beer, icon: "🍺")
        c.mainContext.insert(e)
        vm.events = [e]
        #expect(vm.bingeEpisodesThisMonth == 0)
    }
}
