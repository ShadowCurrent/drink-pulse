import Foundation
import SwiftData
import Testing
import UserNotifications
@testable import drinkpulse

// Pins the completed-week comparison of WeeklySummaryService at fixed dates (D-15). Since plan 0049 the
// notification body is one neutral line, so the comparison is asserted on `summaryContent(in:now:calendar:)`;
// trigger and identifier assertions stay on the scheduled request.
@MainActor
struct WeeklySummaryCompletedWeekTests {

    // MARK: - Fixtures

    private func makeCalendar(firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func utc(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        let calendar = makeCalendar(firstWeekday: 2)
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components)!
    }

    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "test.weeklyCompletedWeek.\(UUID().uuidString)")!
        defaults.set(true, forKey: AppStorageKeys.weeklySummaryEnabled)
        return defaults
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func wednesday() -> Date { utc(2026, 3, 18, 12, 0) }

    /// Seeds one 500 ml, 5 percent beer log per entry, placed 12 hours after the start of the week at the
    /// given offset relative to `reference`; the count is the log's quantity.
    private func seed(
        _ countsByOffset: [Int: Int],
        reference: Date,
        calendar: Calendar,
        into context: ModelContext
    ) {
        for (offset, count) in countsByOffset {
            let range = InsightsPeriod.week.dateRange(offset: offset, now: reference, calendar: calendar)
            let placed = range.lowerBound.addingTimeInterval(12 * 3600)
            context.insert(ConsumptionEvent(
                consumptionDate: placed, volumeMl: 500, abv: 0.05, quantity: count, category: .beer, icon: "🍺"
            ))
        }
    }

    private func schedule(
        now: Date,
        calendar: Calendar,
        counts: [Int: Int],
        seededAround reference: Date
    ) async throws -> (center: FakeNotificationCenter, content: WeeklySummaryContent) {
        let fake = FakeNotificationCenter()
        let service = WeeklySummaryService(center: fake, defaults: makeDefaults())
        let container = try makeContainer()
        seed(counts, reference: reference, calendar: calendar, into: container.mainContext)
        await service.scheduleIfEnabled(context: container.mainContext, now: now, calendar: calendar)
        let content = try service.summaryContent(in: container.mainContext, now: now, calendar: calendar)
        return (fake, content)
    }

    private struct Comparison: Equatable {
        let direction: SignDirection
        let percent: Int
    }

    /// The rounded whole-percent comparison a `.percentage` content carries; nil for other cases.
    private func comparison(_ content: WeeklySummaryContent) -> Comparison? {
        guard case let .percentage(fraction, direction) = content else { return nil }
        return Comparison(direction: direction, percent: Int((abs(fraction) * 100).rounded()))
    }

    private func down(_ percent: Int) -> Comparison { Comparison(direction: .down, percent: percent) }
    private func up(_ percent: Int) -> Comparison { Comparison(direction: .up, percent: percent) }

    // MARK: - Monday-first calendar

    @Test func wednesday_comparesWeekBeforeCurrentWeekAgainstTheOneBeforeThat() async throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let (fake, content) = try await schedule(
            now: wednesday(), calendar: calendar,
            counts: [-2: 2, -1: 1, 0: 2], seededAround: wednesday()
        )

        let request = try #require(fake.addedRequests.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(comparison(content) == down(50))
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.weekday == 2)
        #expect(trigger.dateComponents.hour == 9)
        #expect(trigger.dateComponents.minute == 0)
        #expect(request.identifier == WeeklySummaryService.weeklySummaryIdentifier)
    }

    @Test func sundayNight_stillExcludesTheInProgressWeek() async throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let (fake, content) = try await schedule(
            now: utc(2026, 3, 22, 23, 30), calendar: calendar,
            counts: [-2: 2, -1: 1, 0: 2], seededAround: wednesday()
        )

        #expect(fake.addedRequests.count == 1)
        #expect(comparison(content) == down(50))
    }

    @Test func mondayAfterMidnight_rollsTheComparisonForwardOneWeek() async throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let (fake, content) = try await schedule(
            now: utc(2026, 3, 23, 0, 30), calendar: calendar,
            counts: [-2: 2, -1: 1, 0: 2], seededAround: wednesday()
        )

        #expect(fake.addedRequests.count == 1)
        #expect(comparison(content) == up(100))
    }

    // MARK: - Week boundary

    // InsightsPeriod.dateRange ends a week at 23:59:59, so an event in the sub-second gap before the
    // next week starts must still land in the week it belongs to (review finding WR-02).
    @Test func eventInSubSecondGapAfterLastWeekEnd_countsTowardLastWeek() async throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let now = wednesday()
        let lastWeek = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)
        let fake = FakeNotificationCenter()
        let service = WeeklySummaryService(center: fake, defaults: makeDefaults())
        let container = try makeContainer()
        seed([-2: 2], reference: now, calendar: calendar, into: container.mainContext)
        container.mainContext.insert(ConsumptionEvent(
            consumptionDate: lastWeek.upperBound.addingTimeInterval(0.5),
            volumeMl: 500, abv: 0.05, quantity: 1, category: .beer, icon: "🍺"
        ))

        await service.scheduleIfEnabled(context: container.mainContext, now: now, calendar: calendar)
        let content = try service.summaryContent(in: container.mainContext, now: now, calendar: calendar)

        #expect(fake.addedRequests.count == 1)
        #expect(comparison(content) == down(50))
    }

    @Test func eventInSubSecondGapAfterWeekBeforeLastEnd_countsTowardWeekBeforeLast() async throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let now = wednesday()
        let weekBeforeLast = InsightsPeriod.week.dateRange(offset: -2, now: now, calendar: calendar)
        let fake = FakeNotificationCenter()
        let service = WeeklySummaryService(center: fake, defaults: makeDefaults())
        let container = try makeContainer()
        seed([-1: 1], reference: now, calendar: calendar, into: container.mainContext)
        container.mainContext.insert(ConsumptionEvent(
            consumptionDate: weekBeforeLast.upperBound.addingTimeInterval(0.5),
            volumeMl: 500, abv: 0.05, quantity: 2, category: .beer, icon: "🍺"
        ))

        await service.scheduleIfEnabled(context: container.mainContext, now: now, calendar: calendar)
        let content = try service.summaryContent(in: container.mainContext, now: now, calendar: calendar)

        #expect(fake.addedRequests.count == 1)
        #expect(comparison(content) == down(50))
    }

    // MARK: - Fetch failure

    // A failed read is not "no alcohol": the pending request must be left alone, neither cancelled nor
    // replaced from partial data. The service reads three times (last week, the week before last, and
    // whether any older data exists); each read is failed in turn so a swallowed error on any one of them
    // is caught, not just the first.
    @Test(arguments: [0, 1, 2])
    func fetchFailure_leavesThePendingRequestUntouched(failingCallIndex: Int) async throws {
        struct FetchFailure: Error {}
        let fake = FakeNotificationCenter()
        var callCount = 0
        let service = WeeklySummaryService(center: fake, defaults: makeDefaults(), fetch: { context, descriptor in
            defer { callCount += 1 }
            if callCount == failingCallIndex { throw FetchFailure() }
            return try context.fetch(descriptor)
        })
        let container = try makeContainer()

        await service.scheduleIfEnabled(context: container.mainContext, now: wednesday(), calendar: makeCalendar(firstWeekday: 2))

        #expect(callCount == failingCallIndex + 1)
        #expect(fake.addedRequests.isEmpty)
        #expect(fake.removedBatches.isEmpty)
    }

    // MARK: - Sunday-first calendar

    @Test func sundayFirstCalendar_schedulesOnWeekdayOneAndComparesItsOwnWeeks() async throws {
        let calendar = makeCalendar(firstWeekday: 1)
        let (fake, content) = try await schedule(
            now: wednesday(), calendar: calendar,
            counts: [-2: 3, -1: 1, 0: 5], seededAround: wednesday()
        )

        let request = try #require(fake.addedRequests.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.dateComponents.weekday == 1)
        #expect(comparison(content) == down(67))
    }

    // MARK: - F4 characterization

    // Documents finding F4: the comparison is made at scheduling time but delivered at the next firstWeekday
    // 09:00, by which time "last week" has moved one week forward. Since plan 0049 the body is one neutral
    // line, so the stale comparison no longer reaches the person; the test pins both facts.
    @Test func f4_bakedComparisonIsOneWeekBehindAtTheNextDelivery() async throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let now = wednesday()
        let (fake, content) = try await schedule(
            now: now, calendar: calendar,
            counts: [-2: 2, -1: 1, 0: 2], seededAround: now
        )
        let delivery = try #require(calendar.nextDate(
            after: now,
            matching: DateComponents(hour: WeeklySummaryService.fireHour, minute: WeeklySummaryService.fireMinute, weekday: calendar.firstWeekday),
            matchingPolicy: .nextTime
        ))

        let lastWeekWhenScheduled = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)
        let lastWeekAtDelivery = InsightsPeriod.week.dateRange(offset: -1, now: delivery, calendar: calendar)
        let weekContainingNow = InsightsPeriod.week.dateRange(offset: 0, now: now, calendar: calendar)
        #expect(lastWeekAtDelivery != lastWeekWhenScheduled)
        #expect(lastWeekAtDelivery == weekContainingNow)

        // A delivery-time comparison (week 0 = 2 against week -1 = 1) would differ from the scheduled one,
        // but the delivered body carries no comparison at all.
        #expect(comparison(content) == down(50))
        #expect(comparison(content) != up(100))
        #expect(fake.addedRequests.first?.content.body == String(localized: "weeklySummary.notification.body"))
    }
}
