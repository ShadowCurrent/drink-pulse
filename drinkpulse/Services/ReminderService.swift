import Foundation
import OSLog
import UserNotifications

@MainActor
final class ReminderService {
    static let reminderIdentifier = "dp.daily.log.reminder"

    static let defaultHour = 21
    static let defaultMinute = 0

    private let centerProvider: () -> NotificationScheduling
    private lazy var center: NotificationScheduling = centerProvider()
    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "ReminderService")

    // F3 (10-DECISION-F3.md): lifecycleEpoch advances on every schedule and cancel;
    // cancelEpoch holds the lifecycleEpoch value at the latest cancel. Both mutate
    // synchronously on the main actor, so the post-add comparison cannot race.
    private var lifecycleEpoch = 0
    private var cancelEpoch = 0

    init(
        center: @autoclosure @escaping () -> NotificationScheduling = ReminderService.defaultCenter(),
        defaults: UserDefaults = .standard
    ) {
        self.centerProvider = center
        self.defaults = defaults
    }

    nonisolated static func defaultCenter() -> NotificationScheduling {
        UITestSeed.isActive ? UITestNotificationCenter() : UNUserNotificationCenter.current()
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

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

    func schedule(hour: Int, minute: Int) async throws {
        lifecycleEpoch += 1
        let myEpoch = lifecycleEpoch
        center.removePendingRequests(withIdentifiers: [Self.reminderIdentifier])
        try await center.add(makeRequest(hour: hour, minute: minute))
        // Actor reentrancy lets cancel() run while suspended in add. Remove our own request
        // only when the latest lifecycle event is a cancel issued after this call began; a
        // later schedule owns the identifier and applies its own check.
        if cancelEpoch == lifecycleEpoch, cancelEpoch > myEpoch {
            center.removePendingRequests(withIdentifiers: [Self.reminderIdentifier])
        }
    }

    func cancel() async {
        lifecycleEpoch += 1
        cancelEpoch = lifecycleEpoch
        center.removePendingRequests(withIdentifiers: [Self.reminderIdentifier])
    }

    func scheduleIfEnabled() async {
        guard defaults.bool(forKey: AppStorageKeys.reminderEnabled) else { return }
        let hour = (defaults.object(forKey: AppStorageKeys.reminderHour) as? Int) ?? Self.defaultHour
        let minute = (defaults.object(forKey: AppStorageKeys.reminderMinute) as? Int) ?? Self.defaultMinute
        do {
            try await schedule(hour: hour, minute: minute)
        } catch {
            logger.error("Failed to reschedule reminder: \(error.localizedDescription)")
        }
    }
}
