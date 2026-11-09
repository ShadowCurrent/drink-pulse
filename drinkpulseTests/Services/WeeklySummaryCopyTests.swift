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

    private func downText(_ percent: Int) -> String {
        "As of your last visit, your latest completed week had \(percent)% less alcohol than the week before it."
    }

    private func upText(_ percent: Int) -> String {
        "As of your last visit, your latest completed week had \(percent)% more alcohol than the week before it."
    }

    private let sameText =
        "As of your last visit, your latest completed week had about the same alcohol as the week before it."
    private let directionOnlyUpText =
        "As of your last visit, you logged alcohol in your latest completed week but none the week before it."
    private let directionOnlySameText =
        "As of your last visit, you logged no alcohol in your latest completed week or the week before it."

    // MARK: - down

    @Test func down_body_equalsApprovedWording_with50Percent() {
        #expect(body(for: .percentage(fraction: -0.5, direction: .down)) == downText(50))
    }

    @Test(arguments: [1, 5, 50, 100])
    func down_body_formatsWholePercentWithoutStraySpecifier(percent: Int) {
        let text = body(for: .percentage(fraction: -Double(percent) / 100, direction: .down))
        #expect(text == downText(percent))
        #expect(text?.contains("%d") == false)
        #expect(text?.contains("%%") == false)
    }

    // MARK: - remaining variants

    @Test func up_body_equalsApprovedWording_with50Percent() {
        #expect(body(for: .percentage(fraction: 0.5, direction: .up)) == upText(50))
    }

    @Test(arguments: [1, 5, 50, 100])
    func up_body_formatsWholePercentWithoutStraySpecifier(percent: Int) {
        let text = body(for: .percentage(fraction: Double(percent) / 100, direction: .up))
        #expect(text == upText(percent))
        #expect(text?.contains("%d") == false)
        #expect(text?.contains("%%") == false)
    }

    @Test func same_body_equalsApprovedWording() {
        #expect(body(for: .percentage(fraction: 0.02, direction: .same)) == sameText)
    }

    @Test func directionOnlyUp_body_equalsApprovedWording() {
        #expect(body(for: .directionOnly(.up)) == directionOnlyUpText)
    }

    @Test func directionOnlySame_body_equalsApprovedWording() {
        #expect(body(for: .directionOnly(.same)) == directionOnlySameText)
    }

    // MARK: - rounding boundaries

    @Test func down_body_roundsFractionBelowFivePercentBand_toFive() {
        #expect(body(for: .percentage(fraction: -0.051, direction: .down)) == downText(5))
    }

    @Test func up_body_roundsHalfPercentUp_toOneHundred() {
        #expect(body(for: .percentage(fraction: 0.995, direction: .up)) == upText(100))
    }

    // MARK: - cross-variant invariants

    @Test func allBodies_areDistinct_andNameBothComparedPeriods() {
        let bodies = [
            body(for: .percentage(fraction: -0.5, direction: .down)),
            body(for: .percentage(fraction: 0.5, direction: .up)),
            body(for: .percentage(fraction: 0.02, direction: .same)),
            body(for: .directionOnly(.up)),
            body(for: .directionOnly(.same))
        ].compactMap { $0 }

        #expect(bodies.count == 5)
        #expect(Set(bodies).count == 5)
        for text in bodies {
            #expect(!text.isEmpty)
            #expect(text.components(separatedBy: "week").count - 1 >= 2)
            #expect(!text.contains("%d") && !text.contains("%%") && !text.contains("%@"))
        }
    }
}
