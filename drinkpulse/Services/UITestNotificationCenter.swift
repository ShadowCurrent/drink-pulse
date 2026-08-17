import Foundation
import UserNotifications

final class UITestNotificationCenter: NotificationScheduling, @unchecked Sendable {
    private var pending: [String] = []

    nonisolated init() {}

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        true
    }

    func add(_ request: UNNotificationRequest) async throws {
        pending.append(request.identifier)
    }

    func pendingRequestIdentifiers() async -> [String] { pending }

    func removePendingRequests(withIdentifiers ids: [String]) {
        pending.removeAll { ids.contains($0) }
    }
}
