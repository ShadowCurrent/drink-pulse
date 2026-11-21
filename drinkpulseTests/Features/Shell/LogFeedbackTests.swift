import Foundation
import SwiftUI
import Testing
@testable import drinkpulse

/// WHO female, grams mode: daily limit 10 g; 250 ml at 4 % = 7.89 g (density 0.789).
@MainActor
@Suite struct LogFeedbackTests {

    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private var femaleWHOGrams: UserProfile {
        UserProfile(biologicalSex: .female, guidelineChoice: .who, alcoholUnit: .grams)
    }

    private func beer(ml: Double = 250, abv: Double = 0.04, hoursAgo: Double = 0) -> ConsumptionEvent {
        ConsumptionEvent(
            consumptionDate: now.addingTimeInterval(-hoursAgo * 3600),
            volumeMl: ml, abv: abv, category: .beer, icon: "🍺"
        )
    }

    private func feedback(
        today: [ConsumptionEvent], logged: ConsumptionEvent, profile: UserProfile?
    ) -> SensoryFeedback {
        LogFeedback.feedback(
            todayEvents: today, logged: logged, profile: profile, now: now, calendar: calendar
        )
    }

    @Test func test_feedback_isSuccess_whenTodayStaysWithinLimit() {
        let logged = beer()
        #expect(feedback(today: [logged], logged: logged, profile: femaleWHOGrams) == .success)
    }

    @Test func test_feedback_isWarning_whenLoggedDrinkCrossesDailyLimit() {
        let first = beer(hoursAgo: 1)
        let logged = beer()
        #expect(feedback(today: [first, logged], logged: logged, profile: femaleWHOGrams) == .warning)
    }

    @Test func test_feedback_isSuccess_whenTodayWasAlreadyOverLimit() {
        let earlier = [beer(hoursAgo: 2), beer(hoursAgo: 1)]
        let logged = beer()
        #expect(feedback(today: earlier + [logged], logged: logged, profile: femaleWHOGrams) == .success)
    }

    @Test func test_feedback_isSuccess_whenLoggedDrinkIsBeforeToday() {
        let todayDrink = beer(hoursAgo: 0)
        let yesterday = beer(ml: 1000, hoursAgo: 48)
        #expect(feedback(today: [todayDrink], logged: yesterday, profile: femaleWHOGrams) == .success)
    }

    /// No profile: view-model defaults (WHO, standard drinks at 0.8, daily 20 g).
    /// 500 ml at 5 % = 20.0 g, exactly the limit; a second one crosses it.
    @Test func test_feedback_isWarning_withoutProfile_usesViewModelDefaults() {
        let first = beer(ml: 500, abv: 0.05, hoursAgo: 1)
        #expect(feedback(today: [first], logged: first, profile: nil) == .success)
        let second = beer(ml: 500, abv: 0.05)
        #expect(feedback(today: [first, second], logged: second, profile: nil) == .warning)
    }

    /// WHO female, standard drinks (0.8): 250 ml at 5 % = 10.0 g, exactly the 10 g limit.
    @Test func test_feedback_exactlyAtLimit_isSuccess() {
        let profile = UserProfile(biologicalSex: .female, guidelineChoice: .who, alcoholUnit: .standardDrinks)
        let logged = beer(ml: 250, abv: 0.05)
        #expect(feedback(today: [logged], logged: logged, profile: profile) == .success)
    }
}
