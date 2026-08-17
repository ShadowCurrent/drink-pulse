import XCTest

@MainActor
extension HistoryInteractionUITests {

    func test_allDataOutsideInitialWindow_recoversToRows() throws {
        launchApp(dataset: "outsidewindow")
        openHistoryTab()

        XCTAssertTrue(
            eventButton(containing: "777 ml").waitForExistence(timeout: 10),
            "Every seeded event is older than the 7-day initial window, so the list starts "
            + "empty; the load-more sentinel must still fire and bring the 777 ml rows in."
        )
    }
}
