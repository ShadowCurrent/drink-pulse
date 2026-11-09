import Foundation
import Testing
@testable import drinkpulse

private final class PostCounter: @unchecked Sendable {
    private(set) var count = 0
    func increment() { count += 1 }
}

@MainActor
@Suite(.serialized)
struct NotificationActionHandlerTests {

    private struct Outcome {
        let reminderPosts: Int
        let weeklyPosts: Int
        let addDrinkFlag: Bool?
        let openInsightsFlag: Bool?
    }

    private func routeAndObserve(identifier: String) async -> Outcome {
        let suiteName = "test.notificationActionHandler.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let reminder = PostCounter()
        let weekly = PostCounter()
        let reminderToken = NotificationCenter.default.addObserver(
            forName: NotificationActionHandler.didTapReminder, object: nil, queue: nil
        ) { _ in reminder.increment() }
        let weeklyToken = NotificationCenter.default.addObserver(
            forName: NotificationActionHandler.didTapWeeklySummary, object: nil, queue: nil
        ) { _ in weekly.increment() }
        defer {
            NotificationCenter.default.removeObserver(reminderToken)
            NotificationCenter.default.removeObserver(weeklyToken)
        }

        await NotificationActionHandler.route(identifier: identifier, defaults: defaults)

        return Outcome(
            reminderPosts: reminder.count,
            weeklyPosts: weekly.count,
            addDrinkFlag: defaults.object(forKey: AppStorageKeys.pendingAddDrink) as? Bool,
            openInsightsFlag: defaults.object(forKey: AppStorageKeys.pendingOpenInsights) as? Bool
        )
    }

    @Test func route_reminderIdentifier_setsAddDrinkFlagAndPostsReminderTapOnce() async {
        let outcome = await routeAndObserve(identifier: ReminderService.reminderIdentifier)

        #expect(outcome.addDrinkFlag == true)
        #expect(outcome.openInsightsFlag == nil)
        #expect(outcome.reminderPosts == 1)
        #expect(outcome.weeklyPosts == 0)
    }

    @Test func route_weeklySummaryIdentifier_setsOpenInsightsFlagAndPostsWeeklyTapOnce() async {
        let outcome = await routeAndObserve(identifier: WeeklySummaryService.weeklySummaryIdentifier)

        #expect(outcome.openInsightsFlag == true)
        #expect(outcome.addDrinkFlag == nil)
        #expect(outcome.weeklyPosts == 1)
        #expect(outcome.reminderPosts == 0)
    }

    @Test func route_unknownIdentifier_setsNoFlagAndPostsNothing() async {
        let outcome = await routeAndObserve(identifier: "dp.unknown.identifier")

        #expect(outcome.addDrinkFlag == nil)
        #expect(outcome.openInsightsFlag == nil)
        #expect(outcome.reminderPosts == 0)
        #expect(outcome.weeklyPosts == 0)
    }

    @Test func tapKind_reminderIdentifier_returnsDaily() {
        #expect(NotificationActionHandler.tapKind(forIdentifier: ReminderService.reminderIdentifier) == "daily")
    }

    @Test func tapKind_weeklyIdentifier_returnsWeekly() {
        #expect(NotificationActionHandler.tapKind(forIdentifier: WeeklySummaryService.weeklySummaryIdentifier) == "weekly")
    }

    @Test func tapKind_anyOtherIdentifier_returnsOther_andNeverEchoesTheInput() {
        let uuidShaped = UUID().uuidString
        for identifier in ["", "dp.unknown.identifier", uuidShaped] {
            #expect(NotificationActionHandler.tapKind(forIdentifier: identifier) == "other")
        }
        #expect(!NotificationActionHandler.tapKind(forIdentifier: uuidShaped).contains(uuidShaped))
    }

    @Test func identifierConstants_matchPersistedValues() {
        #expect(ReminderService.reminderIdentifier == "dp.daily.log.reminder")
        #expect(WeeklySummaryService.weeklySummaryIdentifier == "dp.weekly.summary")
    }
}
