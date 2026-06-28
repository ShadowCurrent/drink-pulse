import Testing
import XCTest
import Foundation
import SwiftData
@testable import drinkpulse

// MARK: - Functional tests

@MainActor
struct HistoryViewModelTests {

    private let vm = HistoryViewModel()

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func event(on date: Date, grams: Double, in context: ModelContext) -> ConsumptionEvent {
        let abv = grams / (500 * 0.789)
        let e = ConsumptionEvent(consumptionDate: date, volumeMl: 500, abv: abv, category: .beer, icon: "🍺")
        context.insert(e)
        return e
    }

    private func calendar(firstWeekday: Int) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = firstWeekday
        return c
    }

    // May 1, 2026 is Friday. Monday-first: 4 leading cells → 4 + 31 = 35 total.
    @Test func monthCells_may2026_mondayFirst_returns35Cells() {
        let cells = vm.monthCells(year: 2026, month: 5, events: [],
                                  calendar: calendar(firstWeekday: 2), today: .now)
        #expect(cells.count == 35)
    }

    // May 1, 2026 is Friday. Monday-first: 4 leading empty cells.
    @Test func monthCells_may2026_mondayFirst_has4LeadingEmptyCells() {
        let cells = vm.monthCells(year: 2026, month: 5, events: [],
                                  calendar: calendar(firstWeekday: 2), today: .now)
        let leading = cells.prefix(while: { $0.date == nil }).count
        #expect(leading == 4)
    }

    // Sunday-first: May 1 = Friday = index 5 → 5 leading → 5+31=36 → rounds up to 42.
    @Test func monthCells_may2026_sundayFirst_returns42Cells() {
        let cells = vm.monthCells(year: 2026, month: 5, events: [],
                                  calendar: calendar(firstWeekday: 1), today: .now)
        #expect(cells.count == 42)
    }

    @Test func monthCells_countIsMultipleOf7() {
        for month in 1...12 {
            let cells = vm.monthCells(year: 2026, month: month, events: [],
                                      calendar: calendar(firstWeekday: 2), today: .now)
            #expect(cells.count % 7 == 0, "Month \(month) has \(cells.count) cells, not a multiple of 7")
        }
    }

    @Test func monthCells_zeroConsumptionMonth_allCellsHaveZeroGrams() {
        let cells = vm.monthCells(year: 2026, month: 5, events: [],
                                  calendar: calendar(firstWeekday: 2), today: .now)
        #expect(cells.allSatisfy { $0.grams == 0 })
    }

    @Test func gramsByDay_singleEvent_returnsSingleEntry() throws {
        let c = try makeContainer()
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        let e = event(on: date, grams: 20, in: c.mainContext)
        let result = vm.gramsByDay([e])
        #expect(result.count == 1)
        #expect(abs(result.values.first! - 20) < 0.01)
    }

    @Test func gramsByDay_twoEventsOnSameDay_summedIntoOneEntry() throws {
        let c = try makeContainer()
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        let e1 = event(on: date, grams: 20, in: c.mainContext)
        let e2 = event(on: date.addingTimeInterval(3600), grams: 30, in: c.mainContext)
        let result = vm.gramsByDay([e1, e2])
        #expect(result.count == 1)
        #expect(abs(result.values.first! - 50) < 0.01)
    }

    @Test func gramsByDay_twoEventsOnDifferentDays_returnsTwoEntries() throws {
        let c = try makeContainer()
        let d1 = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 14))!
        let d2 = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        let e1 = event(on: d1, grams: 20, in: c.mainContext)
        let e2 = event(on: d2, grams: 30, in: c.mainContext)
        let result = vm.gramsByDay([e1, e2])
        #expect(result.count == 2)
    }

    @Test func groupedByDay_sortedDescending() throws {
        let c = try makeContainer()
        let d1 = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 14))!
        let d2 = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        let e1 = event(on: d1, grams: 20, in: c.mainContext)
        let e2 = event(on: d2, grams: 20, in: c.mainContext)
        let grouped = vm.groupedByDay([e1, e2])
        #expect(grouped.first?.day == Calendar.current.startOfDay(for: d2))
    }

    @Test func groupedByDay_twoEventsOnSameDay_groupedTogether() throws {
        let c = try makeContainer()
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        let e1 = event(on: date, grams: 20, in: c.mainContext)
        let e2 = event(on: date.addingTimeInterval(3600), grams: 10, in: c.mainContext)
        let grouped = vm.groupedByDay([e1, e2])
        #expect(grouped.count == 1)
        #expect(grouped.first?.events.count == 2)
    }

    @Test func riskColor_zeroGrams_returnsNil() {
        #expect(vm.riskColor(forGrams: 0, dailyLimit: 20) == nil)
    }

    @Test func riskColor_zeroDailyLimit_returnsNil() {
        #expect(vm.riskColor(forGrams: 10, dailyLimit: 0) == nil)
    }

    @Test func riskColor_below50pct_returnsGreen() {
        let color = vm.riskColor(forGrams: 9, dailyLimit: 20)
        #expect(color == .dpGreen)
    }

    @Test func riskColor_exactly50pct_returnsAmber() {
        let color = vm.riskColor(forGrams: 10, dailyLimit: 20)
        #expect(color == .dpAmber)
    }

    @Test func riskColor_at99pct_returnsAmber() {
        let color = vm.riskColor(forGrams: 19.8, dailyLimit: 20)
        #expect(color == .dpAmber)
    }

    @Test func riskColor_at100pct_returnsAmber() {
        let color = vm.riskColor(forGrams: 20, dailyLimit: 20)
        #expect(color == .dpAmber)
    }

    @Test func riskColor_above100pct_returnsRed() {
        let color = vm.riskColor(forGrams: 30, dailyLimit: 20)
        #expect(color == .dpRed)
    }

    // MARK: - Pagination

    private func gregorian() -> Calendar { Calendar(identifier: .gregorian) }

    @Test func hasMoreToLoad_nilEarliest_returnsFalse() {
        #expect(vm.hasMoreToLoad(earliest: nil, windowStart: .now) == false)
    }

    @Test func hasMoreToLoad_earliestBeforeWindow_returnsTrue() {
        let window = Date(timeIntervalSince1970: 1_700_000_000)
        let earliest = window.addingTimeInterval(-86_400)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == true)
    }

    @Test func hasMoreToLoad_earliestInsideWindow_returnsFalse() {
        let window = Date(timeIntervalSince1970: 1_700_000_000)
        let earliest = window.addingTimeInterval(86_400)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == false)
    }

    @Test func hasMoreToLoad_earliestEqualsWindow_returnsFalse() {
        let window = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(vm.hasMoreToLoad(earliest: window, windowStart: window) == false)
    }

    @Test func initialWindowStart_isOnePageBeforeNow() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let start = vm.initialWindowStart(from: now, calendar: gregorian())
        let expected = gregorian().date(byAdding: .day, value: -HistoryViewModel.listPageDays, to: now)
        #expect(start == expected)
    }

    @Test func initialWindowStart_isInThePast() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(vm.initialWindowStart(from: now, calendar: gregorian()) < now)
    }

    @Test func extendedWindowStart_movesBackOnePage() {
        let current = Date(timeIntervalSince1970: 1_700_000_000)
        let extended = vm.extendedWindowStart(from: current, calendar: gregorian())
        let expected = gregorian().date(byAdding: .day, value: -HistoryViewModel.listPageDays, to: current)
        #expect(extended == expected)
    }

    @Test func extendedWindowStart_isEarlierThanCurrent() {
        let current = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(vm.extendedWindowStart(from: current, calendar: gregorian()) < current)
    }

    @Test func extendedWindowStart_repeatedCalls_keepMovingBack() {
        let cal = gregorian()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let once = vm.extendedWindowStart(from: start, calendar: cal)
        let twice = vm.extendedWindowStart(from: once, calendar: cal)
        #expect(twice < once)
        let expected = cal.date(byAdding: .day, value: -2 * HistoryViewModel.listPageDays, to: start)
        #expect(twice == expected)
    }

    @Test func extendedWindowThenHasMore_eventuallyCoversEarliest() {
        let cal = gregorian()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let earliest = cal.date(byAdding: .day, value: -200, to: now)!
        var window = vm.initialWindowStart(from: now, calendar: cal)
        // 90-day window does not yet reach a 200-day-old event.
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == true)
        // One more page (180 days) still short; two pages (270) covers it.
        window = vm.extendedWindowStart(from: window, calendar: cal)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == true)
        window = vm.extendedWindowStart(from: window, calendar: cal)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == false)
    }

    @Test func monthCells_eventsReflectedInGrams() throws {
        let c = try makeContainer()
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        let e = event(on: date, grams: 20, in: c.mainContext)
        let cells = vm.monthCells(year: 2026, month: 5, events: [e],
                                  calendar: calendar(firstWeekday: 2), today: .now)
        let dayCell = cells.first { cell in
            guard let d = cell.date else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
        #expect(dayCell != nil)
        #expect(abs((dayCell?.grams ?? 0) - 20) < 0.01)
    }
}

