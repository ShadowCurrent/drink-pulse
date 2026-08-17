import XCTest

@MainActor
extension HistoryInteractionUITests {

    func test_rowTopEdge_isTappable_opensEditor() throws {
        launchApp()
        openHistoryTab()

        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "The seeded 500 ml beer row should be present in the List segment")

        row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.06)).tap()

        XCTAssertTrue(app.navigationBars["Edit Drink"].waitForExistence(timeout: 5),
                      "Tapping the row's top padding band should open the Edit Drink sheet — "
                      + "if it does not, the padding is outside the interactive shape again")
    }

    func test_rowHitTarget_meetsMinimumHeight() throws {
        launchApp()
        openHistoryTab()

        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "The seeded 500 ml beer row should be present in the List segment")

        XCTAssertGreaterThanOrEqual(
            row.frame.height, 44,
            "A History row's touch target must be at least 44pt tall (got \(row.frame.height))"
        )
    }
}
