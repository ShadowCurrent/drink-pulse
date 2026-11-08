import Foundation
import SwiftData
import Testing
import UserNotifications
@testable import drinkpulse

// Pins the completed-week comparison of WeeklySummaryService.scheduleIfEnabled at fixed dates (D-15).
// Expected bodies are derived from the localized keys, so the tests stay valid when the owner-approved
// wording lands; explicit-wording assertions belong to plan 10-10.
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
    ) async throws -> FakeNotificationCenter {
        let fake = FakeNotificationCenter()
        let service = WeeklySummaryService(center: fake, defaults: makeDefaults())
        let container = try makeContainer()
        seed(counts, reference: reference, calendar: calendar, into: container.mainContext)
        await service.scheduleIfEnabled(context: container.mainContext, now: now, calendar: calendar)
        return fake
    }

    private func downBody(_ percent: Int) -> String {
        String(format: String(localized: "weeklySummary.notification.body.down"), percent)
    }

    private func upBody(_ percent: Int) -> String {
        String(format: String(localized: "weeklySummary.notification.body.up"), percent)
    }

    // MARK: - Monday-first calendar

    @Test func wednesday_comparesWeekBeforeCurrentWeekAgainstTheOneBeforeThat() async throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let fake = try await schedule(
            now: wednesday(), calendar: calendar,
            counts: [-2: 2, -1: 1, 0: 2], seededAround: wednesday()
        )

        let request = try #require(fake.addedRequests.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(request.content.body == downBody(50))
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.weekday == 2)
        #expect(trigger.dateComponents.hour == 9)
        #expect(trigger.dateComponents.minute == 0)
        #expect(request.identifier == WeeklySummaryService.weeklySummaryIdentifier)
    }

    @Test func sundayNight_stillExcludesTheInProgressWeek() async throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let fake = try await schedule(
            now: utc(2026, 3, 22, 23, 30), calendar: calendar,
            counts: [-2: 2, -1: 1, 0: 2], seededAround: wednesday()
        )

        #expect(fake.addedRequests.first?.content.body == downBody(50))
    }

    @Test func mondayAfterMidnight_rollsTheComparisonForwardOneWeek() async throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let fake = try await schedule(
            now: utc(2026, 3, 23, 0, 30), calendar: calendar,
            counts: [-2: 2, -1: 1, 0: 2], seededAround: wednesday()
        )

        #expect(fake.addedRequests.first?.content.body == upBody(100))
    }

    // MARK: - Sunday-first calendar

    @Test func sundayFirstCalendar_schedulesOnWeekdayOneAndComparesItsOwnWeeks() async throws {
        let calendar = makeCalendar(firstWeekday: 1)
        let fake = try await schedule(
            now: wednesday(), calendar: calendar,
            counts: [-2: 3, -1: 1, 0: 5], seededAround: wednesday()
        )

        let request = try #require(fake.addedRequests.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.dateComponents.weekday == 1)
        #expect(request.content.body == downBody(67))
    }

    // MARK: - F4 characterization

    // Documents finding F4: the body is baked at scheduling time but delivered at the next firstWeekday
    // 09:00, by which time "last week" has moved one week forward; this test pins the staleness, not a fix.
    @Test func f4_bakedComparisonIsOneWeekBehindAtTheNextDelivery() async throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let now = wednesday()
        let fake = try await schedule(
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

        // What a delivery-time comparison would say (week 0 = 2 against week -1 = 1) differs from the baked body.
        #expect(fake.addedRequests.first?.content.body == downBody(50))
        #expect(fake.addedRequests.first?.content.body != upBody(100))
    }
}
