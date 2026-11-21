import UIKit
import XCTest

/// Reduce Motion wiring on Home. XCUITest waits for the app to be idle, so it cannot observe an
/// animation frame; these tests prove the forced route reaches each site and that the site reports
/// the same decision its animation modifier uses (DPMotion). The behavior itself is observed by the owner.
@MainActor
final class ReduceMotionDashboardUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(forceReduceMotion: Bool) {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        if forceReduceMotion {
            app.launchArguments += ["-dp_uitest_reduce_motion", "YES"]
        }
        app.launch()
        XCTAssertTrue(app.navigationBars[UITestTabs.today].waitForExistence(timeout: 10),
                      "Home screen navigation bar should appear after launch")
    }

    private func probes(_ site: String) -> XCUIElementQuery {
        // The hero card merges its subtree into one element that inherits the probe's identifier, so
        // only elements whose label is a probe state word are probes.
        app.descendants(matching: .any)
            .matching(identifier: "dp_motion.\(site)")
            .matching(NSPredicate(format: "label IN %@", ["reduced", "animated"]))
    }

    private func waitForProbes(_ site: String, count: Int, exact: Bool = true) {
        var scrolls = 0
        while probes(site).count < count, scrolls < 3 {
            _ = probes(site).firstMatch.waitForExistence(timeout: 3)
            if probes(site).count >= count { break }
            app.swipeUp()
            scrolls += 1
        }
        if exact {
            XCTAssertEqual(probes(site).count, count, "expected \(count) dp_motion.\(site) probes")
        } else {
            XCTAssertGreaterThanOrEqual(probes(site).count, count, "expected a dp_motion.\(site) probe")
        }
    }

    private func assertLabels(_ site: String, count: Int, exact: Bool = true, equal expected: String) {
        waitForProbes(site, count: count, exact: exact)
        for element in probes(site).allElementsBoundByIndex {
            XCTAssertEqual(element.label, expected, "dp_motion.\(site) should report '\(expected)'")
        }
    }

    // MARK: - Overview bars

    func test_forcedReduceMotion_overviewBarsReportReduced() throws {
        launchApp(forceReduceMotion: true)
        assertLabels("overviewBar", count: 3, equal: "reduced")
    }

    func test_withoutOverride_overviewBarsReportAnimated_whenSystemReduceMotionIsOff() throws {
        try XCTSkipIf(UIAccessibility.isReduceMotionEnabled, "Device has Reduce Motion on")
        launchApp(forceReduceMotion: false)
        assertLabels("overviewBar", count: 3, equal: "animated")
    }

    // MARK: - Hero arc

    func test_forcedReduceMotion_heroArcReportsReduced() throws {
        launchApp(forceReduceMotion: true)
        assertLabels("heroArc", count: 1, exact: false, equal: "reduced")
    }

    func test_withoutOverride_heroArcReportsAnimated_whenSystemReduceMotionIsOff() throws {
        try XCTSkipIf(UIAccessibility.isReduceMotionEnabled, "Device has Reduce Motion on")
        launchApp(forceReduceMotion: false)
        assertLabels("heroArc", count: 1, exact: false, equal: "animated")
    }
}
