import XCTest

@MainActor
final class HistoryDynamicTypeUITests: XCTestCase {
    private var app: XCUIApplication!

    private let volumeMarker = "500 ml"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private let defaultCategory = "UICTContentSizeCategoryL"

    private let ax5Category = "UICTContentSizeCategoryAccessibilityXXXL"

    private func launchApp(contentSizeCategory: String) {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
            "-UIPreferredContentSizeCategoryName", contentSizeCategory,
        ]
        app.launch()
    }

    private func openHistoryTab() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 15),
                      "History tab should be accessible after launch")
        tab.tap()
    }

    private func seededRow() -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", volumeMarker)
        ).firstMatch
    }

    func test_row_growsAndStaysHittable_atAX5() throws {
        launchApp(contentSizeCategory: defaultCategory)
        openHistoryTab()

        let defaultRow = seededRow()
        XCTAssertTrue(defaultRow.waitForExistence(timeout: 15),
                      "The seeded \(volumeMarker) row should exist at the default content size")
        let defaultHeight = defaultRow.frame.height
        app.terminate()

        launchApp(contentSizeCategory: ax5Category)
        openHistoryTab()

        let axRow = seededRow()
        XCTAssertTrue(axRow.waitForExistence(timeout: 15),
                      "The seeded \(volumeMarker) row should exist at AX5")
        let axFrame = axRow.frame

        XCTAssertGreaterThan(
            axFrame.height, defaultHeight,
            "The row must grow at AX5 (default \(defaultHeight), AX5 \(axFrame.height)). "
            + "Equal heights mean -UIPreferredContentSizeCategoryName did not take effect, "
            + "or the row is clipped to a fixed height."
        )

        XCTAssertTrue(axRow.isHittable, "The row must still be hittable at AX5")

        let window = app.windows.firstMatch
        XCTAssertLessThanOrEqual(
            axFrame.maxX, window.frame.maxX,
            "The row must not overflow the window horizontally at AX5 "
            + "(row maxX \(axFrame.maxX), window maxX \(window.frame.maxX))"
        )

        XCTAssertTrue(
            axRow.label.contains(volumeMarker),
            "The combined row label must still carry the volume at AX5 (got: \(axRow.label))"
        )

        axRow.tap()
        XCTAssertTrue(app.navigationBars["Edit Drink"].waitForExistence(timeout: 5),
                      "The row must still open the Edit Drink sheet at AX5")
    }
}
