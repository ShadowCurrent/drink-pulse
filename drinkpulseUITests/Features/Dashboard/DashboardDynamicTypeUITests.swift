import XCTest

/// Home at the largest accessibility text size (AX5): no clipped text, no fixed-size text, and the
/// primary elements stay reachable. Brief C016, decision D11-24.
@MainActor
final class DashboardDynamicTypeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func launchHomeAtAX5() {
        app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(
            onboarding: false, contentSizeCategory: AuditLaunch.ax5Category
        )
        app.launch()
        XCTAssertTrue(app.navigationBars[UITestTabs.today].waitForExistence(timeout: 15),
                      "Home should be shown after launch")
    }

    private func element(beginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch
    }

    /// Scrolls the Home content up until the element is hittable, at most six swipes.
    private func scrollIntoView(_ element: XCUIElement) {
        var swipes = 0
        while !element.isHittable && swipes < 6 {
            app.swipeUp()
            swipes += 1
        }
    }

    func test_home_atAX5_hasNoClippedOrFixedSizeText() throws {
        launchHomeAtAX5()
        try assertNoAuditIssuesWhileScrolling(
            in: app,
            types: [.textClipped, .dynamicType],
            screen: UITestTabs.today,
            variant: "ax5",
            maxPages: 5
        )
    }

    func test_home_atAX5_keepsPrimaryElementsReachable() throws {
        launchHomeAtAX5()
        let window = app.windows.firstMatch

        // Tile labels of the native Today screen (plan 0046, D0046-4 / D0046-15).
        let prefixes = ["Calories", "Drinks", "Alcohol-Free Streak", "Alcohol-Free This Month"]
        for prefix in prefixes {
            let target = element(beginningWith: prefix)
            XCTAssertTrue(target.waitForExistence(timeout: 10),
                          "The element labelled '\(prefix)...' should exist on Home at AX5")
            scrollIntoView(target)
            XCTAssertTrue(target.isHittable,
                          "The element labelled '\(prefix)...' must be hittable at AX5")
            XCTAssertLessThanOrEqual(
                target.frame.maxX, window.frame.maxX,
                "The element labelled '\(prefix)...' must not overflow the window horizontally "
                + "(maxX \(target.frame.maxX), window maxX \(window.frame.maxX))"
            )
        }
    }
}
