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
        let abv = target / (500 * 0.789)
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
        // Add 40 g on an earlier Monday in the same month (within the month window).
        // The month window (May 1 → May 18) holds several Mondays, so the average for
        // Monday must divide by the Monday count, not collapse to the single 40 g day.
        let earlierMonday = cal.date(byAdding: .weekOfYear, value: -1, to: monday)!
        let e = ConsumptionEvent(
            timestamp: earlierMonday.addingTimeInterval(12 * 3600),
            volumeMl: 500, abv: 40.0 / 400, name: "Test", category: .beer, icon: "🍺"
        )
        c.mainContext.insert(e)
        vm.events = [e]

        let bars = vm.weekdayAverages
        #expect(bars.count == 7)
        // 40 g divided by the count of Mondays in the month window must be < 40 g
        let mondayBar = bars.first { $0.averageGrams > 0 }
        #expect(mondayBar != nil)
        #expect((mondayBar?.averageGrams ?? 0) < 40.1)
        #expect((mondayBar?.averageGrams ?? 0) > 0)
    }

    // Regression: weekday window follows the selected period, not a fixed 90 days.
    // A week scope must exclude events from outside the current week.
    @Test func weekdayAverages_weekScope_excludesEventsOutsideWindow() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let wednesday = fmt.date(from: "2026-05-20")!
        vm.now = wednesday

        let cal = Calendar.current
        // 30 days ago — well outside the current week, inside the old 90-day window.
        let longAgo = cal.date(byAdding: .day, value: -30, to: wednesday)!
        let e = ConsumptionEvent(
            timestamp: longAgo.addingTimeInterval(12 * 3600),
            volumeMl: 500, abv: 40.0 / 400, name: "Test", category: .beer, icon: "🍺"
        )
        c.mainContext.insert(e)
        vm.events = [e]

        #expect(vm.weekdayAverages.allSatisfy { $0.averageGrams == 0 })
    }

    // Regression: year scope's range upper bound is Dec 31 of the current year,
    // which is in the future. The 90-day weekday window must clamp to `now` so it
    // captures recent events instead of landing entirely in the future (empty chart).
    @Test func weekdayAverages_yearScope_usesEventsBeforeNow_notFutureWindow() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .year

        // Fix now to mid-year so the year's upper bound (Dec 31) is well in the future.
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let midYear = fmt.date(from: "2026-06-09")!
        vm.now = midYear

        let cal = Calendar.current
        // An event a week ago is inside a now-clamped window but outside a Dec-31 window.
        let weekAgo = cal.date(byAdding: .day, value: -7, to: midYear)!
        let e = ConsumptionEvent(
            timestamp: weekAgo.addingTimeInterval(12 * 3600),
            volumeMl: 500, abv: 40.0 / 400, name: "Test", category: .beer, icon: "🍺"
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
        #expect(cal.isDate(range.lowerBound, inSameDayAs: oldest.timestamp))
        #expect(range.upperBound >= recent.timestamp)
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

        // An event 120 days ago would be excluded by the old fixed 90-day window.
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
        // Navigation is inert for all-time.
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
        // No crash, valid range, zero total.
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
