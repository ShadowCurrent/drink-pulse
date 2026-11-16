import XCTest

/// Add Drink steps 1 (drink-type tiles) and 2 (volume, strength, amount, price) at the largest
/// accessibility text size (AX5): no clipped text, no fixed-size text, primary controls reachable.
/// Brief C016, decision D11-24.
@MainActor
final class AddDrinkDynamicTypeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// Owner decision D11-28 (2026-11-16), plan 11-16: a narrow exception, NOT a mute. At AX5 the
    /// system-owned controls of the step 2 `Form` (the Volume, Strength and Amount picker rows and
    /// UIKit-hosted internals that report no element) are flagged `dynamicType` / `textClipped` even
    /// when they use only default text styles, while the same text outside a `Form` passes. The app
    /// cannot remove these controls. Exactly these element keys are tolerated, for these two audit
    /// types only; every other finding on this screen, and every finding on every other screen,
    /// still fails. Contrast, hit-region and description findings are never exempt (plans 11-17 to
    /// 11-21). The text size of this screen is judged by the owner's CHK-07 re-check.
    private static let step2SystemFormControlKeys: Set<String> = [
        "Volume", "Strength", "Amount", "none#type=nil",
    ]

    private func launchAndOpenAddDrinkAtAX5() {
        app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(
            onboarding: false, contentSizeCategory: AuditLaunch.ax5Category
        )
        app.launch()
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 15), "Home tab should exist")
        homeTab.tap()
        let add = app.buttons["Add Drink"]
        XCTAssertTrue(add.waitForExistence(timeout: 10), "Add Drink button should exist on Home")
        add.tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 10),
                      "Add Drink sheet should be shown")
    }

    private func assertInsideWindow(_ element: XCUIElement, _ name: String) {
        let window = app.windows.firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 10), "\(name) should exist at AX5")
        XCTAssertTrue(element.isHittable, "\(name) must be hittable at AX5")
        XCTAssertLessThanOrEqual(
            element.frame.maxX, window.frame.maxX,
            "\(name) must not overflow the window horizontally "
            + "(maxX \(element.frame.maxX), window maxX \(window.frame.maxX))"
        )
    }

    func test_addDrinkStep1_atAX5_hasNoClippedOrFixedSizeText() throws {
        launchAndOpenAddDrinkAtAX5()
        try assertNoAuditIssuesWhileScrolling(
            in: app,
            types: [.textClipped, .dynamicType],
            screen: "Add Drink step 1",
            variant: "ax5",
            maxPages: 6
        )
        assertInsideWindow(app.buttons["Cancel"], "Cancel button")
        assertInsideWindow(app.buttons["Beer"], "Beer tile")
    }

    func test_addDrinkStep2_atAX5_hasNoClippedOrFixedSizeText() throws {
        launchAndOpenAddDrinkAtAX5()
        let wine = app.buttons["Wine"]
        XCTAssertTrue(wine.waitForExistence(timeout: 10), "Wine tile should exist")
        wine.tap()
        XCTAssertTrue(app.navigationBars["Wine"].waitForExistence(timeout: 10),
                      "Wine detail step should be shown")
        try assertNoAuditIssuesWhileScrolling(
            in: app,
            types: [.textClipped, .dynamicType],
            screen: "Add Drink step 2",
            variant: "ax5",
            maxPages: 6,
            exemptElementKeys: Self.step2SystemFormControlKeys
        )
        assertInsideWindow(app.buttons["Save"], "Save button")
        assertInsideWindow(app.buttons["Cancel"], "Cancel button")
    }
}
