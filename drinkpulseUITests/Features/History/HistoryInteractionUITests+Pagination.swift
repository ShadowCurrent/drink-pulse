import XCTest

/// Pagination regression coverage for the History list (List -> ScrollView +
/// LazyVStack migration, plan-0038). Split into its own file to keep
/// `HistoryInteractionUITests.swift` from growing further — that file's own
/// doc comment already flags it as over the project's 300-line ceiling.
///
/// Regression: `LoadMoreSentinel`'s trailing sentinel used `.onAppear` to
/// detect "scrolled near the bottom," which is documented as unreliable
/// inside ScrollView+LazyVStack (unlike `List`) — a genuine scroll-to-bottom
/// gesture could fail to trigger it at all, only firing after an unrelated
/// extra scroll delta forced a corrective layout pass. Fixed by switching to
/// `onScrollVisibilityChange(threshold:_:)` (iOS 18+), which reports real
/// threshold-crossing visibility instead of relying on LazyVStack's estimated
/// content geometry. See `.planning/debug/resolved/history-scrollview-bugs.md`.
///
/// Known limitation: this test asserts the end-to-end user-visible outcome
/// ("scrolling to the bottom of a dense list loads older entries") and is a
/// real regression guard for that flow, but XCUITest's synthesized
/// `swipeUp()` gestures (fast, decisive, force-idle between each) were not
/// observed to reproduce the original bug's exact stuck state in this harness
/// — reverting only the trigger (`.onAppear`) still passed here. The bug and
/// fix are confirmed via direct root-cause evidence instead (Apple WWDC26
/// session 321 + `onScrollVisibilityChange` docs — see the debug session).
@MainActor
extension HistoryInteractionUITests {

    /// The `-dp_uitest_dataset paginationstress` fixture seeds 21 events across
    /// 7 differently-shaped day-section cards (today through 6 days ago — well
    /// inside the initial `listPageDays` window, but overflowing one screen
    /// height) plus one marker event 20 days ago (999 ml — the only 999 ml
    /// entry, so it's an unambiguous match). Because the initial window's
    /// content doesn't fit on one screen, the trailing "load more" sentinel is
    /// NOT visible on first layout — reaching it requires a genuine scroll.
    /// Row/section counts are tuned narrowly: fewer rows and the content fits
    /// on one screen (no scroll needed, sentinel already visible); more rows
    /// (tried up to 22) made XCUITest's own accessibility-query evaluation
    /// pathologically slow against this many `.eventContextMenu`-registered
    /// buttons, independent of app behavior. Blind, unchecked swipes (no
    /// `waitForExistence` polling in between) keep the total accessibility-
    /// query volume low against this fixture.
    func test_scrollToBottom_loadsOlderEntries() throws {
        launchApp(dataset: "paginationstress")
        openHistoryTab()

        XCTAssertTrue(eventButton(containing: "330 ml").waitForExistence(timeout: 10),
                      "List should show today's seeded events before any scrolling")
        XCTAssertFalse(eventButton(containing: "999 ml").exists,
                       "The 20-days-ago 999 ml marker event should be outside the initial 7-day window")

        // Straight downward scrolling only — no scroll-up correction. This is
        // the exact gesture that failed to trigger pagination before the fix.
        for _ in 0..<6 {
            app.swipeUp()
        }

        XCTAssertTrue(eventButton(containing: "999 ml").waitForExistence(timeout: 8),
                      "Scrolling straight down to the bottom should load the older marker event "
                      + "(999 ml, 20 days ago) without requiring an extra scroll-up")
    }
}
