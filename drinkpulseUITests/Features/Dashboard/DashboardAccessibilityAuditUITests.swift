import XCTest

/// Ungated accessibility audit of the Home tab (plan 11-17, audit group A11Y-AUDIT-G03).
///
/// Audits the launch viewport with every audit type, the same coverage as the gated
/// `AccessibilityAuditUITests` Home methods, at the default text size in light and dark
/// appearance and at AX5. It runs in the normal suite; every reported issue fails the test and
/// nothing is exempt.
@MainActor
final class DashboardAccessibilityAuditUITests: XCTestCase {

    override func setUpWithError() throws {
        // Collect every issue of a pass; each is its own failure.
        continueAfterFailure = true
    }

    /// Returns the app on Home, or nil (after a recorded failure) when navigation fails, so a
    /// navigation failure never reaches the audit.
    private func launchAndOpenHome(
        appearance: XCUIDevice.Appearance,
        contentSizeCategory: String?
    ) -> XCUIApplication? {
        pinAppearance(appearance)
        let app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(onboarding: false, contentSizeCategory: contentSizeCategory)
        app.launch()
        let tab = app.tabBars.buttons["Home"]
        let hasTab = tab.waitForExistence(timeout: 15)
        XCTAssertTrue(hasTab, "Home tab should exist")
        guard hasTab else { return nil }
        tab.tap()
        let shown = app.navigationBars["Home"].waitForExistence(timeout: 10)
        XCTAssertTrue(shown, "Home screen should be shown")
        return shown ? app : nil
    }

    func test_home_standard_hasNoAuditIssues() throws {
        guard let app = launchAndOpenHome(appearance: .light, contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Home", variant: "standard")
    }

    func test_home_dark_hasNoAuditIssues() throws {
        guard let app = launchAndOpenHome(appearance: .dark, contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Home", variant: "dark")
    }

    func test_home_ax5_hasNoAuditIssues() throws {
        guard let app = launchAndOpenHome(appearance: .light, contentSizeCategory: AuditLaunch.ax5Category) else {
            return
        }
        try assertNoAuditIssues(in: app, types: .all, screen: "Home", variant: "ax5")
    }
}
