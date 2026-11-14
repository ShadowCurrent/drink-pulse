import XCTest

/// Automated accessibility audit for Phase 11 (VER-03).
///
/// Contract: every issue the audit reports must be listed in the Phase 11 debt
/// ledger section "Accessibility audit allow-list" and in `allowedIssues` under
/// the same ledger ID. Any other issue fails the test. An allow-list entry
/// matches only on screen, variant, audit type and element key, never on the
/// system-localized description text (the simulator locale is not English).
///
/// Limits: the audit covers the visible viewport of each screen at its launch
/// scroll position. It does not exercise Increase Contrast or Reduce Motion.
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

    private struct AllowedIssue {
        let ledgerID: String
        let screen: AuditScreen
        let variant: AuditVariant
        let typeName: String
        let elementKey: String
    }

    // MARK: - Allow-list (every entry has a row in the debt ledger)

    private static let allowedIssues: [AllowedIssue] = []

    private static let ax5Category = "UICTContentSizeCategoryAccessibilityXXXL"

    override func setUpWithError() throws {
        // Collect every issue of a screen in one pass; the handler records
        // each unrecorded issue as its own failure.
        continueAfterFailure = true
    }

    // MARK: - Launch and navigation

    private func launchApp(screen: AuditScreen, variant: AuditVariant) -> XCUIApplication {
        if variant == .dark {
            // Register the restore first so a failure cannot leave the simulator dark.
            addTeardownBlock {
                await MainActor.run { XCUIDevice.shared.appearance = .unspecified }
            }
            XCUIDevice.shared.appearance = .dark
        }
        let app = XCUIApplication()
        if screen == .onboarding {
            app.launchArguments += [
                "-dp_uitest", "YES",
                "-dp_force_onboarding", "YES",
            ]
        } else {
            app.launchArguments += [
                "-dp_onboarding_done", "YES",
                "-dp_uitest", "YES",
                "-dp_uitest_dataset", "multiday",
                "-dp_uitest_unit", "metric",
            ]
        }
        if variant == .ax5 {
            app.launchArguments += [
                "-UIPreferredContentSizeCategoryName", Self.ax5Category,
            ]
        }
        app.launch()
        return app
    }

    private func open(_ screen: AuditScreen, in app: XCUIApplication) {
        switch screen {
        case .onboarding:
            XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 15),
                          "Onboarding welcome step should be shown")
        case .addDrink:
            let tab = app.tabBars.buttons["Home"]
            XCTAssertTrue(tab.waitForExistence(timeout: 15), "Home tab should exist")
            tab.tap()
            let add = app.buttons["Add Drink"]
            XCTAssertTrue(add.waitForExistence(timeout: 10), "Add Drink button should exist on Home")
            add.tap()
            XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 10),
                          "Add Drink sheet should be shown")
        case .home, .insights, .history, .settings:
            let tab = app.tabBars.buttons[screen.rawValue]
            XCTAssertTrue(tab.waitForExistence(timeout: 15), "\(screen.rawValue) tab should exist")
            tab.tap()
            XCTAssertTrue(app.navigationBars[screen.rawValue].waitForExistence(timeout: 10),
                          "\(screen.rawValue) screen should be shown")
        }
    }

    // MARK: - Audit

    private func audit(screen: AuditScreen, variant: AuditVariant) throws {
        let app = launchApp(screen: screen, variant: variant)
        open(screen, in: app)
        try app.performAccessibilityAudit(for: .all) { [self] issue in
            record(issue, screen: screen, variant: variant)
        }
    }

    private func record(
        _ issue: XCUIAccessibilityAuditIssue,
        screen: AuditScreen,
        variant: AuditVariant
    ) -> Bool {
        let typeName = Self.typeName(for: issue.auditType)
        let elementKey = Self.elementKey(for: issue.element)
        let match = Self.allowedIssues.first {
            $0.screen == screen && $0.variant == variant
                && $0.typeName == typeName && $0.elementKey == elementKey
        }
        if let match {
            XCTContext.runActivity(named: "Suppressed known audit issue \(match.ledgerID)") { _ in }
            return true
        }
        XCTFail("Unrecorded accessibility audit issue: "
                + "screen=\(screen.rawValue) variant=\(variant.rawValue) "
                + "type=\(typeName) element=\(elementKey)")
        return true
    }

    private static func typeName(for type: XCUIAccessibilityAuditType) -> String {
        switch type {
        case .contrast: "contrast"
        case .elementDetection: "elementDetection"
        case .hitRegion: "hitRegion"
        case .sufficientElementDescription: "sufficientElementDescription"
        case .dynamicType: "dynamicType"
        case .textClipped: "textClipped"
        case .trait: "trait"
        default: "raw\(type.rawValue)"
        }
    }

    private static func elementKey(for element: XCUIElement?) -> String {
        guard let element else { return "none" }
        let raw = [element.identifier, element.label].first { !$0.isEmpty } ?? "none"
        return raw
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: " ")
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
