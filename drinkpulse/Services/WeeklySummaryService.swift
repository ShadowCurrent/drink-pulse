import Foundation
import OSLog
import UserNotifications

/// Schedules / cancels the opt-in weekly "here's your week-over-week alcohol
/// summary" local notification (v1.1). Mirrors `ReminderService`'s exact shape
/// (ADR-0008 Services layer): stable identifier, pure trigger factory,
/// idempotent schedule/cancel, `@AppStorage`-gated `scheduleIfEnabled`. The
/// dynamic notification body comes from `WeeklySummaryCalculator` (plan
/// 01-01); `scheduleIfEnabled(context:)` (added in plan 01-02 Task 2) fetches
/// current/prior-week `ConsumptionEvent`s directly via SwiftData.
@MainActor
final class WeeklySummaryService {
    /// Stable identifier for the single repeating weekly-summary request.
    /// One fixed id makes scheduling idempotent: rescheduling replaces in place.
    static let weeklySummaryIdentifier = "dp.weekly.summary"

    /// Fixed local fire time: 9am on the locale's first day of the week.
    static let fireHour = 9
    static let fireMinute = 0

    private let center: NotificationScheduling
    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "WeeklySummaryService")

    init(
        center: NotificationScheduling = WeeklySummaryService.defaultCenter(),
        defaults: UserDefaults = .standard
    ) {
        self.center = center
        self.defaults = defaults
    }

    /// Real notification centre in production; a non-prompting stub under the
    /// `-dp_uitest` launch arg so UI tests never hit the system permission
    /// alert (identical conditional to `ReminderService.defaultCenter()`).
    nonisolated static func defaultCenter() -> NotificationScheduling {
        UITestSeed.isActive ? UITestNotificationCenter() : UNUserNotificationCenter.current()
    }

    /// Requests alert + sound authorization (no badge). Returns whether granted.
    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    /// Pure factory: builds the weekly-repeating request for the given
    /// content, or `nil` when there is nothing to schedule (`.skip`).
    /// `calendar` is read fresh at call time (never cached at service-init)
    /// so a Region-setting change is picked up on the next call (ENGG-03).
    func makeRequest(calendar: Calendar = .current, content: WeeklySummaryContent) -> UNNotificationRequest? {
        guard content != .skip else { return nil }

        var components = DateComponents()
        components.weekday = calendar.firstWeekday
        components.hour = Self.fireHour
        components.minute = Self.fireMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let notification = UNMutableNotificationContent()
        notification.title = String(localized: "weeklySummary.notification.title")
        notification.body = Self.bodyText(for: content)
        notification.sound = .default

        return UNNotificationRequest(
            identifier: Self.weeklySummaryIdentifier,
            content: notification,
            trigger: trigger
        )
    }

    /// Removes the pending weekly-summary request, if any.
    func cancel() async {
        center.removePendingRequests(withIdentifiers: [Self.weeklySummaryIdentifier])
    }

    /// Maps a classified `WeeklySummaryContent` to its localized notification
    /// body. Never interpolates raw grams — only the rounded whole-percent
    /// magnitude (matches `InsightsHeroCard.TrendBadge`'s rounding idiom,
    /// not its ±1% "unchanged" threshold, which lives in `WeeklySummaryCalculator`).
    private static func bodyText(for content: WeeklySummaryContent) -> String {
        switch content {
        case .skip:
            // Unreachable via makeRequest's guard; kept only for exhaustiveness.
            return ""
        case .directionOnly(let direction):
            switch direction {
            case .up:
                return String(localized: "weeklySummary.notification.body.directionOnlyUp")
            default:
                return String(localized: "weeklySummary.notification.body.directionOnlySame")
            }
        case .percentage(let fraction, let direction):
            switch direction {
            case .same:
                return String(localized: "weeklySummary.notification.body.same")
            case .up:
                return String(format: String(localized: "weeklySummary.notification.body.up"), Int((abs(fraction) * 100).rounded()))
            case .down:
                return String(format: String(localized: "weeklySummary.notification.body.down"), Int((abs(fraction) * 100).rounded()))
            }
        }
    }
}
