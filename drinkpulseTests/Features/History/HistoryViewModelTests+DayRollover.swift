import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
extension HistoryViewModelTests {

    private func rolloverContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func rolloverEvent(on date: Date, in context: ModelContext) -> ConsumptionEvent {
        let e = ConsumptionEvent(consumptionDate: date, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        context.insert(e)
        return e
    }

    @Test func daySections_clockCrossesMidnight_relabelsTheDayThatWasToday() throws {
        let c = try rolloverContainer()
        let cal = Calendar(identifier: .gregorian)
        let may14 = cal.date(from: DateComponents(year: 2026, month: 5, day: 14, hour: 9))!
        let may15 = cal.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 9))!
        let events = [may15, may14].map { rolloverEvent(on: $0, in: c.mainContext) }

        let beforeMidnight = cal.date(from: DateComponents(
            year: 2026, month: 5, day: 15, hour: 23, minute: 59, second: 59))!
        let afterMidnight = cal.date(from: DateComponents(
            year: 2026, month: 5, day: 16, hour: 0, minute: 0, second: 1))!

        let before = vm.daySections(events, now: beforeMidnight, calendar: cal)
        let after = vm.daySections(events, now: afterMidnight, calendar: cal)

        #expect(before.map(\.id) == after.map(\.id))

        #expect(before[0].title != after[0].title)
        #expect(after[0].title == before[1].title)

        let dateStyle = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()
        #expect(after[1].title == after[1].id.formatted(dateStyle))
    }

    @Test func daySections_sameInputsTwice_returnsEqualTitlesAndOrdering() throws {
        let c = try rolloverContainer()
        let cal = Calendar(identifier: .gregorian)
        let now = cal.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 12))!
        let dates = [
            cal.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 9))!,
            cal.date(from: DateComponents(year: 2026, month: 5, day: 14, hour: 9))!,
            cal.date(from: DateComponents(year: 2026, month: 5, day: 5, hour: 9))!,
        ]
        let events = dates.map { rolloverEvent(on: $0, in: c.mainContext) }

        let first = vm.daySections(events, now: now, calendar: cal)
        let second = vm.daySections(events, now: now, calendar: cal)

        #expect(first.count == 3)
        #expect(first.map(\.id) == second.map(\.id))
        #expect(first.map(\.title) == second.map(\.title))
    }
}
