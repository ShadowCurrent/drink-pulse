import Foundation
import SwiftData
import Testing
import UserNotifications
@testable import drinkpulse

private struct TestError: Error {}

/// `scheduleIfEnabled(context:)` coverage for `WeeklySummaryService` — split
/// out of `WeeklySummaryServiceTests.swift` to keep both files under the
/// 300-line ceiling (CLAUDE.md). Mirrors that file's helper shape.
@MainActor
struct WeeklySummaryServiceScheduleTests {

    private func makeDefaults() -> UserDefaults {
        // Isolated suite so tests never read/write the real app domain.
        let defaults = UserDefaults(suiteName: "test.weeklySummary.\(UUID().uuidString)")!
        return defaults
    }

    /// Retained in-memory container. The caller must keep this alive for the
    /// test (mirrors HealthWriteHooksTests.makeContainer()'s dangling-context
    /// warning).
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // MARK: - scheduleIfEnabled

    @Test func scheduleIfEnabled_doesNothing_whenDisabled() async throws {
        let fake = FakeNotificationCenter()
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppStorageKeys.weeklySummaryEnabled)
        let service = WeeklySummaryService(center: fake, defaults: defaults)
        let container = try makeContainer()

        await service.scheduleIfEnabled(context: container.mainContext)

        #expect(fake.addedRequests.isEmpty)
        #expect(fake.removedBatches.isEmpty)
    }

    @Test func scheduleIfEnabled_cancelsPending_whenNoPriorWeekDataAtAll() async throws {
        let fake = FakeNotificationCenter()
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppStorageKeys.weeklySummaryEnabled)
        let service = WeeklySummaryService(center: fake, defaults: defaults)
        let seedRequest = service.makeRequest(content: .percentage(fraction: 0.1, direction: .up))!
        try await fake.add(seedRequest)
        let container = try makeContainer()

        await service.scheduleIfEnabled(context: container.mainContext)

        #expect(fake.pendingIds.isEmpty)
    }

    @Test func scheduleIfEnabled_schedulesPercentageContent_usingPhysicalDensity_notModeDensity() async throws {
        let fake = FakeNotificationCenter()
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppStorageKeys.weeklySummaryEnabled)
        let service = WeeklySummaryService(center: fake, defaults: defaults)
        let container = try makeContainer()
        let context = container.mainContext

        let calendar = Calendar.current
        let now = Date.now
        let priorRange = InsightsPeriod.week.dateRange(offset: -2, now: now, calendar: calendar)
        let currentRange = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)

        let priorEvent = ConsumptionEvent(
            consumptionDate: priorRange.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        )
        let currentEvent = ConsumptionEvent(
            consumptionDate: currentRange.lowerBound, volumeMl: 500, abv: 0.05, quantity: 2, category: .beer, icon: "🍺"
        )
        context.insert(priorEvent)
        context.insert(currentEvent)

        // Expected value derived from the physical (0.789) density via
        // pureAlcoholGrams — never a display-mode density like 0.8 (UK units).
        let expectedContent = WeeklySummaryCalculator.content(
            currentWeekGrams: currentEvent.pureAlcoholGrams,
            priorWeekGrams: priorEvent.pureAlcoholGrams,
            hasAnyPriorWeekData: true
        )
        let expectedRequest = service.makeRequest(calendar: calendar, content: expectedContent)!

        await service.scheduleIfEnabled(context: context)

        #expect(fake.addedRequests.count == 1)
        #expect(fake.addedRequests.first?.content.body == expectedRequest.content.body)
    }

    @Test func scheduleIfEnabled_directionOnly_whenPriorWeekHasOnlyZeroAbvEvent() async throws {
        let fake = FakeNotificationCenter()
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppStorageKeys.weeklySummaryEnabled)
        let service = WeeklySummaryService(center: fake, defaults: defaults)
        let container = try makeContainer()
        let context = container.mainContext

        let calendar = Calendar.current
        let now = Date.now
        let beforePriorRange = InsightsPeriod.week.dateRange(offset: -3, now: now, calendar: calendar)
        let priorRange = InsightsPeriod.week.dateRange(offset: -2, now: now, calendar: calendar)
        let currentRange = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)

        // Older event before the prior week guarantees hasAnyPriorWeekData,
        // independent of the (zero-abv) prior-week event below.
        context.insert(ConsumptionEvent(
            consumptionDate: beforePriorRange.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        ))
        // Alcohol-free drink: pureAlcoholGrams == 0.0, but it IS real prior-week data.
        context.insert(ConsumptionEvent(
            consumptionDate: priorRange.lowerBound, volumeMl: 330, abv: 0.0, category: .beer, icon: "🍺"
        ))
        context.insert(ConsumptionEvent(
            consumptionDate: currentRange.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        ))

        await service.scheduleIfEnabled(context: context)

        let expectedBody = String(localized: "weeklySummary.notification.body.directionOnlyUp")
        #expect(fake.addedRequests.first?.content.body == expectedBody)
    }

    @Test func scheduleIfEnabled_isIdempotent_leavesOnePendingRequest() async throws {
        let fake = FakeNotificationCenter()
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppStorageKeys.weeklySummaryEnabled)
        let service = WeeklySummaryService(center: fake, defaults: defaults)
        let container = try makeContainer()
        let context = container.mainContext

        let calendar = Calendar.current
        let now = Date.now
        let priorRange = InsightsPeriod.week.dateRange(offset: -2, now: now, calendar: calendar)
        let currentRange = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)
        context.insert(ConsumptionEvent(
            consumptionDate: priorRange.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        ))
        context.insert(ConsumptionEvent(
            consumptionDate: currentRange.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        ))

        await service.scheduleIfEnabled(context: context)
        await service.scheduleIfEnabled(context: context)

        #expect(fake.addedRequests.count == 2)
        #expect(fake.pendingIds == [WeeklySummaryService.weeklySummaryIdentifier])
        #expect(fake.removedBatches.count == 2)
    }

    @Test func scheduleIfEnabled_swallowsSchedulingError_withoutThrowing() async throws {
        let fake = FakeNotificationCenter()
        fake.addError = TestError()
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppStorageKeys.weeklySummaryEnabled)
        let service = WeeklySummaryService(center: fake, defaults: defaults)
        let container = try makeContainer()
        let context = container.mainContext

        let calendar = Calendar.current
        let now = Date.now
        let priorRange = InsightsPeriod.week.dateRange(offset: -2, now: now, calendar: calendar)
        let currentRange = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)
        context.insert(ConsumptionEvent(
            consumptionDate: priorRange.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        ))
        context.insert(ConsumptionEvent(
            consumptionDate: currentRange.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        ))

        await service.scheduleIfEnabled(context: context)

        #expect(fake.addedRequests.isEmpty)
    }

    @Test func scheduleIfEnabled_comparesLastWeekVsWeekBefore_ignoringInProgressCurrentWeek() async throws {
        let fake = FakeNotificationCenter()
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppStorageKeys.weeklySummaryEnabled)
        let service = WeeklySummaryService(center: fake, defaults: defaults)
        let container = try makeContainer()
        let context = container.mainContext

        let calendar = Calendar.current
        let now = Date.now
        let weekBeforeLastRange = InsightsPeriod.week.dateRange(offset: -2, now: now, calendar: calendar)
        let lastWeekRange = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)
        let inProgressRange = InsightsPeriod.week.dateRange(offset: 0, now: now, calendar: calendar)

        let weekBeforeLastEvent = ConsumptionEvent(
            consumptionDate: weekBeforeLastRange.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        )
        let lastWeekEvent = ConsumptionEvent(
            consumptionDate: lastWeekRange.lowerBound, volumeMl: 500, abv: 0.05, quantity: 2, category: .beer, icon: "🍺"
        )
        // Deliberately huge outlier in the still-in-progress current week — must NOT
        // influence the result. If production code still reads offset 0 for
        // "currentWeekGrams", this event dominates the comparison and the test fails.
        let inProgressEvent = ConsumptionEvent(
            consumptionDate: inProgressRange.lowerBound, volumeMl: 500, abv: 0.05, quantity: 50, category: .beer, icon: "🍺"
        )
        context.insert(weekBeforeLastEvent)
        context.insert(lastWeekEvent)
        context.insert(inProgressEvent)

        let expectedContent = WeeklySummaryCalculator.content(
            currentWeekGrams: lastWeekEvent.pureAlcoholGrams,
            priorWeekGrams: weekBeforeLastEvent.pureAlcoholGrams,
            hasAnyPriorWeekData: true
        )
        let expectedRequest = service.makeRequest(calendar: calendar, content: expectedContent)!

        await service.scheduleIfEnabled(context: context)

        #expect(fake.addedRequests.first?.content.body == expectedRequest.content.body)
    }
}
