import UIKit
import XCTest

/// Reduce Motion wiring on the History calendar. XCUITest cannot observe an animation frame; these
/// tests prove the forced route reaches the calendar card, that the card reports the decision its
/// animation modifier uses (DPMotion), and that day selection still works with motion reduced.
@MainActor
final class ReduceMotionHistoryUITests: XCTestCase {
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
    }

    private func openCalendar() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should be accessible after launch")
        tab.tap()
        let segment = app.segmentedControls.buttons["Calendar"]
        XCTAssertTrue(segment.waitForExistence(timeout: 5), "History segment 'Calendar' should exist")
        segment.tap()
    }

    private var probe: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "dp_motion.historyCalendar").firstMatch
    }

    func test_forcedReduceMotion_calendarCardReportsReduced_andDayDetailStillAppears() throws {
        launchApp(forceReduceMotion: true)
        openCalendar()

        XCTAssertTrue(probe.waitForExistence(timeout: 5), "Calendar card should expose its Reduce Motion probe")
        XCTAssertEqual(probe.label, "reduced", "Forced Reduce Motion should reach the calendar card")

        let number = String(Calendar.current.component(.day, from: .now))
        let todayCell = app.buttons.matching(
            NSPredicate(format: "label MATCHES %@", "^\(number)\\D.*")
        ).firstMatch
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5), "Today's calendar day cell should exist")
        todayCell.tap()

        let detailRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "500 ml")).firstMatch
        XCTAssertTrue(detailRow.waitForExistence(timeout: 5),
                      "Tapping today's day cell should still reveal the 500 ml day-detail row")
    }

    func test_withoutOverride_calendarCardReportsAnimated_whenSystemReduceMotionIsOff() throws {
        try XCTSkipIf(UIAccessibility.isReduceMotionEnabled, "Device has Reduce Motion on")
        launchApp(forceReduceMotion: false)
        openCalendar()

        XCTAssertTrue(probe.waitForExistence(timeout: 5), "Calendar card should expose its Reduce Motion probe")
        XCTAssertEqual(probe.label, "animated", "Without the override the calendar card should report animated")
    }
}
