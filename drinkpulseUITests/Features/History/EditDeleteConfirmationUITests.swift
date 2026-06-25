import XCTest

/// UI coverage for the Edit Drink sheet's delete-confirmation popover.
///
/// The destructive trash button in the Edit sheet's nav bar opens a popover
/// (anchored to the button) carrying a confirm "Delete" button. This pins the
/// real flow: trash → popover → confirm removes the event and dismisses the
/// sheet; trash → popover → dismiss-without-confirm keeps the event.
///
/// Disambiguation: BOTH the toolbar trash and the popover confirm expose the
/// English label "Delete". The toolbar one is reached via the "Edit Drink"
/// nav bar; the popover confirm carries the stable identifier
/// `confirmDeleteButton`.
///
/// Seed: `-dp_uitest YES` inserts a single "Today" 500 ml 5% beer in an
/// in-memory store; the List row subtitle renders "500 ml" in metric.
@MainActor
final class EditDeleteConfirmationUITests: XCTestCase {
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

    private func waitForBeerRowCount(_ expected: Int, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if beerRowCount() == expected { return true }
            usleep(150_000)
        }
        return beerRowCount() == expected
    }

    /// Opens the Edit Drink sheet for the seeded beer row and returns its nav bar.
    private func openEditSheet() -> XCUIElement {
        openHistoryTab()
        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "Seeded beer row should be present before editing")
        row.tap()
        let editNav = app.navigationBars["Edit Drink"]
        XCTAssertTrue(editNav.waitForExistence(timeout: 5),
                      "Tapping the row should open the Edit Drink sheet")
        return editNav
    }

    // MARK: - Confirm path

    /// Trash → popover → confirm "Delete" removes the event and dismisses the
    /// sheet, leaving History empty.
    func test_editDelete_confirm_removesEventAndDismisses() throws {
        launchApp()
        let editNav = openEditSheet()

        // Open the confirmation popover via the nav-bar trash button.
        editNav.buttons["Delete"].tap()

        // The popover surfaces the confirmation title.
        XCTAssertTrue(app.staticTexts["Delete this drink?"].waitForExistence(timeout: 5),
                      "Tapping the trash button should open the delete-confirmation popover")

        // Confirm via the identified popover button (NOT the toolbar trash).
        let confirm = app.buttons["confirmDeleteButton"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5),
                      "Popover should expose the confirm Delete button")
        confirm.tap()

        // Sheet dismisses and the only beer row is gone.
        XCTAssertFalse(app.navigationBars["Edit Drink"].waitForExistence(timeout: 5),
                       "Confirming delete should dismiss the Edit Drink sheet")
        XCTAssertTrue(waitForBeerRowCount(0, timeout: 5),
                      "Confirming delete should remove the only beer row")
    }

    // MARK: - Cancel path

    /// Trash → popover → dismiss without confirming (tap outside) keeps the event
    /// and the sheet stays editable.
    func test_editDelete_dismissPopover_keepsEvent() throws {
        launchApp()
        let editNav = openEditSheet()

        editNav.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Delete this drink?"].waitForExistence(timeout: 5),
                      "Tapping the trash button should open the delete-confirmation popover")

        // Dismiss the popover by tapping outside it. The popover is anchored to
        // the top-right trash button, so a tap low-center of the window lands in
        // the dimmed passthrough area (the nav bar itself is obscured and has no
        // valid hit point while the popover is up).
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()
        XCTAssertFalse(app.staticTexts["Delete this drink?"].waitForExistence(timeout: 3),
                       "Tapping outside should dismiss the popover without deleting")

        // Cancel out of the still-present sheet and verify the row survived.
        editNav.buttons["Cancel"].tap()
        XCTAssertTrue(waitForBeerRowCount(1, timeout: 5),
                      "Dismissing the popover must NOT delete the event")
    }
}