// MARK: - Performance tests

@MainActor
class HistoryViewModelPerformanceTests: XCTestCase {

    private let vm = HistoryViewModel()

    private func makeEvents(count: Int, spreadDays: Int) -> [ConsumptionEvent] {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        return (0..<count).map { i in
            let dayOffset = i % spreadDays
            let ts = base.addingTimeInterval(Double(dayOffset) * 86_400 + Double(i % 86400))
            return ConsumptionEvent(consumptionDate: ts, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        }
    }

    func test_gramsByDay_performance_2000events() {
        let events = makeEvents(count: 2000, spreadDays: 1095)
        measure { _ = vm.gramsByDay(events) }
    }

    func test_gramsByDay_performance_extremeLoad_10000events() {
        let events = makeEvents(count: 10_000, spreadDays: 1095)
        measure { _ = vm.gramsByDay(events) }
    }

    func test_groupedByDay_performance_2000events() {
        let events = makeEvents(count: 2000, spreadDays: 1095)
        measure { _ = vm.groupedByDay(events) }
    }

    func test_monthCells_performance_36months() {
        let events = makeEvents(count: 2000, spreadDays: 1095)
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        measure {
            for month in 1...12 {
                for year in 2024...2026 {
                    _ = vm.monthCells(year: year, month: month, events: events,
                                      calendar: cal, today: .now)
                }
            }
        }
    }
}
