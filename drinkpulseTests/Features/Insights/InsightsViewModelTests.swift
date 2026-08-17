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
        let vm = InsightsViewModel()
        vm.profile = UserProfile(guidelineChoice: .who, alcoholUnit: .grams)
        return vm
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
        let abv = target / (500 * 0.789)
        let e = ConsumptionEvent(consumptionDate: ts, volumeMl: 500, abv: abv, category: .beer, icon: "🍺", price: price)
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

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let monday = fmt.date(from: "2026-05-18")!
        vm.now = monday

        let cal = Calendar.current
        let earlierMonday = cal.date(byAdding: .weekOfYear, value: -1, to: monday)!
        let e = ConsumptionEvent(
            consumptionDate: earlierMonday.addingTimeInterval(12 * 3600),
            volumeMl: 500, abv: 40.0 / 400, category: .beer, icon: "🍺"
        )
        c.mainContext.insert(e)
        vm.events = [e]

        let bars = vm.weekdayAverages
        #expect(bars.count == 7)
        let mondayBar = bars.first { $0.averageGrams > 0 }
        #expect(mondayBar != nil)
        #expect((mondayBar?.averageGrams ?? 0) < 40.1)
        #expect((mondayBar?.averageGrams ?? 0) > 0)
    }

    @Test func weekdayAverages_weekScope_excludesEventsOutsideWindow() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let wednesday = fmt.date(from: "2026-05-20")!
        vm.now = wednesday

        let cal = Calendar.current
        let longAgo = cal.date(byAdding: .day, value: -30, to: wednesday)!
        let e = ConsumptionEvent(
            consumptionDate: longAgo.addingTimeInterval(12 * 3600),
            volumeMl: 500, abv: 40.0 / 400, category: .beer, icon: "🍺"
        )
        c.mainContext.insert(e)
        vm.events = [e]

        #expect(vm.weekdayAverages.allSatisfy { $0.averageGrams == 0 })
    }

    @Test func weekdayAverages_yearScope_usesEventsBeforeNow_notFutureWindow() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .year

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let midYear = fmt.date(from: "2026-06-09")!
        vm.now = midYear

        let cal = Calendar.current
        let weekAgo = cal.date(byAdding: .day, value: -7, to: midYear)!
        let e = ConsumptionEvent(
            consumptionDate: weekAgo.addingTimeInterval(12 * 3600),
            volumeMl: 500, abv: 40.0 / 400, category: .beer, icon: "🍺"
        )
        c.mainContext.insert(e)
        vm.events = [e]

        let bars = vm.weekdayAverages
        #expect(bars.count == 7)
        #expect(bars.contains { $0.averageGrams > 0 })
    }

    // MARK: - allTime scope

    @Test func allTime_rangeSpansOldestEventToNow() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .allTime
        vm.now = .now

        let oldest = event(daysAgo: 200, grams: 10, in: c.mainContext)
        let recent = event(daysAgo: 3, grams: 10, in: c.mainContext)
        vm.events = [recent, oldest]

        let range = vm.activeDateRange
        let cal = Calendar.current
        #expect(cal.isDate(range.lowerBound, inSameDayAs: oldest.consumptionDate))
        #expect(range.upperBound >= recent.consumptionDate)
    }

    @Test func allTime_totalIncludesEventsOlderThanAYear() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .allTime
        vm.now = .now

        let old = event(daysAgo: 400, grams: 25, in: c.mainContext)
        let recent = event(daysAgo: 1, grams: 15, in: c.mainContext)
        vm.events = [recent, old]

        #expect(abs(vm.periodTotalGrams - 40) < 0.01)
    }

    @Test func allTime_weekdayAveragesUseWholeHistory() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .allTime
        vm.now = .now

        let old = event(daysAgo: 120, grams: 30, in: c.mainContext)
        vm.events = [old]

        #expect(vm.weekdayAverages.contains { $0.averageGrams > 0 })
    }

    @Test func allTime_isAllTimeAndNavigationDisabled() {
        let vm = makeVM()
        vm.period = .allTime
        vm.now = .now

        #expect(vm.isAllTime)
        #expect(vm.activeOffset == 0)
        vm.navigatePrev()
        #expect(vm.activeOffset == 0)
        vm.navigateNext()
        #expect(vm.activeOffset == 0)
    }

    @Test func allTime_friendlyLabelIsAllTime() {
        let vm = makeVM()
        vm.period = .allTime
        vm.now = .now
        #expect(vm.friendlyLabel == String(localized: "insights.nav.allTime"))
    }

    @Test func allTime_emptyEventsRangeIsSafe() {
        let vm = makeVM()
        vm.period = .allTime
        vm.events = []
        vm.now = .now
        #expect(vm.activeDateRange.lowerBound <= vm.activeDateRange.upperBound)
        #expect(vm.periodTotalGrams == 0)
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
        let pinned = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        vm.now = pinned
        vm.events = [
            event(daysAgo: 0, grams: 60, relativeTo: pinned, in: c.mainContext),
            event(daysAgo: 1, grams: 60, relativeTo: pinned, in: c.mainContext),
        ]
        #expect(vm.bingeEpisodesThisMonth == 2)
    }

    @Test func bingeEpisodes_multipleDrinksOnSameDay_combinedForThreshold() throws {
        let c = try makeContainer()
        let vm = makeVM()
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
        let lastMonth = fmt.date(from: "2026-04-20")!
        let e = ConsumptionEvent(consumptionDate: lastMonth, volumeMl: 500, abv: 100.0 / 400, category: .beer, icon: "🍺")
        c.mainContext.insert(e)
        vm.events = [e]
        #expect(vm.bingeEpisodesThisMonth == 0)
    }
}
