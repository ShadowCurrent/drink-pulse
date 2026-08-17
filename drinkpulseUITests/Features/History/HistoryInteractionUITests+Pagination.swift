import XCTest

@MainActor
extension HistoryInteractionUITests {

    func test_scrollToBottom_loadsOlderEntries() throws {
        launchApp(dataset: "paginationstress")
        openHistoryTab()

        XCTAssertTrue(eventButton(containing: "330 ml").waitForExistence(timeout: 10),
                      "List should show today's seeded events before any scrolling")
        XCTAssertFalse(eventButton(containing: "999 ml").exists,
                       "The 20-days-ago 999 ml marker event should be outside the initial 7-day window")

        for _ in 0..<6 {
            app.swipeUp()
        }

        XCTAssertTrue(eventButton(containing: "999 ml").waitForExistence(timeout: 8),
                      "Scrolling straight down to the bottom should load the older marker event "
                      + "(999 ml, 20 days ago) without requiring an extra scroll-up")
    }
}
