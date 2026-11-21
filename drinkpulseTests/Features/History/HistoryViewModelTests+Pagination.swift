import Testing
import Foundation
@testable import drinkpulse

@MainActor
extension HistoryViewModelTests {

    func gregorian() -> Calendar { Calendar(identifier: .gregorian) }

    /// `count` events, newest first, `perDay` per day starting today at noon.
    private func newestFirst(count: Int, perDay: Int, calendar: Calendar) throws -> [ConsumptionEvent] {
        let noon = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 21, hour: 12)))
        return try (0..<count).map { i in
            let day = try #require(calendar.date(byAdding: .day, value: -(i / perDay), to: noon))
            return ConsumptionEvent(consumptionDate: day.addingTimeInterval(-Double(i % perDay) * 60),
                                    volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        }
    }

    @Test func test_listFetchLimit_isOneMoreThanThePageLimit() {
        #expect(vm.listFetchLimit(pageLimit: 50) == 51)
    }

    @Test func test_nextPageLimit_growsByOnePage() {
        #expect(vm.nextPageLimit(after: 50) == 50 + HistoryViewModel.listPageSize)
    }

    @Test func test_listPage_fewerThanLimit_showsAllWithoutMore() throws {
        let cal = gregorian()
        let fetched = try newestFirst(count: 5, perDay: 2, calendar: cal)
        let page = vm.listPage(from: fetched, pageLimit: 10, calendar: cal)
        #expect(page.events.map(\.uuid) == fetched.map(\.uuid))
        #expect(page.hasMore == false)
    }

    @Test func test_listPage_exactlyLimit_showsAllWithoutMore() throws {
        let cal = gregorian()
        let fetched = try newestFirst(count: 10, perDay: 3, calendar: cal)
        let page = vm.listPage(from: fetched, pageLimit: 10, calendar: cal)
        #expect(page.events.count == 10)
        #expect(page.hasMore == false)
    }

    @Test func test_listPage_overLimit_hidesTheOldestPossiblyPartialDay() throws {
        let cal = gregorian()
        // 11 fetched for a limit of 10, 3 per day: days 0-2 full (9), day 3 has 2 of 3 loaded.
        let fetched = try newestFirst(count: 11, perDay: 3, calendar: cal)
        let page = vm.listPage(from: fetched, pageLimit: 10, calendar: cal)
        #expect(page.events.map(\.uuid) == fetched.prefix(9).map(\.uuid))
        #expect(page.hasMore == true)
    }

    @Test func test_listPage_singleDayOverLimit_showsTheLimitRatherThanNothing() throws {
        let cal = gregorian()
        let fetched = try newestFirst(count: 11, perDay: 20, calendar: cal)
        let page = vm.listPage(from: fetched, pageLimit: 10, calendar: cal)
        #expect(page.events.map(\.uuid) == fetched.prefix(10).map(\.uuid))
        #expect(page.hasMore == true)
    }

    @Test func test_listPage_empty_hasNoMore() {
        let page = vm.listPage(from: [], pageLimit: 10, calendar: gregorian())
        #expect(page.events.isEmpty)
        #expect(page.hasMore == false)
    }

    @Test func test_listPage_eachLoadAddsOnlyOnePage() throws {
        // Regression: one load used to jump the window to the earliest event (whole history).
        let cal = gregorian()
        let all = try newestFirst(count: 300, perDay: 3, calendar: cal)
        let limit = vm.nextPageLimit(after: HistoryViewModel.listPageSize)
        let fetched = Array(all.prefix(vm.listFetchLimit(pageLimit: limit)))
        let page = vm.listPage(from: fetched, pageLimit: limit, calendar: cal)
        #expect(page.events.count <= limit)
        #expect(page.hasMore == true)
    }
}

// MARK: - Calendar range (plan 0045 final review)

@MainActor
extension HistoryViewModelTests {

    @Test func test_calendarRange_isStableWithinADay() throws {
        let cal = gregorian()
        let morning = try #require(cal.date(from: DateComponents(year: 2026, month: 11, day: 21, hour: 8)))
        let evening = try #require(cal.date(from: DateComponents(year: 2026, month: 11, day: 21, hour: 22)))
        #expect(vm.calendarRange(earliest: nil, now: morning, calendar: cal)
                == vm.calendarRange(earliest: nil, now: evening, calendar: cal))
    }

    @Test func test_calendarRange_startsAtEarliestMonth_andEndsAfterToday() throws {
        let cal = gregorian()
        let now = try #require(cal.date(from: DateComponents(year: 2026, month: 11, day: 21, hour: 8)))
        let earliest = try #require(cal.date(from: DateComponents(year: 2026, month: 5, day: 4, hour: 12)))
        let range = vm.calendarRange(earliest: earliest, now: now, calendar: cal)
        #expect(range.start == cal.date(from: DateComponents(year: 2026, month: 5, day: 1)))
        #expect(range.end == cal.date(from: DateComponents(year: 2026, month: 11, day: 22)))
    }
}
