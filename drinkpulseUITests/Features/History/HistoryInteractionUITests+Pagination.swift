import XCTest

@MainActor
extension HistoryInteractionUITests {

    func test_scrollToBottom_loadsOlderEntries() throws {
        launchApp(dataset: "paginationstress")
        openHistoryTab()

        XCTAssertTrue(eventButton(containing: "330 ml").waitForExistence(timeout: 10),
                      "List should show today's seeded events before any scrolling")
        XCTAssertFalse(eventButton(containing: "999 ml").exists,
                       "The 40-days-ago 999 ml marker event should be outside the first 50-event page")

        let marker = eventButton(containing: "999 ml")
        for _ in 0..<20 where !marker.exists {
            app.swipeUp()
        }

        XCTAssertTrue(marker.waitForExistence(timeout: 8),
                      "Scrolling straight down to the bottom should load the next page with the older "
                      + "marker event (999 ml, 40 days ago) without requiring an extra scroll-up")
    }
}
