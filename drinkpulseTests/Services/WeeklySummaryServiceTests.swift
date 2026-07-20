import Foundation
import SwiftData
import Testing
import UserNotifications
@testable import drinkpulse

private struct TestError: Error {}

/// Unit coverage for `WeeklySummaryService` (plan 01-02) — mirrors
/// `ReminderServiceTests`' shape exactly, reusing its `FakeNotificationCenter`
/// directly (declared with no access modifier in that file, so it's visible
/// here as an internal type of the `drinkpulseTests` target).
@MainActor
struct WeeklySummaryServiceTests {

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

    // MARK: - makeRequest

    @Test func makeRequest_returnsNil_forSkipContent() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .skip)
        #expect(request == nil)
    }

    @Test func makeRequest_buildsWeeklyRepeatingTrigger_atFireHourMinute_withInjectedFirstWeekday() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        let request = service.makeRequest(
            calendar: calendar,
            content: .percentage(fraction: 0.12, direction: .up)
        )

        let trigger = request?.trigger as? UNCalendarNotificationTrigger
        #expect(trigger?.dateComponents.weekday == 2)
        #expect(trigger?.dateComponents.hour == 9)
        #expect(trigger?.dateComponents.minute == 0)
        #expect(trigger?.repeats == true)
        #expect(request?.identifier == WeeklySummaryService.weeklySummaryIdentifier)
    }

    @Test func makeRequest_setsLocalizedTitle_forEveryContentBranch() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .percentage(fraction: 0.12, direction: .up))
        #expect(request?.content.title == String(localized: "weeklySummary.notification.title"))
    }

    @Test func makeRequest_bodyText_percentageUp_interpolatesRoundedWholePercent() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .percentage(fraction: 0.12, direction: .up))
        #expect(request?.content.body == String(format: String(localized: "weeklySummary.notification.body.up"), 12))
    }

    @Test func makeRequest_bodyText_percentageDown_interpolatesRoundedWholePercent() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .percentage(fraction: -0.34, direction: .down))
        #expect(request?.content.body == String(format: String(localized: "weeklySummary.notification.body.down"), 34))
    }

    @Test func makeRequest_bodyText_percentageSame_hasNoInterpolation() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .percentage(fraction: 0.02, direction: .same))
        #expect(request?.content.body == String(localized: "weeklySummary.notification.body.same"))
    }

    @Test func makeRequest_bodyText_directionOnlyUp() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .directionOnly(.up))
        #expect(request?.content.body == String(localized: "weeklySummary.notification.body.directionOnlyUp"))
    }

    @Test func makeRequest_bodyText_directionOnlySame() {
        let service = WeeklySummaryService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(content: .directionOnly(.same))
        #expect(request?.content.body == String(localized: "weeklySummary.notification.body.directionOnlySame"))
    }

    // MARK: - cancel

    @Test func cancel_removesPendingWeeklySummaryRequest() async throws {
        let fake = FakeNotificationCenter()
        let service = WeeklySummaryService(center: fake, defaults: makeDefaults())
        let request = service.makeRequest(content: .percentage(fraction: 0.12, direction: .up))!
        try await fake.add(request)

        await service.cancel()

        #expect(fake.pendingIds.isEmpty)
        #expect(fake.removedBatches.last == [WeeklySummaryService.weeklySummaryIdentifier])
    }

    // MARK: - requestAuthorization

    @Test func requestAuthorization_returnsGrantedResult_andPropagatesError() async throws {
        let fakeGranted = FakeNotificationCenter()
        fakeGranted.authorizationResult = true
        let grantedService = WeeklySummaryService(center: fakeGranted, defaults: makeDefaults())

        let granted = try await grantedService.requestAuthorization()

        #expect(granted == true)
        #expect(fakeGranted.authCallCount == 1)

        let fakeError = FakeNotificationCenter()
        fakeError.authorizationError = TestError()
        let errorService = WeeklySummaryService(center: fakeError, defaults: makeDefaults())

        await #expect(throws: TestError.self) {
            _ = try await errorService.requestAuthorization()
        }
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
        let priorRange = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)
        let currentRange = InsightsPeriod.week.dateRange(offset: 0, now: now, calendar: calendar)

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
        let beforePriorRange = InsightsPeriod.week.dateRange(offset: -2, now: now, calendar: calendar)
        let priorRange = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)
        let currentRange = InsightsPeriod.week.dateRange(offset: 0, now: now, calendar: calendar)

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
        let priorRange = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)
        let currentRange = InsightsPeriod.week.dateRange(offset: 0, now: now, calendar: calendar)
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
        let priorRange = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)
        let currentRange = InsightsPeriod.week.dateRange(offset: 0, now: now, calendar: calendar)
        context.insert(ConsumptionEvent(
            consumptionDate: priorRange.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        ))
        context.insert(ConsumptionEvent(
            consumptionDate: currentRange.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        ))

        await service.scheduleIfEnabled(context: context)

        #expect(fake.addedRequests.isEmpty)
    }
}
