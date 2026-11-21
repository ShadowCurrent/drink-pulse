import Testing
import XCTest
import Foundation
import SwiftData
@testable import drinkpulse

// MARK: - Functional tests

@MainActor
struct HistoryViewModelTests {

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

        let dateStyle = Date.FormatStyle.dateTime.weekday(.wide).day().month(.abbreviated)
        #expect(sections[2].title == sections[2].id.formatted(dateStyle))
        #expect(sections[0].title != sections[0].id.formatted(dateStyle))
        #expect(sections[1].title != sections[1].id.formatted(dateStyle))
        #expect(sections[0].title != sections[1].title)
    }

    @Test func daySections_preservesInputOrderWithinADay() throws {
        let c = try makeContainer()
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        let oldest = event(on: date, grams: 20, in: c.mainContext)
        let middle = event(on: date.addingTimeInterval(3600), grams: 10, in: c.mainContext)
        let newest = event(on: date.addingTimeInterval(7200), grams: 15, in: c.mainContext)

        let sections = vm.daySections([oldest, middle, newest])
        #expect(sections.count == 1)
        #expect(sections.first?.events.map(\.uuid) == [oldest.uuid, middle.uuid, newest.uuid])
    }

    @Test func daySections_emptyInput_returnsNoSections() {
        #expect(vm.daySections([]).isEmpty)
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

    func test_calendarMarks_performance_2000events() {
        let events = makeEvents(count: 2000, spreadDays: 1095)
        measure {
            _ = HistoryCalendarMarks.levels(events: events, dailyLimitGrams: 20,
                                            density: 0.789, calendar: .current)
        }
    }

    func test_calendarMarks_performance_extremeLoad_10000events() {
        let events = makeEvents(count: 10_000, spreadDays: 1095)
        measure {
            _ = HistoryCalendarMarks.levels(events: events, dailyLimitGrams: 20,
                                            density: 0.789, calendar: .current)
        }
    }

    func test_daySections_performance_2000events() {
        let events = makeEvents(count: 2000, spreadDays: 1095)
        measure { _ = vm.daySections(events) }
    }
}
