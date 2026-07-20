import Foundation
import Testing
import UserNotifications
@testable import drinkpulse

/// Unit coverage for `WeeklySummaryService` (plan 01-02) — mirrors
/// `ReminderServiceTests`' shape exactly, reusing its `FakeNotificationCenter`
/// directly (declared with no access modifier in that file, so it's visible
/// here as an internal type of the `drinkpulseTests` target).
@MainActor
struct WeeklySummaryServiceTests {

    private func makeDefaults() -> UserDefaults {
        // Isolated suite so tests never read/write the real app domain.
        let defaults = UserDefaults(suiteName: "test.weeklySummary.\(UUID().uuidString)")!
        return defaults
    }

    // MARK: - makeRequest

    @Test func makeRequest_returnsNil_forSkipContent() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .skip)
        #expect(request == nil)
    }

    @Test func makeRequest_buildsWeeklyRepeatingTrigger_atFireHourMinute_withInjectedFirstWeekday() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        let request = service.makeRequest(
            calendar: calendar,
            content: .percentage(fraction: 0.12, direction: .up)
        )

        let trigger = request?.trigger as? UNCalendarNotificationTrigger
        #expect(trigger?.dateComponents.weekday == 2)
        #expect(trigger?.dateComponents.hour == 9)
        #expect(trigger?.dateComponents.minute == 0)
        #expect(trigger?.repeats == true)
        #expect(request?.identifier == WeeklySummaryService.weeklySummaryIdentifier)
    }

    @Test func makeRequest_setsLocalizedTitle_forEveryContentBranch() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .percentage(fraction: 0.12, direction: .up))
        #expect(request?.content.title == String(localized: "weeklySummary.notification.title"))
    }

    @Test func makeRequest_bodyText_percentageUp_interpolatesRoundedWholePercent() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .percentage(fraction: 0.12, direction: .up))
        #expect(request?.content.body == String(format: String(localized: "weeklySummary.notification.body.up"), 12))
    }

    @Test func makeRequest_bodyText_percentageDown_interpolatesRoundedWholePercent() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .percentage(fraction: -0.34, direction: .down))
        #expect(request?.content.body == String(format: String(localized: "weeklySummary.notification.body.down"), 34))
    }

    @Test func makeRequest_bodyText_percentageSame_hasNoInterpolation() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .percentage(fraction: 0.02, direction: .same))
        #expect(request?.content.body == String(localized: "weeklySummary.notification.body.same"))
    }

    @Test func makeRequest_bodyText_directionOnlyUp() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .directionOnly(.up))
        #expect(request?.content.body == String(localized: "weeklySummary.notification.body.directionOnlyUp"))
    }

    @Test func makeRequest_bodyText_directionOnlySame() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .directionOnly(.same))
        #expect(request?.content.body == String(localized: "weeklySummary.notification.body.directionOnlySame"))
    }

    // MARK: - cancel

    @Test func cancel_removesPendingWeeklySummaryRequest() async throws {
        let fake = FakeNotificationCenter()
        let service = WeeklySummaryService(center: fake, defaults: makeDefaults())
        let request = service.makeRequest(content: .percentage(fraction: 0.12, direction: .up))!
        try await fake.add(request)

        await service.cancel()

        #expect(fake.pendingIds.isEmpty)
        #expect(fake.removedBatches.last == [WeeklySummaryService.weeklySummaryIdentifier])
    }

    // MARK: - requestAuthorization

    @Test func requestAuthorization_returnsGrantedResult_andPropagatesError() async throws {
        let fakeGranted = FakeNotificationCenter()
        fakeGranted.authorizationResult = true
        let grantedService = WeeklySummaryService(center: fakeGranted, defaults: makeDefaults())

        let granted = try await grantedService.requestAuthorization()

        #expect(granted == true)
        #expect(fakeGranted.authCallCount == 1)

        struct LocalTestError: Error {}
        let fakeError = FakeNotificationCenter()
        fakeError.authorizationError = LocalTestError()
        let errorService = WeeklySummaryService(center: fakeError, defaults: makeDefaults())

        await #expect(throws: LocalTestError.self) {
            _ = try await errorService.requestAuthorization()
        }
    }
}
