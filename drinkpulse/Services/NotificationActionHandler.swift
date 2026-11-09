import Foundation
import UserNotifications
import OSLog

final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate, Sendable {
    private static let logger = Logger(subsystem: "com.drinkpulse.app", category: "NotificationActionHandler")

    static let didTapReminder = Notification.Name("dp.didTapReminder")

    static let didTapWeeklySummary = Notification.Name("dp.didTapWeeklySummary")

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        Self.logger.notice("Notification tap received, kind: \(Self.tapKind(forIdentifier: response.notification.request.identifier), privacy: .public)")
        await Self.route(identifier: response.notification.request.identifier)
    }

    /// Classifies a tapped notification for logging. Returns one of three constants, so the log
    /// line never carries the raw identifier or any payload field.
    static func tapKind(forIdentifier id: String) -> String {
        if id == ReminderService.reminderIdentifier { return "daily" }
        if id == WeeklySummaryService.weeklySummaryIdentifier { return "weekly" }
        return "other"
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
