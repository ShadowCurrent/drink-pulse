import Foundation
import OSLog
import UserNotifications

/// Schedules / cancels the opt-in daily "log your drinks" local notification
/// (plan-0016). First member of the `Services/` layer (ADR-0008): orchestrates
/// `UNUserNotificationCenter` through the injected `NotificationScheduling`
/// protocol so the logic is unit-testable with a fake centre.
///
/// The reminder is purely a prompt to *log* — never a consumption
/// recommendation — consistent with the project's risk-language stance.
@MainActor
final class ReminderService {
    /// Stable identifier for the single repeating reminder request. Using one
    /// fixed id makes scheduling idempotent: rescheduling replaces in place.
    static let reminderIdentifier = "dp.daily.log.reminder"

    /// Default fire time when the reminder is first enabled (Q1 → 21:00).
    static let defaultHour = 21
    static let defaultMinute = 0

    private let center: NotificationScheduling
    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "ReminderService")

    init(
        center: NotificationScheduling = ReminderService.defaultCenter(),
        defaults: UserDefaults = .standard
    ) {
        self.center = center
        self.defaults = defaults
    }

    /// Real notification centre in production; a non-prompting stub under the
    /// `-dp_uitest` launch arg so UI tests never hit the system permission
    /// alert. Inert in production (`UITestSeed.isActive` is always false there).
    nonisolated static func defaultCenter() -> NotificationScheduling {
        UITestSeed.isActive ? UITestNotificationCenter() : UNUserNotificationCenter.current()
    }

    /// Requests alert + sound authorization (no badge). Returns whether granted.
    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    /// Pure factory: builds the repeating request for the given fire time.
    /// Extracted so tests can assert on the trigger without scheduling.
    func makeRequest(hour: Int, minute: Int) -> UNNotificationRequest {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = String(localized: "reminder.notification.title")
        content.body = String(localized: "reminder.notification.body")
        content.sound = .default

        return UNNotificationRequest(
            identifier: Self.reminderIdentifier,
            content: content,
            trigger: trigger
        )
    }

    /// Removes any existing reminder first (idempotency), then adds one
    /// repeating request — toggling or changing the time never leaves two
    /// pending requests behind.
    func schedule(hour: Int, minute: Int) async throws {
        center.removePendingRequests(withIdentifiers: [Self.reminderIdentifier])
        try await center.add(makeRequest(hour: hour, minute: minute))
    }

    /// Removes the pending reminder request, if any.
    func cancel() async {
        center.removePendingRequests(withIdentifiers: [Self.reminderIdentifier])
    }

    /// Reads the `@AppStorage`-backed settings and re-applies the schedule when
    /// the reminder is enabled. Safe to call at launch and on `scenePhase
    /// == .active`; a no-op when disabled.
    func scheduleIfEnabled() async {
        guard defaults.bool(forKey: AppStorageKeys.reminderEnabled) else { return }
        let hour = (defaults.object(forKey: AppStorageKeys.reminderHour) as? Int) ?? Self.defaultHour
        let minute = (defaults.object(forKey: AppStorageKeys.reminderMinute) as? Int) ?? Self.defaultMinute
        do {
            try await schedule(hour: hour, minute: minute)
        } catch {
            // Scheduling failure is non-fatal (the user simply gets no reminder);
            // log the category, never the time value, and move on.
            logger.error("Failed to reschedule reminder: \(error.localizedDescription)")
        }
    }
}
