import XCTest

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

    func test_editDelete_confirm_removesEventAndDismisses() throws {
        launchApp()
        let editNav = openEditSheet()

        editNav.buttons["Delete"].tap()

        XCTAssertTrue(app.staticTexts["Delete this drink?"].waitForExistence(timeout: 5),
                      "Tapping the trash button should open the delete-confirmation popover")

        let confirm = app.buttons["confirmDeleteButton"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5),
                      "Popover should expose the confirm Delete button")
        confirm.tap()

        XCTAssertTrue(app.navigationBars["Edit Drink"].waitForNonExistence(timeout: 5),
                      "Confirming delete should dismiss the Edit Drink sheet")
        XCTAssertTrue(waitForBeerRowCount(0, timeout: 5),
                      "Confirming delete should remove the only beer row")
    }

    // MARK: - Cancel glyph

    func test_editSheet_cancel_rendersAsCloseGlyph() throws {
        launchApp()
        let editNav = openEditSheet()

        let cancel = editNav.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "Edit sheet should offer Cancel")
        XCTAssertLessThan(abs(cancel.frame.width - cancel.frame.height), 4,
                          "Cancel should render as the square X glyph, like Add Drink, not a text label")
    }

    // MARK: - Trailing toolbar grouping

    /// HIG Toolbars: keep text-labelled actions (Save) apart from symbol actions (trash), so the
    /// destructive trash never shares Save's glass capsule.
    func test_editSheet_trashAndSave_sitInSeparateCapsules() throws {
        launchApp()
        let editNav = openEditSheet()

        let trash = editNav.buttons["Delete"]
        let save = editNav.buttons["Save"]
        XCTAssertTrue(trash.waitForExistence(timeout: 5), "Edit sheet should offer the trash button")
        XCTAssertTrue(save.waitForExistence(timeout: 5), "Edit sheet should offer Save")
        // The accessibility tree cannot show glass grouping, and a shared capsule still leaves a
        // gap between the two frames, so compare pixels: the gap between the buttons must show
        // the sheet background (as left of the trash), not the capsule's glass.
        let shot = XCUIScreen.main.screenshot().image
        let midY = save.frame.midY
        let gapColor = pixel(in: shot, at: CGPoint(x: (trash.frame.maxX + save.frame.minX) / 2, y: midY))
        let backgroundColor = pixel(in: shot, at: CGPoint(x: trash.frame.minX - 20, y: midY))
        let difference = zip(gapColor, backgroundColor).map { abs(Int($0) - Int($1)) }.max() ?? 0
        XCTAssertLessThanOrEqual(difference, 8,
                                 "Trash and Save should sit in separate capsules (gap \(gapColor), background \(backgroundColor))")
    }

    /// RGB bytes of the screenshot pixel at a point in screen coordinates.
    private func pixel(in image: UIImage, at point: CGPoint) -> [UInt8] {
        guard let cgImage = image.cgImage else { return [] }
        let scale = CGFloat(cgImage.width) / image.size.width
        var rgba = [UInt8](repeating: 0, count: 4)
        let context = CGContext(data: &rgba, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(cgImage, in: CGRect(x: -point.x * scale, y: -(CGFloat(cgImage.height) - point.y * scale),
                                          width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
        return Array(rgba.prefix(3))
    }

    // MARK: - Cancel path

    func test_editDelete_dismissPopover_keepsEvent() throws {
        launchApp()
        let editNav = openEditSheet()

        editNav.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Delete this drink?"].waitForExistence(timeout: 5),
                      "Tapping the trash button should open the delete-confirmation popover")

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()
        XCTAssertFalse(app.staticTexts["Delete this drink?"].waitForExistence(timeout: 3),
                       "Tapping outside should dismiss the popover without deleting")

        editNav.buttons["Cancel"].tap()
        XCTAssertTrue(waitForBeerRowCount(1, timeout: 5),
                      "Dismissing the popover must NOT delete the event")
    }
}
