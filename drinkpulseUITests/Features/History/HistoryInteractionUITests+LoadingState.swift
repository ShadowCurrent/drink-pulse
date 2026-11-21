import XCTest

@MainActor
extension HistoryInteractionUITests {

    func test_allDataOutsideInitialWindow_recoversToRows() throws {
        launchApp(dataset: "outsidewindow")
        openHistoryTab()

        XCTAssertTrue(
            eventButton(containing: "777 ml").waitForExistence(timeout: 10),
            "Every seeded event is more than a week old; count-based paging must still show "
            + "them on the first page instead of an empty list."
        )
    }
}
