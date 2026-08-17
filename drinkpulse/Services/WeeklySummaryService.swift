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
        center.removePendingRequests(withIdentifiers: [Self.weeklySummaryIdentifier])
    }

    func scheduleIfEnabled(context: ModelContext) async {
        guard defaults.bool(forKey: AppStorageKeys.weeklySummaryEnabled) else { return }

        let calendar = Calendar.current
        let now = Date.now
        let lastWeekRange = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)
        let weekBeforeLastRange = InsightsPeriod.week.dateRange(offset: -2, now: now, calendar: calendar)

        let lastWeekGrams = fetchEvents(in: context, from: lastWeekRange.lowerBound, to: lastWeekRange.upperBound)
            .reduce(0) { $0 + $1.pureAlcoholGrams }
        let weekBeforeLastGrams = fetchEvents(in: context, from: weekBeforeLastRange.lowerBound, to: weekBeforeLastRange.upperBound)
            .reduce(0) { $0 + $1.pureAlcoholGrams }
        let hasAnyPriorWeekData = hasEvents(in: context, before: lastWeekRange.lowerBound)

        let content = WeeklySummaryCalculator.content(
            currentWeekGrams: lastWeekGrams,
            priorWeekGrams: weekBeforeLastGrams,
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
            logger.error("Failed to reschedule weekly summary: \(error.localizedDescription)")
        }
    }

    private func fetchEvents(in context: ModelContext, from start: Date, to end: Date) -> [ConsumptionEvent] {
        let descriptor = FetchDescriptor<ConsumptionEvent>(
            predicate: #Predicate { $0.consumptionDate >= start && $0.consumptionDate <= end }
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
