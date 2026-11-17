import XCTest

/// Ungated accessibility audit of the Settings tab (plan 11-20, audit groups A11Y-AUDIT-G06 and the
/// Settings share of G09).
///
/// Audits the launch viewport with every audit type, the same coverage as the gated
/// `AccessibilityAuditUITests` Settings methods, at the default text size in light and dark
/// appearance and at AX5. It runs in the normal suite with the seeded profile (the no-profile
/// progress indicator, OBS-C, is out of scope) and every reported issue fails the test, with one
/// owner-approved exception (D11-29, amending D11-25): `contrast` and `textClipped` issues on app
/// text that lies under the system tab bar at the launch scroll position are not evaluated. At the
/// launch viewport that is the reminder row and its caption at the default size, and the
/// Preferences header and the first Preferences row at AX5. Each ignored issue is still recorded as
/// a warning with its key and frame, and the count is recorded per variant.
@MainActor
final class SettingsAccessibilityAuditUITests: XCTestCase {

    override func setUpWithError() throws {
        // Collect every issue of a pass; each is its own failure.
        continueAfterFailure = true
    }

    /// Returns the app on Settings, or nil (after a recorded failure) when navigation fails, so a
    /// navigation failure never reaches the audit.
    private func launchAndOpenSettings(
        appearance: XCUIDevice.Appearance,
        contentSizeCategory: String?
    ) -> XCUIApplication? {
        pinAppearance(appearance)
        let app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(onboarding: false, contentSizeCategory: contentSizeCategory)
        app.launch()
        let tab = app.tabBars.buttons["Settings"]
        let hasTab = tab.waitForExistence(timeout: 15)
        XCTAssertTrue(hasTab, "Settings tab should exist")
        guard hasTab else { return nil }
        tab.tap()
        let shown = app.navigationBars["Settings"].waitForExistence(timeout: 10)
        XCTAssertTrue(shown, "Settings screen should be shown")
        return shown ? app : nil
    }

    func test_settings_standard_hasNoAuditIssues() throws {
        guard let app = launchAndOpenSettings(appearance: .light, contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(
            in: app, types: .all, screen: "Settings", variant: "standard", ignoreTabBarOccludedContent: true
        )
    }

    func test_settings_dark_hasNoAuditIssues() throws {
        guard let app = launchAndOpenSettings(appearance: .dark, contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(
            in: app, types: .all, screen: "Settings", variant: "dark", ignoreTabBarOccludedContent: true
        )
    }

    func test_settings_ax5_hasNoAuditIssues() throws {
        guard let app = launchAndOpenSettings(appearance: .light, contentSizeCategory: AuditLaunch.ax5Category) else {
            return
        }
        try assertNoAuditIssues(
            in: app, types: .all, screen: "Settings", variant: "ax5", ignoreTabBarOccludedContent: true
        )
    }
}
