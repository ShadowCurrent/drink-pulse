import XCTest

/// UI coverage for the History row context menu's delete confirmation.
///
/// Long-pressing a History row opens a context menu offering Duplicate and a
/// destructive Delete. Delete destroys a logged health record with no undo, so
/// it is gated by a confirmation dialog — matching the Edit sheet's already
/// shipped, already UI-tested posture (`EditDeleteConfirmationUITests`).
/// Duplicate is non-destructive and stays one tap.
///
/// Disambiguation: THREE controls expose the English label "Delete" across
/// these flows — the context-menu item, this dialog's confirm button, and the
/// Edit sheet's toolbar trash. Never match the confirm control by label. This
/// dialog's confirm carries the stable identifier `confirmContextDeleteButton`,
/// deliberately distinct from the Edit sheet's `confirmDeleteButton`, so a
/// query written for one flow can never cross-match the other.
///
/// Seed: `-dp_uitest YES` inserts a single "Today" 500 ml 5% beer in an
/// in-memory store; the row subtitle renders "500 ml" in metric.
@MainActor
final class ContextMenuDeleteConfirmationUITests: XCTestCase {
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
        ]
        app.launch()
    }

    private func openHistoryTab() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10),
                      "History tab should be accessible after launch")
        tab.tap()
    }

    private func eventButton(containing substring: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
    }

    private func beerRowCount() -> Int {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "500 ml")).count
    }

    /// The confirmation's destructive button, addressed by its stable identifier.
    ///
    /// `.firstMatch` is required, not cosmetic: SwiftUI publishes the presented
    /// `confirmationDialog`'s buttons at more than one point in the accessibility
    /// hierarchy, so the bare subscript query resolves to multiple elements and
    /// `tap()` fails with "Multiple matching elements found". Resolving the first
    /// match keeps the query keyed on the identifier — never on the English label
    /// "Delete", which several controls in these flows share.
    private func confirmDeleteButton() -> XCUIElement {
        app.buttons["confirmContextDeleteButton"].firstMatch
    }

    private func waitForBeerRowCount(_ expected: Int, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if beerRowCount() == expected { return true }
            usleep(150_000)
        }
        return beerRowCount() == expected
    }

    /// Long-presses the seeded beer row and returns once its context menu is up.
    /// 1.2s is the press duration already proven in `DuplicateEditPersistenceUITests`.
    private func openContextMenuOnSeededRow() {
        openHistoryTab()
        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "Seeded beer row should be present before long-pressing it")
        row.press(forDuration: 1.2)
    }

    // MARK: - Confirm path

    /// Long-press → Delete → confirm removes the row.
    func test_contextMenuDelete_confirm_removesRow() throws {
        launchApp()
        openContextMenuOnSeededRow()

        let menuDelete = app.buttons["Delete"]
        XCTAssertTrue(menuDelete.waitForExistence(timeout: 5),
                      "Context menu should offer Delete")
        menuDelete.tap()

        let confirm = confirmDeleteButton()
        XCTAssertTrue(confirm.waitForExistence(timeout: 5),
                      "Context-menu Delete must open a confirmation, not delete immediately")
        confirm.tap()

        XCTAssertTrue(waitForBeerRowCount(0, timeout: 5),
                      "Confirming should remove the only beer row")
    }

    // MARK: - Cancel path

    /// Long-press → Delete → dismiss without confirming keeps the row, still hittable.
    ///
    /// Anchored to a context menu, the `confirmationDialog` is presented as a
    /// popover, and in that presentation the system deliberately suppresses the
    /// explicit `.cancel`-role button — dismissing the popover IS the cancel
    /// affordance. (The `.cancel` button is still declared in
    /// `EventContextMenuModifier` for the presentations that do render one.)
    /// `EditDeleteConfirmationUITests.test_editDelete_dismissPopover_keepsEvent`
    /// pins the Edit sheet's equivalent path the same way, and this test reuses
    /// its dismissal gesture verbatim: a coordinate tap low-center of the window,
    /// which lands in the popover's dismiss region. No system-localized label is
    /// matched, so the non-English simulator locale is irrelevant (CLAUDE.md).
    func test_contextMenuDelete_cancel_keepsRow() throws {
        launchApp()
        openContextMenuOnSeededRow()

        let menuDelete = app.buttons["Delete"]
        XCTAssertTrue(menuDelete.waitForExistence(timeout: 5),
                      "Context menu should offer Delete")
        menuDelete.tap()

        let confirm = confirmDeleteButton()
        XCTAssertTrue(confirm.waitForExistence(timeout: 5),
                      "Context-menu Delete must open a confirmation, not delete immediately")

        // The popover is anchored to the row, so a tap low-center of the window
        // lands in the dimmed dismiss region below it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()

        XCTAssertFalse(confirmDeleteButton().waitForExistence(timeout: 3),
                       "Dismissing should close the confirmation without deleting")
        XCTAssertTrue(waitForBeerRowCount(1, timeout: 5),
                      "Dismissing the confirmation must NOT delete the drink")
        XCTAssertTrue(eventButton(containing: "500 ml").isHittable,
                      "The kept row must still be interactive after dismissing")
    }

    // MARK: - Duplicate is not gated

    /// Duplicate is non-destructive: no confirmation, and it adds a second row.
    func test_contextMenuDuplicate_isNotGatedByConfirmation() throws {
        launchApp()
        openContextMenuOnSeededRow()

        let duplicate = app.buttons["Duplicate"]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5),
                      "Context menu should offer Duplicate")
        duplicate.tap()

        XCTAssertFalse(confirmDeleteButton().waitForExistence(timeout: 3),
                       "Duplicate is non-destructive and must not be gated by a confirmation")
        XCTAssertTrue(waitForBeerRowCount(2, timeout: 5),
                      "Duplicate should immediately produce a second 500 ml beer row")
    }
}
