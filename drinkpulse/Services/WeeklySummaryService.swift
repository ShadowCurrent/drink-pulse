import Foundation
import OSLog
import SwiftData
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

    /// Reads the `@AppStorage`-backed opt-in flag and, when enabled, recomputes
    /// the current/prior-week percentage change and (re)schedules the weekly
    /// summary notification. Safe to call at launch and on foreground; a no-op
    /// when disabled. Best-effort: scheduling failures are logged, never thrown
    /// (mirrors `ReminderService.scheduleIfEnabled()`'s shape exactly).
    func scheduleIfEnabled(context: ModelContext) async {
        guard defaults.bool(forKey: AppStorageKeys.weeklySummaryEnabled) else { return }

        let calendar = Calendar.current
        let now = Date.now
        let currentRange = InsightsPeriod.week.dateRange(offset: 0, now: now, calendar: calendar)
        let priorRange = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)

        // Physical density only (pureAlcoholGrams) — never a display-mode
        // density — so the reported percentage never shifts with the user's
        // display-unit setting.
        let currentGrams = fetchEvents(in: context, from: currentRange.lowerBound, to: currentRange.upperBound)
            .reduce(0) { $0 + $1.pureAlcoholGrams }
        let priorGrams = fetchEvents(in: context, from: priorRange.lowerBound, to: priorRange.upperBound)
            .reduce(0) { $0 + $1.pureAlcoholGrams }
        let hasAnyPriorWeekData = hasEvents(in: context, before: currentRange.lowerBound)

        let content = WeeklySummaryCalculator.content(
            currentWeekGrams: currentGrams,
            priorWeekGrams: priorGrams,
            hasAnyPriorWeekData: hasAnyPriorWeekData
        )

        guard let request = makeRequest(calendar: calendar, content: content) else {
            await cancel()
            return
        }

        do {
            center.removePendingRequests(withIdentifiers: [Self.weeklySummaryIdentifier])
            try await center.add(request)
        } catch {
            // Scheduling failure is non-fatal (the user simply gets no
            // notification); log the error category only, never the
            // computed percentage, gram totals, or fire date.
            logger.error("Failed to reschedule weekly summary: \(error.localizedDescription)")
        }
    }

    /// Fetches events whose `consumptionDate` falls within `[start, end]`
    /// (mirrors `HealthSection`'s `fetchEvents` idiom).
    private func fetchEvents(in context: ModelContext, from start: Date, to end: Date) -> [ConsumptionEvent] {
        let descriptor = FetchDescriptor<ConsumptionEvent>(
            predicate: #Predicate { $0.consumptionDate >= start && $0.consumptionDate <= end }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Whether any `ConsumptionEvent` exists strictly before `date` — distinct
    /// from "prior week grams == 0", which can mean a real sober week (ENGG-05)
    /// rather than no history yet (ENGG-06).
    private func hasEvents(in context: ModelContext, before date: Date) -> Bool {
        var descriptor = FetchDescriptor<ConsumptionEvent>(
            predicate: #Predicate { $0.consumptionDate < date }
        )
        descriptor.fetchLimit = 1
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
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
            case .same:
                return String(localized: "weeklySummary.notification.body.directionOnlySame")
            case .down:
                // `WeeklySummaryCalculator.content` never constructs
                // `.directionOnly(.down)` today (WR-03) — fail loudly in
                // debug builds if that invariant is ever broken, but still
                // degrade gracefully in release rather than crashing.
                assertionFailure("WeeklySummaryCalculator never produces .directionOnly(.down)")
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
