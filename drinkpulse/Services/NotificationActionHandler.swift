import Foundation
import UserNotifications

final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let didTapReminder = Notification.Name("dp.didTapReminder")

    static let didTapWeeklySummary = Notification.Name("dp.didTapWeeklySummary")

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let id = response.notification.request.identifier
        if id == ReminderService.reminderIdentifier {
            UserDefaults.standard.set(true, forKey: AppStorageKeys.pendingAddDrink)
            await MainActor.run {
                NotificationCenter.default.post(name: Self.didTapReminder, object: nil)
            }
        } else if id == WeeklySummaryService.weeklySummaryIdentifier {
            UserDefaults.standard.set(true, forKey: AppStorageKeys.pendingOpenInsights)
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
