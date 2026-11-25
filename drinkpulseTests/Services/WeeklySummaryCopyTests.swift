import Foundation
import Testing
import UserNotifications
@testable import drinkpulse

/// Wording guard for the weekly-summary notification body (plan 0049 D0049-2; earlier wording D-16).
/// Unlike WeeklySummaryServiceTests, these assertions use the literal approved string, not String(localized:) of
/// the key, so a wording regression in the catalog fails here.
@MainActor
struct WeeklySummaryCopyTests {

    private func makeService() -> WeeklySummaryService {
        let defaults = UserDefaults(suiteName: "test.weeklySummaryCopy.\(UUID().uuidString)")!
        return WeeklySummaryService(center: FakeNotificationCenter(), defaults: defaults)
    }

    private func body(for content: WeeklySummaryContent) -> String? {
        makeService().makeRequest(content: content)?.content.body
    }

    private let neutral = "Your weekly summary is ready."

    // Plan 0049 D0049-2 (VOICE.md owner decision): one neutral body for every scheduled case, so no
    // health number reaches the lock screen.
    @Test(arguments: [WeeklySummaryContent.percentage(fraction: -0.5, direction: .down),
                      .percentage(fraction: 0.5, direction: .up),
                      .percentage(fraction: 0.02, direction: .same),
                      .directionOnly(.up),
                      .directionOnly(.same)])
    func everyScheduledBody_isNeutral_withNoNumbers(content: WeeklySummaryContent) {
        let text = body(for: content)
        #expect(text == neutral)
        #expect(text?.contains(where: \.isNumber) == false)
        #expect(text?.contains("%") == false)
    }

    @Test func skip_hasNoRequest() {
        #expect(makeService().makeRequest(content: .skip) == nil)
    }
}
