import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct HistoryCalendarMarksTests {

    private let calendar = Calendar(identifier: .gregorian)
    private let day = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    /// `volumeMl × 0.5` grams at density 1.0: exact in binary floating point, so the
    /// 0.5 / 1.0 boundaries are tested without rounding noise.
    private func event(grams: Double, on date: Date, in context: ModelContext) -> ConsumptionEvent {
        let e = ConsumptionEvent(consumptionDate: date, volumeMl: grams * 2, abv: 0.5,
                                 category: .beer, icon: "🍺")
        context.insert(e)
        return e
    }

    private func level(grams: Double) throws -> RiskLevel? {
        let context = try makeContext()
        let marks = HistoryCalendarMarks.levels(
            events: [event(grams: grams, on: day, in: context)],
            dailyLimitGrams: 20, density: 1.0, calendar: calendar
        )
        return marks[calendar.startOfDay(for: day)]
    }

    @Test func test_marks_mapLevels_atBoundaries() throws {
        #expect(try level(grams: 9.9) == .safe)
        #expect(try level(grams: 10) == .caution)
        #expect(try level(grams: 20) == .caution)
        #expect(try level(grams: 20.1) == .exceeded)
    }

    @Test func test_marks_useGivenDensity() throws {
        let context = try makeContext()
        // 500 ml × 5 %: 19.725 g at 0.789 (caution), 20.0 g at 0.8 (caution), limit 19.8 g
        // separates them.
        let e = ConsumptionEvent(consumptionDate: day, volumeMl: 500, abv: 0.05,
                                 category: .beer, icon: "🍺")
        context.insert(e)
        let key = calendar.startOfDay(for: day)
        let physical = HistoryCalendarMarks.levels(events: [e], dailyLimitGrams: 19.8,
                                                   density: 0.789, calendar: calendar)
        let units = HistoryCalendarMarks.levels(events: [e], dailyLimitGrams: 19.8,
                                                density: 0.8, calendar: calendar)
        #expect(physical[key] == .caution)
        #expect(units[key] == .exceeded)
    }

    @Test func test_marks_omitDaysWithoutAlcohol() throws {
        let context = try makeContext()
        let marks = HistoryCalendarMarks.levels(
            events: [event(grams: 0, on: day, in: context)],
            dailyLimitGrams: 20, density: 1.0, calendar: calendar
        )
        #expect(marks.isEmpty)
    }

    @Test func test_marks_emptyMonth_isEmpty() {
        let marks = HistoryCalendarMarks.levels(events: [], dailyLimitGrams: 20,
                                                density: 0.789, calendar: calendar)
        #expect(marks.isEmpty)
    }

    @Test func test_marks_zeroLimit_isEmpty() throws {
        let context = try makeContext()
        let marks = HistoryCalendarMarks.levels(
            events: [event(grams: 10, on: day, in: context)],
            dailyLimitGrams: 0, density: 1.0, calendar: calendar
        )
        #expect(marks.isEmpty)
    }

    @Test func test_marks_sumEventsOfOneDay() throws {
        let context = try makeContext()
        let later = day.addingTimeInterval(60)
        let marks = HistoryCalendarMarks.levels(
            events: [event(grams: 6, on: day, in: context), event(grams: 6, on: later, in: context)],
            dailyLimitGrams: 20, density: 1.0, calendar: calendar
        )
        #expect(marks.count == 1)
        #expect(marks[calendar.startOfDay(for: day)] == .caution)
    }
}
