import XCTest

/// Automated accessibility audit for Phase 11 (VER-03), gated by default.
///
/// Open findings (owner decision D11-22) are recorded in
/// `.planning/phases/11-ios-27-release-verification/11-EVIDENCE.md`, section "Accessibility audit
/// (exploratory run, D11-22)", and in the Phase 11 debt ledger. None is allow-listed.
/// Every method skips unless `DP_RUN_A11Y_AUDIT=1` is set in the test runner environment
/// (for xcodebuild: `TEST_RUNNER_DP_RUN_A11Y_AUDIT=1`), so the full suite stays green. With the flag
/// set, every issue the audit reports fails the test. There is deliberately no allow-list: nothing
/// may mute an issue. Remove the gate when the findings are fixed under their owner briefs.
///
/// Limits: the audit covers the visible viewport of each screen at its launch scroll position.
/// It does not exercise Increase Contrast or Reduce Motion. Add Drink and Onboarding are audited
/// at the standard and AX5 variants only (no dark variant), so dark contrast on those two screens
/// is covered by the human check CHK-08 only.
@MainActor
final class AccessibilityAuditUITests: XCTestCase {

    // MARK: - Types

    private enum AuditScreen: String {
        case home = "Home"
        case insights = "Insights"
        case history = "History"
        case settings = "Settings"
        case addDrink = "Add Drink"
        case onboarding = "Onboarding"
    }

    private enum AuditVariant: String {
        case standard
        case ax5
        case dark
    }

    override func setUpWithError() throws {
        try Self.skipUnlessAuditEnabled()
        // Collect every issue of a screen in one pass; the handler records
        // each issue as its own failure.
        continueAfterFailure = true
    }

    /// The audit has open findings (decision D11-22), so it runs only on explicit opt-in.
    /// The skip reason is reported in the test results.
    private nonisolated static func skipUnlessAuditEnabled() throws {
        let enabled = ProcessInfo.processInfo.environment["DP_RUN_A11Y_AUDIT"] == "1"
        try XCTSkipUnless(
            enabled,
            "Phase 11 accessibility audit: open findings are recorded in 11-EVIDENCE.md "
                + "(decision D11-22). Set DP_RUN_A11Y_AUDIT=1 to run. See section "
                + "\"Accessibility audit (exploratory run, D11-22)\" and todo "
                + "2026-11-14-fix-accessibility-audit-findings."
        )
    }

    // MARK: - Launch and navigation

    private func launchApp(screen: AuditScreen, variant: AuditVariant) -> XCUIApplication {
        // Appearance is simulator-global and survives the test process, so pin it for every
        // variant. Register the restore first so a failure cannot leave the simulator dark.
        // The simulator rejects .unspecified ("Requested appearance value (0) is not valid"),
        // so restore the appearance read before the change, light if unset.
        let previous = XCUIDevice.shared.appearance
        let restored: XCUIDevice.Appearance = previous == .unspecified ? .light : previous
        addTeardownBlock {
            await MainActor.run { XCUIDevice.shared.appearance = restored }
        }
        XCUIDevice.shared.appearance = variant == .dark ? .dark : .light
        let app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(
            onboarding: screen == .onboarding,
            contentSizeCategory: variant == .ax5 ? AuditLaunch.ax5Category : nil
        )
        app.launch()
        return app
    }

    /// True only when every wait for the tab, navigation bar, button or sheet succeeded.
    private func open(_ screen: AuditScreen, in app: XCUIApplication) -> Bool {
        switch screen {
        case .onboarding:
            let shown = app.buttons["Get Started"].waitForExistence(timeout: 15)
            XCTAssertTrue(shown, "Onboarding welcome step should be shown")
            return shown
        case .addDrink:
            let tab = app.tabBars.buttons["Home"]
            let hasTab = tab.waitForExistence(timeout: 15)
            XCTAssertTrue(hasTab, "Home tab should exist")
            guard hasTab else { return false }
            tab.tap()
            let add = app.buttons["Add Drink"]
            let hasAdd = add.waitForExistence(timeout: 10)
            XCTAssertTrue(hasAdd, "Add Drink button should exist on Home")
            guard hasAdd else { return false }
            add.tap()
            let sheet = app.navigationBars["Add Drink"].waitForExistence(timeout: 10)
            XCTAssertTrue(sheet, "Add Drink sheet should be shown")
            return sheet
        case .home, .insights, .history, .settings:
            let tab = app.tabBars.buttons[screen.rawValue]
            let hasTab = tab.waitForExistence(timeout: 15)
            XCTAssertTrue(hasTab, "\(screen.rawValue) tab should exist")
            guard hasTab else { return false }
            tab.tap()
            let shown = app.navigationBars[screen.rawValue].waitForExistence(timeout: 10)
            XCTAssertTrue(shown, "\(screen.rawValue) screen should be shown")
            return shown
        }
    }

    // MARK: - Audit

    private func audit(screen: AuditScreen, variant: AuditVariant) throws {
        let app = launchApp(screen: screen, variant: variant)
        guard open(screen, in: app) else { return }
        try app.performAccessibilityAudit(for: .all) { [self] issue in
            record(issue, screen: screen, variant: variant)
        }
    }

    private func record(
        _ issue: XCUIAccessibilityAuditIssue,
        screen: AuditScreen,
        variant: AuditVariant
    ) -> Bool {
        let typeName = AccessibilityAuditKey.typeName(for: issue.auditType)
        let elementKey = AccessibilityAuditKey.elementKey(for: issue.element)
        XCTFail("Accessibility audit issue: "
                + "screen=\(screen.rawValue) variant=\(variant.rawValue) "
                + "type=\(typeName) element=\(elementKey)")
        // true means handled, so the system does not record a second failure.
        return true
    }

    // MARK: - Tests

    func test_audit_home_standard() throws { try audit(screen: .home, variant: .standard) }
    func test_audit_home_ax5() throws { try audit(screen: .home, variant: .ax5) }
    func test_audit_home_dark() throws { try audit(screen: .home, variant: .dark) }
    func test_audit_insights_standard() throws { try audit(screen: .insights, variant: .standard) }
    func test_audit_insights_ax5() throws { try audit(screen: .insights, variant: .ax5) }
    func test_audit_insights_dark() throws { try audit(screen: .insights, variant: .dark) }
    func test_audit_history_standard() throws { try audit(screen: .history, variant: .standard) }
    func test_audit_history_ax5() throws { try audit(screen: .history, variant: .ax5) }
    func test_audit_history_dark() throws { try audit(screen: .history, variant: .dark) }
    func test_audit_settings_standard() throws { try audit(screen: .settings, variant: .standard) }
    func test_audit_settings_ax5() throws { try audit(screen: .settings, variant: .ax5) }
    func test_audit_settings_dark() throws { try audit(screen: .settings, variant: .dark) }
    func test_audit_addDrink_standard() throws { try audit(screen: .addDrink, variant: .standard) }
    func test_audit_addDrink_ax5() throws { try audit(screen: .addDrink, variant: .ax5) }
    func test_audit_onboarding_standard() throws { try audit(screen: .onboarding, variant: .standard) }
    func test_audit_onboarding_ax5() throws { try audit(screen: .onboarding, variant: .ax5) }
}
