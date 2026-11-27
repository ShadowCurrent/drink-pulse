import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// Area-chart limit rule caption (plan 0046 review): the rule sits at the effective daily limit,
/// which is a daily average (weekly / 7) when the guideline has no daily limit (UK).
@MainActor
extension InsightsViewModelTests {

    @Test func test_limitRuleCaption_isDailyLimit_whenGuidelineHasDailyLimit() {
        let vm = makeVM()
        #expect(vm.limitRuleCaption == "Daily limit")
    }

    @Test func test_limitRuleCaption_isDailyAverage_whenGuidelineHasNoDailyLimit() throws {
        let c = try makeContainer()
        // Only UK: a custom goal derives its daily limit as weekly / 7 (`effectiveLimits`).
        for choice in [GuidelineChoice.uk] {
            let profile = UserProfile(guidelineChoice: choice)
            c.mainContext.insert(profile)
            let vm = InsightsViewModel()
            vm.profile = profile
            #expect(vm.effectiveDailyLimitGrams > 0)
            #expect(vm.limitRuleCaption == "Daily average", "for \(choice)")
        }
    }
}
