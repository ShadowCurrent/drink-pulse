import XCTest

/// Probe-only audit assertion (ungated).
///
/// The test-only probes (`dp_health_sample_count` and the one point `dp_motion.*` elements) exist
/// whenever `-dp_uitest` is set, so every all-types per-screen audit sees them. These tests fail on any
/// finding, of any audit type, reported for a probe element, and first assert that the probes exist so
/// they cannot pass vacuously. They complement the unfiltered per-screen audit classes and never
/// replace them.
@MainActor
final class ProbeAccessibilityAuditUITests: XCTestCase {

    private let identifierPrefixes = ["dp_motion.", "dp_health_sample_count"]

    override func setUpWithError() throws {
        // Collect every finding of a pass; each is its own failure.
        continueAfterFailure = true
    }

    private func launchAndOpen(tab name: String) -> XCUIApplication? {
        pinAppearance(.light)
        let app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(onboarding: false, contentSizeCategory: nil)
        app.launch()
        let tab = app.tabBars.buttons[name]
        let hasTab = tab.waitForExistence(timeout: 15)
        XCTAssertTrue(hasTab, "\(name) tab should exist")
        guard hasTab else { return nil }
        tab.tap()
        let shown = app.navigationBars[name].waitForExistence(timeout: 10)
        XCTAssertTrue(shown, "\(name) screen should be shown")
        return shown ? app : nil
    }

    private func probe(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func test_probes_onHome_haveNoAuditIssues() throws {
        guard let app = launchAndOpen(tab: UITestTabs.today) else { return }
        var swipes = 0
        while !probe("dp_motion.overviewBar", in: app).waitForExistence(timeout: 3), swipes < 3 {
            app.swipeUp()
            swipes += 1
        }
        try assertNoAuditIssuesOnProbes(
            in: app,
            types: .all,
            requiredIdentifiers: ["dp_health_sample_count", "dp_motion.overviewBar", "dp_motion.heroArc"],
            identifierPrefixes: identifierPrefixes,
            screen: UITestTabs.today,
            variant: "standard"
        )
    }

    func test_probes_onHistoryCalendar_haveNoAuditIssues() throws {
        guard let app = launchAndOpen(tab: "History") else { return }
        let segment = app.segmentedControls.buttons["Calendar"]
        let hasSegment = segment.waitForExistence(timeout: 5)
        XCTAssertTrue(hasSegment, "History segment 'Calendar' should exist")
        guard hasSegment else { return }
        segment.tap()
        XCTAssertTrue(probe("dp_motion.historyCalendar", in: app).waitForExistence(timeout: 5),
                      "Calendar card should expose its probe")
        try assertNoAuditIssuesOnProbes(
            in: app,
            types: .all,
            requiredIdentifiers: ["dp_health_sample_count", "dp_motion.historyCalendar"],
            identifierPrefixes: identifierPrefixes,
            screen: "History calendar",
            variant: "standard"
        )
    }
}
