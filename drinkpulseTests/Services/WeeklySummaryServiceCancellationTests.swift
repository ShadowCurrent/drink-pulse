import Foundation
import SwiftData
import Testing
import UserNotifications
@testable import drinkpulse

@MainActor
struct WeeklySummaryServiceCancellationTests {

    private let identifier = WeeklySummaryService.weeklySummaryIdentifier

    private func makeDefaults(optedIn: Bool) -> UserDefaults {
        let defaults = UserDefaults(suiteName: "test.weeklyCancellation.\(UUID().uuidString)")!
        defaults.set(optedIn, forKey: AppStorageKeys.weeklySummaryEnabled)
        return defaults
    }

    /// One event last week and two the week before, so the content is a percentage, not skip.
    private func makeSeededContext() throws -> (ModelContainer, ModelContext) {
        let container = try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let calendar = Calendar.current
        let now = Date.now
        let lastWeek = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: calendar)
        let weekBeforeLast = InsightsPeriod.week.dateRange(offset: -2, now: now, calendar: calendar)
        context.insert(ConsumptionEvent(
            consumptionDate: lastWeek.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        ))
        context.insert(ConsumptionEvent(
            consumptionDate: weekBeforeLast.lowerBound, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        ))
        context.insert(ConsumptionEvent(
            consumptionDate: weekBeforeLast.lowerBound.addingTimeInterval(3600),
            volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        ))
        return (container, context)
    }

    // MARK: - F3 pin (research assumption A4)

    @Test func optOut_whileSceneActiveRescheduleSuspendedInAdd_leavesNoPendingRequest() async throws {
        let center = SlowNotificationCenter()
        let defaults = makeDefaults(optedIn: true)
        let service = WeeklySummaryService(center: center, defaults: defaults)
        let (container, context) = try makeSeededContext()
        defer { withExtendedLifetime(container) {} }
        defer { center.release() }

        let rescheduling = Task { await service.scheduleIfEnabled(context: context) }
        try #require(await center.waitUntilAddEntered(), "scheduleIfEnabled never reached add within the deadline")

        defaults.set(false, forKey: AppStorageKeys.weeklySummaryEnabled)
        await service.cancel()
        center.release()
        await rescheduling.value

        let pending = await center.pendingRequestIdentifiers()
        // Finding F3 / assumption A4 (10-DECISION-F3.md): the scene-active reschedule has no
        // re-check after add, so its request lands after the opt-out cancel. The Settings
        // enable path is separately guarded by WeeklySummarySection's toggleGeneration.
        withKnownIssue("F3/A4: an opt-out cancel does not stop a reschedule already suspended in add") {
            #expect(pending.isEmpty)
        }
    }

    // MARK: - Controls

    @Test func cancel_afterScheduleCompleted_leavesNoPendingRequest() async throws {
        let center = SlowNotificationCenter()
        center.release()
        let service = WeeklySummaryService(center: center, defaults: makeDefaults(optedIn: true))
        let (container, context) = try makeSeededContext()
        defer { withExtendedLifetime(container) {} }

        await service.scheduleIfEnabled(context: context)
        let pendingAfterSchedule = await center.pendingRequestIdentifiers()
        #expect(pendingAfterSchedule == [identifier])

        await service.cancel()

        let pending = await center.pendingRequestIdentifiers()
        #expect(pending.isEmpty)
        let removals = center.operationLog.compactMap { operation -> [String]? in
            if case .remove(let ids) = operation { return ids }
            return nil
        }
        #expect(!removals.isEmpty)
        #expect(removals.allSatisfy { $0 == [identifier] })
    }

    @Test func scheduleIfEnabled_whenOptedOut_addsNothingAndNeverEntersAdd() async throws {
        let center = SlowNotificationCenter()
        let service = WeeklySummaryService(center: center, defaults: makeDefaults(optedIn: false))
        let (container, context) = try makeSeededContext()
        defer { withExtendedLifetime(container) {} }

        await service.scheduleIfEnabled(context: context)

        #expect(center.addEntered == false)
        #expect(center.operationLog.isEmpty)
        let pending = await center.pendingRequestIdentifiers()
        #expect(pending.isEmpty)
    }
}
