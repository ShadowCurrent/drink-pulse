import XCTest

/// Insights at the largest accessibility text size (AX5): no clipped text, no fixed-size text, and
/// the period controls stay reachable. Brief C016, decision D11-24.
///
/// Chart axis label overlap is not detectable by `performAccessibilityAudit`; the owner
/// re-observation of CHK-07 covers the weekday labels and the area chart.
@MainActor
final class InsightsDynamicTypeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func launchInsightsAtAX5() {
        app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(
            onboarding: false, contentSizeCategory: AuditLaunch.ax5Category
        )
        app.launch()
        let tab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(tab.waitForExistence(timeout: 15), "Insights tab should exist")
        tab.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 10),
                      "Insights screen should be shown")
    }

    func test_insights_atAX5_hasNoClippedOrFixedSizeText() throws {
        launchInsightsAtAX5()
        try assertNoAuditIssuesWhileScrolling(
            in: app,
            types: [.textClipped, .dynamicType],
            screen: "Insights",
            variant: "ax5",
            maxPages: 5
        )
    }

    func test_insights_atAX5_keepsControlsReachable() throws {
        launchInsightsAtAX5()
        let window = app.windows.firstMatch

        let labels = ["Period", "Previous period", "Next period"]
        for label in labels {
            let control = app.descendants(matching: .any).matching(
                NSPredicate(format: "label BEGINSWITH %@", label)
            ).firstMatch
            XCTAssertTrue(control.waitForExistence(timeout: 10),
                          "The '\(label)' control should exist on Insights at AX5")
            XCTAssertTrue(control.isHittable,
                          "The '\(label)' control must be hittable at AX5")
            XCTAssertLessThanOrEqual(
                control.frame.maxX, window.frame.maxX,
                "The '\(label)' control must not overflow the window horizontally "
                + "(maxX \(control.frame.maxX), window maxX \(window.frame.maxX))"
            )
        }
    }
}
