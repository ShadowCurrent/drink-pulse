import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// Day-rollover and determinism coverage for `daySections(_:now:calendar:)`.
///
/// These two cases exist because `HistoryListQueryView` now *stores* the section
/// list in `@State` instead of deriving it on every body pass (B8-1). Storing a
/// time-dependent title creates a correctness obligation the per-render version
/// did not have — see `HistoryListQueryView.refreshSections()` (A4-2). The view
/// answers that obligation with three refresh triggers; these tests pin the other
/// half of it: that the underlying pure function really does relabel a day when
/// the clock crosses midnight, and that its output is stable enough to cache.
///
/// Split into its own file to keep `HistoryViewModelTests.swift` under the
/// project's 300-line ceiling — mirrors the `+Pagination.swift` split already
/// used for this suite.
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

    /// One second before midnight vs. one second after, over the *same* fixed event
    /// set: the day that was "today" must be relabelled. Asserted structurally
    /// (no localized literals, so it is locale-independent like the sibling title
    /// test): the May-15 section after the rollover carries the exact title the
    /// May-14 section carried before it — i.e. it moved onto the yesterday branch —
    /// and May-14 has fallen through to the formatted-date branch.
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

        // Same events, same days, same order — only the clock moved.
        #expect(before.map(\.id) == after.map(\.id))

        // The May-15 section is titled differently on the two sides of midnight.
        #expect(before[0].title != after[0].title)
        // ...and specifically it now carries the title May-14 carried before:
        // the yesterday branch.
        #expect(after[0].title == before[1].title)

        // May-14 has fallen all the way through to the formatted-date branch.
        let dateStyle = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()
        #expect(after[1].title == after[1].id.formatted(dateStyle))
    }

    /// Caching the output is only safe if the function is deterministic for fixed
    /// inputs. Two invocations with the same events, clock and calendar must agree
    /// on both the titles and the day ordering.
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
