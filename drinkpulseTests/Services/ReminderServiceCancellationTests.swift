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

    // MARK: - F3 regression

    /// Finding F3 (10-DECISION-F3.md, outcome fix-service-epoch): a cancel issued while schedule
    /// is suspended in add must win, so the in-flight add's request does not stay pending.
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
        #expect(pending.isEmpty)
    }

    /// Schedule A is held in add, cancel runs, schedule B completes, then A's add returns.
    /// A must not remove B's request: the latest lifecycle event is B's schedule, not a cancel.
    @Test func scheduleHeld_thenCancel_thenLaterSchedule_keepsLaterRequest() async throws {
        let center = SlowNotificationCenter()
        let service = ReminderService(center: center, defaults: makeDefaults())
        defer { center.release() }

        let first = Task { try await service.schedule(hour: 9, minute: 0) }
        try #require(await center.waitUntilAddEntered(), "schedule never reached add within the deadline")

        await service.cancel()
        try await service.schedule(hour: 10, minute: 30)
        center.release()
        try await first.value

        let pending = await center.pendingRequestIdentifiers()
        #expect(pending == [identifier])
        #expect(removalsAfterFirstAdd(in: center) == 0)
    }

    /// Schedule A is held, schedule B completes with no cancel, then A's add returns.
    @Test func scheduleHeld_thenLaterSchedule_keepsLaterRequest() async throws {
        let center = SlowNotificationCenter()
        let service = ReminderService(center: center, defaults: makeDefaults())
        defer { center.release() }

        let first = Task { try await service.schedule(hour: 9, minute: 0) }
        try #require(await center.waitUntilAddEntered(), "schedule never reached add within the deadline")

        try await service.schedule(hour: 10, minute: 30)
        center.release()
        try await first.value

        let pending = await center.pendingRequestIdentifiers()
        #expect(pending == [identifier])
        #expect(removalsAfterFirstAdd(in: center) == 0)
    }

    private func removalsAfterFirstAdd(in center: SlowNotificationCenter) -> Int {
        let log = center.operationLog
        guard let firstAdd = log.firstIndex(where: { if case .add = $0 { return true } else { return false } }) else {
            return 0
        }
        return log[(firstAdd + 1)...].filter { if case .remove = $0 { return true } else { return false } }.count
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

    @Test func schedule_withoutCancel_leavesRequestPendingAfterAdd() async throws {
        let center = SlowNotificationCenter()
        let service = ReminderService(center: center, defaults: makeDefaults())
        defer { center.release() }

        let scheduling = Task { try await service.schedule(hour: 9, minute: 0) }
        try #require(await center.waitUntilAddEntered(), "schedule never reached add within the deadline")
        center.release()
        try await scheduling.value

        let pending = await center.pendingRequestIdentifiers()
        #expect(pending == [identifier])
    }
}
