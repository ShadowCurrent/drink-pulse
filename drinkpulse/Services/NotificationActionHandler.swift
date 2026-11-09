import Foundation
import UserNotifications

final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate, Sendable {
    static let didTapReminder = Notification.Name("dp.didTapReminder")

    static let didTapWeeklySummary = Notification.Name("dp.didTapWeeklySummary")

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await Self.route(identifier: response.notification.request.identifier)
    }

    /// Routes a tapped notification to the app: sets the matching pending flag (cold launch)
    /// and posts the matching tap notification (warm app). Extracted from the delegate callback
    /// so tests can drive a tap without constructing `UNNotificationResponse`, which has no
    /// public initializer.
    static func route(identifier id: String, defaults: UserDefaults = .standard) async {
        if id == ReminderService.reminderIdentifier {
            defaults.set(true, forKey: AppStorageKeys.pendingAddDrink)
            await MainActor.run {
                NotificationCenter.default.post(name: Self.didTapReminder, object: nil)
            }
        } else if id == WeeklySummaryService.weeklySummaryIdentifier {
            defaults.set(true, forKey: AppStorageKeys.pendingOpenInsights)
            await MainActor.run {
                NotificationCenter.default.post(name: Self.didTapWeeklySummary, object: nil)
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
