import Foundation
import UserNotifications

/// Launch-argument-gated stand-in for `UNUserNotificationCenter`, used only
/// when `-dp_uitest` is active (see `UITestSeed`). It auto-grants
/// authorization and no-ops scheduling so UI tests can exercise the Reminders
/// toggle/time wiring **without** triggering the real, locale-dependent system
/// permission alert and without scheduling a real notification on the
/// simulator.
///
/// Inert in production: `ReminderService.defaultCenter()` only selects it when
/// `UITestSeed.isActive` is `true`, which is impossible outside a UI-test launch.
/// Carries no PII and performs no real platform side effects.
final class UITestNotificationCenter: NotificationScheduling, @unchecked Sendable {
    private var pending: [String] = []

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
