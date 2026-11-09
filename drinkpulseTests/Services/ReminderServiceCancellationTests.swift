import Foundation
import Testing
import UserNotifications
@testable import drinkpulse

@MainActor
struct ReminderServiceCancellationTests {

    private let identifier = ReminderService.reminderIdentifier

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test.reminderCancellation.\(UUID().uuidString)")!
    }

    // MARK: - F3 pin

    @Test func cancel_whileScheduleSuspendedInAdd_leavesNoPendingRequest() async throws {
        let center = SlowNotificationCenter()
        let service = ReminderService(center: center, defaults: makeDefaults())
        defer { center.release() }

        let scheduling = Task { try await service.schedule(hour: 9, minute: 0) }
        try #require(await center.waitUntilAddEntered(), "schedule never reached add within the deadline")

        await service.cancel()
        center.release()
        try await scheduling.value

        let pending = await center.pendingRequestIdentifiers()
        // Finding F3 (10-DECISION-F3.md): the in-flight add lands after the cancel, so the
        // reminder stays pending after the user opted out. Remove this wrapper when the
        // approved fix lands (plan 10-09) or keep it as documentation if the owner retains it.
        withKnownIssue("F3: a cancel issued while schedule is suspended in add does not stop that add") {
            #expect(pending.isEmpty)
        }
    }

    // MARK: - Controls

    @Test func cancel_afterScheduleCompleted_leavesNoPendingRequest() async throws {
        let center = SlowNotificationCenter()
        center.release()
        let service = ReminderService(center: center, defaults: makeDefaults())

        try await service.schedule(hour: 9, minute: 0)
        await service.cancel()

        let pending = await center.pendingRequestIdentifiers()
        #expect(pending.isEmpty)
        let removals = center.operationLog.compactMap { operation -> [String]? in
            if case .remove(let ids) = operation { return ids }
            return nil
        }
        #expect(!removals.isEmpty)
        #expect(removals.allSatisfy { $0 == [identifier] })
    }

    @Test func scheduleCancelSchedule_leavesExactlyOnePendingRequest() async throws {
        let center = SlowNotificationCenter()
        center.release()
        let service = ReminderService(center: center, defaults: makeDefaults())

        try await service.schedule(hour: 9, minute: 0)
        await service.cancel()
        try await service.schedule(hour: 10, minute: 30)

        let pending = await center.pendingRequestIdentifiers()
        #expect(pending == [identifier])
    }
}
