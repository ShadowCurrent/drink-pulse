import Foundation
import Testing
import UserNotifications
@testable import drinkpulse

/// Records `NotificationScheduling` calls so `ReminderService` can be tested
/// without touching the real notification centre — no authorization prompt and
/// no real scheduled notification is ever produced. `@unchecked Sendable`: all
/// access happens on the MainActor (the tests and the service are `@MainActor`).
final class FakeNotificationCenter: NotificationScheduling, @unchecked Sendable {
    var authorizationResult = true
    var authorizationError: Error?
    var addError: Error?

    private(set) var authCallCount = 0
    private(set) var addedRequests: [UNNotificationRequest] = []
    private(set) var removedBatches: [[String]] = []
    private(set) var pendingIds: [String] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        authCallCount += 1
        if let authorizationError { throw authorizationError }
        return authorizationResult
    }

    func add(_ request: UNNotificationRequest) async throws {
        if let addError { throw addError }
        addedRequests.append(request)
        pendingIds.append(request.identifier)
    }

    func pendingRequestIdentifiers() async -> [String] { pendingIds }

    func removePendingRequests(withIdentifiers ids: [String]) {
        removedBatches.append(ids)
        pendingIds.removeAll { ids.contains($0) }
    }
}

private struct TestError: Error {}

@MainActor
struct ReminderServiceTests {

    private func makeDefaults() -> UserDefaults {
        // Isolated suite so tests never read/write the real app domain.
        let defaults = UserDefaults(suiteName: "test.reminder.\(UUID().uuidString)")!
        return defaults
    }

    // MARK: - makeRequest

    @Test func makeRequest_buildsRepeatingTrigger_atGivenHourMinute() {
        let service = ReminderService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(hour: 21, minute: 0)

        let trigger = request.trigger as? UNCalendarNotificationTrigger
        #expect(trigger?.repeats == true)
        #expect(trigger?.dateComponents.hour == 21)
        #expect(trigger?.dateComponents.minute == 0)
        #expect(request.identifier == ReminderService.reminderIdentifier)
    }

    @Test func makeRequest_setsLocalizedTitleBodyAndSound() {
        let service = ReminderService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(hour: 9, minute: 30)

        #expect(request.content.title == String(localized: "reminder.notification.title"))
        #expect(request.content.body == String(localized: "reminder.notification.body"))
        #expect(request.content.sound == .default)
    }

    // MARK: - schedule

    @Test func schedule_addsExactlyOneRequest_withReminderIdentifier() async throws {
        let fake = FakeNotificationCenter()
        let service = ReminderService(center: fake, defaults: makeDefaults())

        try await service.schedule(hour: 21, minute: 0)

        #expect(fake.addedRequests.count == 1)
        #expect(fake.addedRequests.first?.identifier == ReminderService.reminderIdentifier)
        #expect(fake.pendingIds == [ReminderService.reminderIdentifier])
    }

    @Test func schedule_isIdempotent_leavesOnePendingRequest() async throws {
        let fake = FakeNotificationCenter()
        let service = ReminderService(center: fake, defaults: makeDefaults())

        try await service.schedule(hour: 21, minute: 0)
        try await service.schedule(hour: 8, minute: 15)

        // Two add calls, but remove-then-add keeps exactly one pending request.
        #expect(fake.addedRequests.count == 2)
        #expect(fake.pendingIds == [ReminderService.reminderIdentifier])
        // Each schedule removes first → ordering guarantee (no double pending).
        #expect(fake.removedBatches.count == 2)
        #expect(fake.removedBatches.allSatisfy { $0 == [ReminderService.reminderIdentifier] })
    }

    // MARK: - cancel

    @Test func cancel_removesPendingReminder() async throws {
        let fake = FakeNotificationCenter()
        let service = ReminderService(center: fake, defaults: makeDefaults())
        try await service.schedule(hour: 21, minute: 0)

        await service.cancel()

        #expect(fake.pendingIds.isEmpty)
        #expect(fake.removedBatches.last == [ReminderService.reminderIdentifier])
    }

    // MARK: - requestAuthorization

    @Test func requestAuthorization_returnsGrantedResult() async throws {
        let fake = FakeNotificationCenter()
        fake.authorizationResult = true
        let service = ReminderService(center: fake, defaults: makeDefaults())

        let granted = try await service.requestAuthorization()

        #expect(granted == true)
        #expect(fake.authCallCount == 1)
    }

    @Test func requestAuthorization_propagatesError() async {
        let fake = FakeNotificationCenter()
        fake.authorizationError = TestError()
        let service = ReminderService(center: fake, defaults: makeDefaults())

        await #expect(throws: TestError.self) {
            _ = try await service.requestAuthorization()
        }
    }

    // MARK: - scheduleIfEnabled

    @Test func scheduleIfEnabled_doesNothing_whenDisabled() async {
        let fake = FakeNotificationCenter()
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppStorageKeys.reminderEnabled)
        let service = ReminderService(center: fake, defaults: defaults)

        await service.scheduleIfEnabled()

        #expect(fake.addedRequests.isEmpty)
    }

    @Test func scheduleIfEnabled_schedulesStoredTime_whenEnabled() async {
        let fake = FakeNotificationCenter()
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppStorageKeys.reminderEnabled)
        defaults.set(8, forKey: AppStorageKeys.reminderHour)
        defaults.set(45, forKey: AppStorageKeys.reminderMinute)
        let service = ReminderService(center: fake, defaults: defaults)

        await service.scheduleIfEnabled()

        #expect(fake.addedRequests.count == 1)
        let trigger = fake.addedRequests.first?.trigger as? UNCalendarNotificationTrigger
        #expect(trigger?.dateComponents.hour == 8)
        #expect(trigger?.dateComponents.minute == 45)
    }

    @Test func scheduleIfEnabled_usesDefaultTime_whenNoStoredTime() async {
        let fake = FakeNotificationCenter()
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppStorageKeys.reminderEnabled)
        // No hour/minute stored → falls back to 21:00.
        let service = ReminderService(center: fake, defaults: defaults)

        await service.scheduleIfEnabled()

        let trigger = fake.addedRequests.first?.trigger as? UNCalendarNotificationTrigger
        #expect(trigger?.dateComponents.hour == ReminderService.defaultHour)
        #expect(trigger?.dateComponents.minute == ReminderService.defaultMinute)
    }

    @Test func scheduleIfEnabled_swallowsSchedulingError() async {
        let fake = FakeNotificationCenter()
        fake.addError = TestError()
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppStorageKeys.reminderEnabled)
        let service = ReminderService(center: fake, defaults: defaults)

        // Must not throw — failure is logged and ignored (no reminder, no crash).
        await service.scheduleIfEnabled()

        #expect(fake.addedRequests.isEmpty)
    }
}
