import Foundation
import UserNotifications

protocol NotificationScheduling: Sendable {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func pendingRequestIdentifiers() async -> [String]
    func removePendingRequests(withIdentifiers ids: [String])
}

extension UNUserNotificationCenter: @retroactive @unchecked Sendable {}

extension UNUserNotificationCenter: NotificationScheduling {
    func pendingRequestIdentifiers() async -> [String] {
        await pendingNotificationRequests().map(\.identifier)
    }

    func removePendingRequests(withIdentifiers ids: [String]) {
        removePendingNotificationRequests(withIdentifiers: ids)
    }
}
