import XCTest

/// The four Onboarding steps at the largest accessibility text size (AX5): no clipped text, no
/// fixed-size text, and each step's primary button reachable. Brief C016, decision D11-24.
@MainActor
final class OnboardingDynamicTypeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func launchOnboardingAtAX5() {
        app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(
            onboarding: true, contentSizeCategory: AuditLaunch.ax5Category
        )
        app.launch()
    }

    /// Asserts the step's primary button is hittable (scrolling if needed) and inside the window.
    private func assertPrimaryButtonReachable(_ label: String, step: String) {
        let button = app.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "\(step): '\(label)' button should exist")
        var swipes = 0
        while !button.isHittable && swipes < 5 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(button.isHittable, "\(step): '\(label)' button must be hittable at AX5")
        XCTAssertLessThanOrEqual(
            button.frame.maxX, app.windows.firstMatch.frame.maxX,
            "\(step): '\(label)' button must not overflow the window horizontally"
        )
    }

    private func tap(_ label: String, step: String) {
        assertPrimaryButtonReachable(label, step: step)
        app.buttons[label].tap()
    }

    private func audit(_ screen: String) throws {
        try assertNoAuditIssuesWhileScrolling(
            in: app,
            types: [.textClipped, .dynamicType],
            screen: screen,
            variant: "ax5",
            maxPages: 4
        )
    }

    func test_onboardingWelcome_atAX5_hasNoClippedOrFixedSizeText() throws {
        launchOnboardingAtAX5()
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 15))
        try audit("Onboarding welcome")
        assertPrimaryButtonReachable("Get Started", step: "Welcome")
    }

    func test_onboardingProfile_atAX5_hasNoClippedOrFixedSizeText() throws {
        launchOnboardingAtAX5()
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 15))
        tap("Get Started", step: "Welcome")
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 10))
        try audit("Onboarding profile")
        assertPrimaryButtonReachable("Continue", step: "Profile")
    }

    func test_onboardingGuideline_atAX5_hasNoClippedOrFixedSizeText() throws {
        launchOnboardingAtAX5()
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 15))
        tap("Get Started", step: "Welcome")
        OnboardingWalk.chooseSex("Female", in: app)
        tap("Continue", step: "Profile")
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 10))
        try audit("Onboarding guideline")
        assertPrimaryButtonReachable("Continue", step: "Guideline")
    }

    func test_onboardingHealth_atAX5_hasNoClippedOrFixedSizeText() throws {
        launchOnboardingAtAX5()
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 15))
        tap("Get Started", step: "Welcome")
        OnboardingWalk.chooseSex("Female", in: app)
        tap("Continue", step: "Profile")
        tap("Continue", step: "Guideline")
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 10))
        try audit("Onboarding health")
        assertPrimaryButtonReachable("Done", step: "Health")
    }

    func test_onboardingProfile_atAX5_sexRowsEnableContinue() throws {
        launchOnboardingAtAX5()
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 15))
        tap("Get Started", step: "Welcome")

        let female = app.buttons["sexChoiceRow.female"]
        XCTAssertTrue(female.waitForExistence(timeout: 10), "AX5 About You should show sex choice rows")
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Continue"].isEnabled, "Continue must be disabled before a choice")

        female.tap()
        XCTAssertTrue(app.buttons["Continue"].isEnabled, "Choosing a row should enable Continue")
        assertPrimaryButtonReachable("Continue", step: "Profile")
    }
}
