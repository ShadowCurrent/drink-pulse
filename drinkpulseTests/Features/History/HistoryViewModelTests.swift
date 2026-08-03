import Testing
import XCTest
import Foundation
import SwiftData
@testable import drinkpulse

// MARK: - Functional tests

@MainActor
struct HistoryViewModelTests {

    // Internal (not private) so `HistoryViewModelTests+Pagination.swift` can
    // reach it — mirrors the `HistoryInteractionUITests+Helpers.swift` pattern.
    let vm = HistoryViewModel()

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

    @Test func daySections_twoEventsOnDifferentDays_newestDayFirst() throws {
        let c = try makeContainer()
        let d1 = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 14))!
        let d2 = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        let e1 = event(on: d1, grams: 20, in: c.mainContext)
        let e2 = event(on: d2, grams: 20, in: c.mainContext)
        let sections = vm.daySections([e2, e1])
        #expect(sections.count == 2)
        #expect(sections.first?.id == Calendar.current.startOfDay(for: d2))
    }

    @Test func daySections_twoEventsOnSameDay_groupedTogether() throws {
        let c = try makeContainer()
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        let e1 = event(on: date, grams: 20, in: c.mainContext)
        let e2 = event(on: date.addingTimeInterval(3600), grams: 10, in: c.mainContext)
        let sections = vm.daySections([e2, e1])
        #expect(sections.count == 1)
        #expect(sections.first?.events.count == 2)
    }

    /// Titles come from the injected `now`, not from ambient current-date calls, so
    /// this is deterministic regardless of when the suite runs. Asserted structurally
    /// (each branch produces a distinct title, and only the oldest day falls through
    /// to the date format) so the check stays locale-independent.
    @Test func daySections_todayYesterdayAndOlderDay_getDistinctTitles() throws {
        let c = try makeContainer()
        let cal = Calendar.current
        let now = cal.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 12))!
        let today = cal.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 9))!
        let yesterday = cal.date(from: DateComponents(year: 2026, month: 5, day: 14, hour: 9))!
        let older = cal.date(from: DateComponents(year: 2026, month: 5, day: 5, hour: 9))!
        let events = [today, yesterday, older].map { event(on: $0, grams: 20, in: c.mainContext) }

        let sections = vm.daySections(events, now: now, calendar: cal)
        #expect(sections.count == 3)

        let dateStyle = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()
        // Oldest day falls through to the formatted date.
        #expect(sections[2].title == sections[2].id.formatted(dateStyle))
        // Today and yesterday take the two special-cased branches instead.
        #expect(sections[0].title != sections[0].id.formatted(dateStyle))
        #expect(sections[1].title != sections[1].id.formatted(dateStyle))
        #expect(sections[0].title != sections[1].title)
    }

    /// B8-2: the per-group sort was removed, so grouping now depends on the caller's
    /// ordering. Feeding input whose within-day order is NOT newest-first proves the
    /// input order is preserved rather than re-derived — this test is what converts
    /// the "Dictionary(grouping:) preserves order" assumption into a checked fact.
    @Test func daySections_preservesInputOrderWithinADay() throws {
        let c = try makeContainer()
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        let oldest = event(on: date, grams: 20, in: c.mainContext)
        let middle = event(on: date.addingTimeInterval(3600), grams: 10, in: c.mainContext)
        let newest = event(on: date.addingTimeInterval(7200), grams: 15, in: c.mainContext)

        // Deliberately oldest-first: a re-sort inside the function would reverse this.
        let sections = vm.daySections([oldest, middle, newest])
        #expect(sections.count == 1)
        #expect(sections.first?.events.map(\.uuid) == [oldest.uuid, middle.uuid, newest.uuid])
    }

    @Test func daySections_emptyInput_returnsNoSections() {
        #expect(vm.daySections([]).isEmpty)
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

/// Deliberately kept on XCTest, not converted to Swift Testing: these tests use
/// `measure { }`, which has no Swift Testing equivalent (Apple Developer Forums
/// thread 774088). Reviewed, applied decision per ROADMAP Phase 2 Success
/// Criterion #4 / SWIFT6-03. Decision dated 2026-07-27.
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

    func test_daySections_performance_2000events() {
        let events = makeEvents(count: 2000, spreadDays: 1095)
        measure { _ = vm.daySections(events) }
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
