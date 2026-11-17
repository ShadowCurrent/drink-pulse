import XCTest

/// Ungated accessibility audit of the Onboarding welcome step (plan 11-21, audit group
/// A11Y-AUDIT-G07).
///
/// Audits the launch viewport with every audit type at the default text size and at AX5, in light
/// appearance. It runs in the normal suite and every reported issue fails the test. Onboarding has
/// no tab bar, so no D11-29 opt-in applies.
@MainActor
final class OnboardingAccessibilityAuditUITests: XCTestCase {

    override func setUpWithError() throws {
        // Collect every issue of a pass; each is its own failure.
        continueAfterFailure = true
    }

    /// Returns the app on the welcome step, or nil (after a recorded failure) when the step is not
    /// shown, so a navigation failure never reaches the audit.
    private func launchWelcome(contentSizeCategory: String?) -> XCUIApplication? {
        pinAppearance(.light)
        let app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(onboarding: true, contentSizeCategory: contentSizeCategory)
        app.launch()
        let shown = app.buttons["Get Started"].waitForExistence(timeout: 15)
        XCTAssertTrue(shown, "Onboarding welcome step should be shown")
        return shown ? app : nil
    }

    func test_onboardingWelcome_standard_hasNoAuditIssues() throws {
        guard let app = launchWelcome(contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Onboarding", variant: "standard")
    }

    func test_onboardingWelcome_ax5_hasNoAuditIssues() throws {
        guard let app = launchWelcome(contentSizeCategory: AuditLaunch.ax5Category) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Onboarding", variant: "ax5")
    }
}
