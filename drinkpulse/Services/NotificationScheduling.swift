import Foundation
import UserNotifications

/// Narrow abstraction over the parts of `UNUserNotificationCenter` the app
/// uses, so `ReminderService` is unit-testable without touching the real
/// notification centre (no real authorization prompt, no real scheduling).
///
/// The real conformance (below) is a thin framework adapter — excluded from
/// unit coverage as framework glue (see ADR-0008). Tests inject a fake.
protocol NotificationScheduling: Sendable {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func pendingRequestIdentifiers() async -> [String]
    func removePendingRequests(withIdentifiers ids: [String])
}

/// Thin adapter: `UNUserNotificationCenter` already provides
/// `requestAuthorization(options:)` and `add(_:)` with matching async
/// signatures; only the two convenience-named members need bridging.
extension UNUserNotificationCenter: @retroactive @unchecked Sendable {}

extension UNUserNotificationCenter: NotificationScheduling {
    func pendingRequestIdentifiers() async -> [String] {
        await pendingNotificationRequests().map(\.identifier)
    }

    func removePendingRequests(withIdentifiers ids: [String]) {
        removePendingNotificationRequests(withIdentifiers: ids)
    }
}
