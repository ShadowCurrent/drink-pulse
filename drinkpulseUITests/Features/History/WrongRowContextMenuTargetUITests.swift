import XCTest

/// Regression pin for a health-data correctness bug (live user report, 2026-08-05,
/// see `.planning/debug/contextmenu-zoom-glitch.md`): on a day with 2+ events,
/// long-pressing a row that was NOT the first one in the retired
/// `HistoryDaySectionCard`'s `ForEach` and choosing Duplicate or Delete from the
/// context menu acted on the WRONG event — always the first-registered one,
/// never the one actually pressed.
///
/// Root cause (confirmed via on-device `os.Logger` instrumentation comparing
/// menu-BUILD-time vs action-EXEC-time event identity, and independently
/// corroborated by Apple Developer Forums reports): `HistoryDaySectionCard`
/// rendered as ONE `List` row per day, with every event in that day a
/// `.contextMenu`-bearing subview NESTED INSIDE that single shared row.
/// SwiftUI/`UIContextMenuInteraction` does not correctly scope multiple
/// `.contextMenu`s declared on sibling subviews of one `List` row — the
/// long-press interaction that fired was always the FIRST one registered for
/// that row, regardless of which subview's bounds were actually touched.
///
/// FIXED by flattening `HistoryListQueryView`'s `List` to one top-level row
/// per `ConsumptionEvent` (`HistoryEventCardRow`, day boundaries as
/// non-interactive header pseudo-rows in the SAME flat `ForEach` — see
/// `HistoryFlatRow.swift`): every event now owns its own List row/cell, so
/// there is exactly one `.contextMenu` per row and no sibling to misroute to.
/// This also made the custom `.contextMenu(menuItems:preview:)` machinery
/// added earlier in the same debug session unnecessary — reverted back to the
/// plain `.contextMenu(menuItems:)` (`EventContextMenu.swift`), since the
/// default lift/preview now correctly scopes to the single pressed row.
@MainActor
final class WrongRowContextMenuTargetUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
            "-dp_uitest_dataset", "sameday",
        ]
        app.launch()
    }

    private func rows(containing substring: String) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring))
    }

    /// Long-pressing the BOTTOM (beer, 08:00) row and tapping Duplicate must
    /// duplicate the BEER row, not the TOP (wine, 20:00) row.
    func test_duplicateBottomRow_duplicatesBeerNotWine() throws {
        launchApp()

        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should be accessible")
        tab.tap()

        let beerRow = rows(containing: "330 ml").firstMatch
        XCTAssertTrue(beerRow.waitForExistence(timeout: 10), "Seeded 330 ml beer row should be present")
        XCTAssertTrue(rows(containing: "750 ml").firstMatch.waitForExistence(timeout: 5), "Seeded wine row should be present")

        // Long-press the BOTTOM row (beer, 08:00 — sorts below the 20:00 wine).
        beerRow.press(forDuration: 1.2)

        let duplicate = app.buttons["Duplicate"]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5), "Context menu should offer Duplicate")
        duplicate.tap()

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if rows(containing: "330 ml").count == 2 || rows(containing: "750 ml").count == 2 { break }
            usleep(150_000)
        }

        let beerCount = rows(containing: "330 ml").count
        let wineCount = rows(containing: "750 ml").count
        XCTAssertEqual(beerCount, 2,
                       "Long-pressing the BOTTOM (beer) row and tapping Duplicate must duplicate the "
                       + "BEER row (count should be 2), got beer=\(beerCount) wine=\(wineCount)")
        XCTAssertEqual(wineCount, 1,
                       "The wine row (TOP, not pressed) must be unaffected, got wine=\(wineCount)")
    }

    /// Long-pressing the BOTTOM (beer, 08:00) row and confirming Delete must
    /// delete the BEER row, not the TOP (wine, 20:00) row. Higher severity than
    /// the Duplicate case above — Delete is irreversible.
    func test_deleteBottomRow_deletesBeerNotWine() throws {
        launchApp()

        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should be accessible")
        tab.tap()

        let beerRow = rows(containing: "330 ml").firstMatch
        XCTAssertTrue(beerRow.waitForExistence(timeout: 10), "Seeded 330 ml beer row should be present")
        XCTAssertTrue(rows(containing: "750 ml").firstMatch.waitForExistence(timeout: 5), "Seeded wine row should be present")

        beerRow.press(forDuration: 1.2)

        let delete = app.buttons["Delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "Context menu should offer Delete")
        delete.tap()

        let confirm = app.buttons["confirmContextDeleteButton"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Delete should open a confirmation")
        confirm.tap()

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if rows(containing: "330 ml").count == 0 || rows(containing: "750 ml").count == 0 { break }
            usleep(150_000)
        }

        XCTAssertEqual(rows(containing: "330 ml").count, 0,
                       "Long-pressing the BOTTOM (beer) row and confirming Delete must delete the BEER row")
        XCTAssertEqual(rows(containing: "750 ml").count, 1,
                       "The wine row (TOP, not pressed) must survive")
    }
}
