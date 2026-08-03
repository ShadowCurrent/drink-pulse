import XCTest

/// Hit-target coverage for the History row (finding C14-1). Split into its own
/// file matching the established `+Helpers` / `+Pagination` / `+DirectionalTransition`
/// convention — `HistoryInteractionUITests.swift` is already over the project's
/// 300-line ceiling and must not be grown.
///
/// The defect these pin: the row's 10pt vertical padding used to be applied to the
/// `Button`, OUTSIDE a `contentShape(Rectangle())` that had already pinned the
/// interactive shape to the unpadded `EventRow` frame. 20pt of every row's height
/// was therefore visible but inert. A center tap could never detect that — it lands
/// well inside the inner frame either way — which is why the first test taps a
/// normalized coordinate near the row's top edge instead of using `.tap()`.
///
/// Matching follows this suite's locale rule: the simulator's system locale is
/// Polish, so only app-rendered ENGLISH text and stable numeric values are matched.
@MainActor
extension HistoryInteractionUITests {

    /// Tapping the very top of a row — inside the padding band that used to be dead —
    /// opens the Edit sheet.
    func test_rowTopEdge_isTappable_opensEditor() throws {
        launchApp()
        openHistoryTab()

        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "The seeded 500 ml beer row should be present in the List segment")

        // dy 0.06 is inside the top padding band, not the row's text. Deliberately
        // NOT `row.tap()` — a center tap passes with or without the fix.
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.06)).tap()

        XCTAssertTrue(app.navigationBars["Edit Drink"].waitForExistence(timeout: 5),
                      "Tapping the row's top padding band should open the Edit Drink sheet — "
                      + "if it does not, the padding is outside the interactive shape again")
    }

    /// The row meets the 44pt minimum touch target CLAUDE.md requires.
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
