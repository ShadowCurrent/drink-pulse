import Foundation
import OSLog
import SwiftData
import UserNotifications

@MainActor
final class WeeklySummaryService {
    static let weeklySummaryIdentifier = "dp.weekly.summary"

    static let fireHour = 9
    static let fireMinute = 0

    private let centerProvider: () -> NotificationScheduling
    private lazy var center: NotificationScheduling = centerProvider()
    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "WeeklySummaryService")

    // F3 (10-DECISION-F3.md): lifecycleEpoch advances on every schedule and cancel;
    // cancelEpoch holds the lifecycleEpoch value at the latest cancel. Both mutate
    // synchronously on the main actor, so the post-add comparison cannot race.
    private var lifecycleEpoch = 0
    private var cancelEpoch = 0

    init(
        center: @autoclosure @escaping () -> NotificationScheduling = WeeklySummaryService.defaultCenter(),
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

    func cancel() async {
        lifecycleEpoch += 1
        cancelEpoch = lifecycleEpoch
        center.removePendingRequests(withIdentifiers: [Self.weeklySummaryIdentifier])
    }

    func scheduleIfEnabled(context: ModelContext, now: Date = .now, calendar: Calendar = .current) async {
        guard defaults.bool(forKey: AppStorageKeys.weeklySummaryEnabled) else { return }

        // Half-open week intervals [start, nextStart): InsightsPeriod.dateRange ends a week at
        // 23:59:59, which would leave a sub-second gap between consecutive weeks.
        let thisWeekStart = InsightsPeriod.week.dateRange(offset: 0, now: now, calendar: calendar).lowerBound
        let lastWeekStart = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar).lowerBound
        let weekBeforeLastStart = InsightsPeriod.week.dateRange(offset: -2, now: now, calendar: calendar).lowerBound

        let lastWeekGrams = fetchEvents(in: context, from: lastWeekStart, before: thisWeekStart)
            .reduce(0) { $0 + $1.pureAlcoholGrams }
        let weekBeforeLastGrams = fetchEvents(in: context, from: weekBeforeLastStart, before: lastWeekStart)
            .reduce(0) { $0 + $1.pureAlcoholGrams }
        let hasAnyPriorWeekData = hasEvents(in: context, before: lastWeekStart)

        let content = WeeklySummaryCalculator.content(
            currentWeekGrams: lastWeekGrams,
            priorWeekGrams: weekBeforeLastGrams,
            hasAnyPriorWeekData: hasAnyPriorWeekData
        )

        guard let request = makeRequest(calendar: calendar, content: content) else {
            await cancel()
            return
        }

        lifecycleEpoch += 1
        let myEpoch = lifecycleEpoch
        do {
            center.removePendingRequests(withIdentifiers: [Self.weeklySummaryIdentifier])
            try await center.add(request)
            // Actor reentrancy lets cancel() run while suspended in add. Remove our own request
            // only when the latest lifecycle event is a cancel issued after this call began; a
            // later schedule owns the identifier and applies its own check.
            if cancelEpoch == lifecycleEpoch, cancelEpoch > myEpoch {
                center.removePendingRequests(withIdentifiers: [Self.weeklySummaryIdentifier])
            }
        } catch {
            logger.error("Failed to reschedule weekly summary: \(error.localizedDescription)")
        }
    }

    private func fetchEvents(in context: ModelContext, from start: Date, before end: Date) -> [ConsumptionEvent] {
        let descriptor = FetchDescriptor<ConsumptionEvent>(
            predicate: #Predicate { $0.consumptionDate >= start && $0.consumptionDate < end }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func hasEvents(in context: ModelContext, before date: Date) -> Bool {
        var descriptor = FetchDescriptor<ConsumptionEvent>(
            predicate: #Predicate { $0.consumptionDate < date }
        )
        descriptor.fetchLimit = 1
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    private static func bodyText(for content: WeeklySummaryContent) -> String {
        switch content {
        case .skip:
            return ""
        case .directionOnly(let direction):
            switch direction {
            case .up:
                return String(localized: "weeklySummary.notification.body.directionOnlyUp")
            case .same:
                return String(localized: "weeklySummary.notification.body.directionOnlySame")
            case .down:
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
