import Foundation
import SwiftData
import Testing
import UserNotifications
@testable import drinkpulse

@MainActor
struct NotificationOptOutTests {

    private func makeDefaults(prefix: String) -> UserDefaults {
        UserDefaults(suiteName: "test.\(prefix).\(UUID().uuidString)")!
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// Seeds one event in the week before last and one in last week, so the weekly
    /// summary produces a percentage body instead of being skipped.
    private func seedWeeklyEvents(in context: ModelContext) {
        let calendar = Calendar.current
        let now = Date.now
        let priorRange = InsightsPeriod.week.dateRange(offset: -2, now: now, calendar: calendar)
        let currentRange = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)
        context.insert(ConsumptionEvent(
            consumptionDate: priorRange.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        ))
        context.insert(ConsumptionEvent(
            consumptionDate: currentRange.lowerBound, volumeMl: 500, abv: 0.05, quantity: 2, category: .beer, icon: "🍺"
        ))
    }

    /// Both requests pending on one shared fake center.
    private func makeSharedCenterWithBothPending() async throws
        -> (center: FakeNotificationCenter, reminder: ReminderService, weekly: WeeklySummaryService) {
        let center = FakeNotificationCenter()
        let reminder = ReminderService(center: center, defaults: makeDefaults(prefix: "optout.reminder"))
        let weekly = WeeklySummaryService(center: center, defaults: makeDefaults(prefix: "optout.weekly"))
        try await reminder.schedule(hour: 21, minute: 0)
        let weeklyRequest = try #require(weekly.makeRequest(content: .percentage(fraction: 0.1, direction: .up)))
        try await center.add(weeklyRequest)
        return (center, reminder, weekly)
    }

    // MARK: - Cross-identifier cancel isolation

    @Test func reminderCancel_leavesWeeklyPending_andRemovesOnlyReminderIdentifier() async throws {
        let (center, reminder, _) = try await makeSharedCenterWithBothPending()
        #expect(Set(center.pendingIds) == [ReminderService.reminderIdentifier, WeeklySummaryService.weeklySummaryIdentifier])

        await reminder.cancel()

        #expect(center.pendingIds == [WeeklySummaryService.weeklySummaryIdentifier])
        #expect(center.removedBatches.last == [ReminderService.reminderIdentifier])
    }

    @Test func weeklyCancel_leavesReminderPending_andRemovesOnlyWeeklyIdentifier() async throws {
        let (center, _, weekly) = try await makeSharedCenterWithBothPending()
        #expect(Set(center.pendingIds) == [ReminderService.reminderIdentifier, WeeklySummaryService.weeklySummaryIdentifier])

        await weekly.cancel()

        #expect(center.pendingIds == [ReminderService.reminderIdentifier])
        #expect(center.removedBatches.last == [WeeklySummaryService.weeklySummaryIdentifier])
    }

    // MARK: - No resurrection after opt-out

    @Test func reminder_afterOptOutAndCancel_scheduleIfEnabledAddsNothing() async throws {
        let center = FakeNotificationCenter()
        let defaults = makeDefaults(prefix: "optout.reminder")
        defaults.set(true, forKey: AppStorageKeys.reminderEnabled)
        let service = ReminderService(center: center, defaults: defaults)
        await service.scheduleIfEnabled()
        #expect(center.pendingIds == [ReminderService.reminderIdentifier])
        let addedBeforeOptOut = center.addedRequests.count

        defaults.set(false, forKey: AppStorageKeys.reminderEnabled)
        await service.cancel()
        await service.scheduleIfEnabled()

        #expect(center.addedRequests.count == addedBeforeOptOut)
        #expect(center.pendingIds.isEmpty)
    }

    @Test func weekly_afterOptOutAndCancel_scheduleIfEnabledAddsNothing() async throws {
        let center = FakeNotificationCenter()
        let defaults = makeDefaults(prefix: "optout.weekly")
        defaults.set(true, forKey: AppStorageKeys.weeklySummaryEnabled)
        let service = WeeklySummaryService(center: center, defaults: defaults)
        let container = try makeContainer()
        seedWeeklyEvents(in: container.mainContext)
        await service.scheduleIfEnabled(context: container.mainContext)
        #expect(center.pendingIds == [WeeklySummaryService.weeklySummaryIdentifier])
        let addedBeforeOptOut = center.addedRequests.count

        defaults.set(false, forKey: AppStorageKeys.weeklySummaryEnabled)
        await service.cancel()
        await service.scheduleIfEnabled(context: container.mainContext)

        #expect(center.addedRequests.count == addedBeforeOptOut)
        #expect(center.pendingIds.isEmpty)
    }
}
