import Foundation
import UserNotifications

/// `UNUserNotificationCenter` delegate that turns a tap on the daily log
/// reminder into an "open Add Drink" intent (plan-0016, Q3 → option A).
///
/// On tap it sets a persisted `@AppStorage` flag (so the action survives a
/// cold launch — the shell reads & clears it on appear) and posts an in-process
/// event for the already-running case. Inert for any other notification id.
///
/// `NSObject` subclass because `UNUserNotificationCenterDelegate` requires it;
/// it carries no app state, so this is not a view model and does not use
/// `@Observable`.
///
/// `@unchecked Sendable`: holds zero stored properties (only static
/// identifiers) and its delegate methods only touch `UserDefaults` /
/// `NotificationCenter`, both thread-safe — safe to assign as the
/// notification-centre delegate from a background task (`drinkpulseApp.init`
/// resolves `UNUserNotificationCenter.current()` off the main thread to avoid
/// blocking first-frame render on its documented XPC connection setup).
final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    /// Posted on the main actor when the user taps the reminder while the app
    /// is already running; the shell observes it to present Add Drink.
    static let didTapReminder = Notification.Name("dp.didTapReminder")

    /// Posted on the main actor when the user taps the weekly summary while
    /// the app is already running; the shell observes it to select Insights.
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

    /// Show the reminder as a banner + sound even when the app is foregrounded,
    /// so a user looking at the app still gets the nudge.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
