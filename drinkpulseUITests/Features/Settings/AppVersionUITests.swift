import XCTest

@MainActor
final class AppVersionUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_appVersionRow_isShownBelowDataSection_inVersionFormat() throws {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        app.launch()

        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10),
                      "Settings tab should be accessible after launch")
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Settings navigation bar should appear")

        let deleteAll = app.buttons["Delete all data"]
        var swipes = 0
        while !deleteAll.isHittable && swipes < 8 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(deleteAll.isHittable,
                      "'Delete all data' row should be reachable by scrolling")

        let versionRow = app.descendants(matching: .any)
            .matching(identifier: "settings.appVersion").firstMatch
        XCTAssertTrue(versionRow.waitForExistence(timeout: 5),
                      "App version footer should exist at the bottom of Settings")

        let pattern = NSPredicate(
            format: "label MATCHES %@", "(?s)Version [0-9]+(\\.[0-9]+)* \\([0-9]+\\).*"
        )
        XCTAssertTrue(pattern.evaluate(with: versionRow),
                      "Version footer should read 'Version X (Y)', got '\(versionRow.label)'")

        XCTAssertGreaterThan(versionRow.frame.minY, deleteAll.frame.maxY,
                             "Version footer should sit below the last Data row")
    }
}
