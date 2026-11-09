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

    /// Models the system notification center handing a tapped notification to the delegate.
    /// It does not consult `pending`: the double has no clock that could deliver a scheduled
    /// request by itself, so the UI test decides when the tap happens.
    func deliverTap(identifier: String) async {
        await NotificationActionHandler.route(identifier: identifier)
    }
}
