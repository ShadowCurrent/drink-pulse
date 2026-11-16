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
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 10),
                      "Home screen navigation bar should appear after launch")
    }

    private func probes(_ site: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "dp_motion.\(site)")
    }

    private func waitForProbes(_ site: String, count: Int) {
        var scrolls = 0
        while probes(site).count < count, scrolls < 3 {
            _ = probes(site).firstMatch.waitForExistence(timeout: 3)
            if probes(site).count >= count { break }
            app.swipeUp()
            scrolls += 1
        }
        XCTAssertEqual(probes(site).count, count, "expected \(count) dp_motion.\(site) probes")
    }

    private func assertLabels(_ site: String, count: Int, equal expected: String) {
        waitForProbes(site, count: count)
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
}
