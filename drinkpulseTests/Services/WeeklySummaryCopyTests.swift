import Foundation
import Testing
import UserNotifications
@testable import drinkpulse

/// Wording guard for the weekly-summary notification bodies (D-16, owner record in 10-DECISION-F4.md).
/// Unlike WeeklySummaryServiceTests, these assertions use literal approved strings, not String(localized:) of the
/// same key, so a wording regression in the catalog fails here.
@MainActor
struct WeeklySummaryCopyTests {

    private func makeService() -> WeeklySummaryService {
        let defaults = UserDefaults(suiteName: "test.weeklySummaryCopy.\(UUID().uuidString)")!
        return WeeklySummaryService(center: FakeNotificationCenter(), defaults: defaults)
    }

    private func body(for content: WeeklySummaryContent) -> String? {
        makeService().makeRequest(content: content)?.content.body
    }

    // MARK: - down

    @Test func down_body_equalsApprovedWording_with50Percent() {
        #expect(
            body(for: .percentage(fraction: -0.5, direction: .down))
                == "As of your last visit, your latest completed week had 50% less alcohol than the week before it."
        )
    }

    @Test(arguments: [1, 50, 100])
    func down_body_formatsWholePercentWithoutStraySpecifier(percent: Int) {
        let text = body(for: .percentage(fraction: -Double(percent) / 100, direction: .down))
        #expect(
            text == "As of your last visit, your latest completed week had \(percent)% less alcohol than the week before it."
        )
        #expect(text?.contains("%d") == false)
        #expect(text?.contains("%%") == false)
    }
}
