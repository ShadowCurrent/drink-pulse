import XCTest

/// Coverage for the empty-initial-window recovery path on the History list
/// (finding B10-1). Split into its own file to keep
/// `HistoryInteractionUITests.swift` from growing further — that file's own doc
/// comment already flags it as over the project's 300-line ceiling.
///
/// Background: quick task `260802-uia` shrank `HistoryViewModel.listPageDays`
/// from 90 to 7, so a user whose last drink was more than a week ago now opens
/// History on a window with no events in it. Before this plan that rendered a
/// completely blank `List`; it now renders a labelled progress row *alongside*
/// the load-more sentinel.
@MainActor
extension HistoryInteractionUITests {

    /// The outside-window fixture seeds three 777 ml beers at 10, 12 and 40 days
    /// ago and **nothing inside the 7-day initial window**, so the list starts
    /// with zero rows and `hasMore == true`.
    ///
    /// **What this test proves.** That the list still recovers to rows. That is
    /// exactly the failure mode this plan could have introduced: the loading row
    /// is added *above* the `hasMore` conditional as its own `if`, and if it had
    /// instead been written as an `else if` branch that displaces
    /// `LoadMoreSentinel`, nothing would ever call `extendListWindow`, the window
    /// would never widen, and the 777 ml rows would never appear — this test
    /// would fail.
    ///
    /// **What it deliberately does not prove.** That the spinner was *seen*. The
    /// blank state self-heals within roughly one render cycle: the sentinel is the
    /// only row, so its `.onAppear` fires immediately, and
    /// `extendedWindowStart(from:earliest:)` collapses every consecutive empty
    /// page in one jump. A timing-based assertion on that transient would be
    /// flaky, and a flaky test is worse than no test. The presence and labelling
    /// of the loading row are pinned by source assertions in this plan's Task 2,
    /// and its appearance by the plan's human check.
    ///
    /// Do not shorten the timeout to try to "catch" the spinner, and do not add a
    /// delay to the production path to make the transient observable.
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
