import XCTest

@MainActor
final class ExportUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += ["-dp_onboarding_done", "YES", "-dp_uitest", "YES"]
        app.launch()
    }

    func test_export_presentsSavePanel_andConfirmsOnSave() throws {
        launchApp()
        openDataSection()

        let exportButton = app.buttons["Export all data"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5),
                      "Export row should be visible in the Data section")
        exportButton.tap()

        let filenameField = app.textFields["DOCPicker.filenameTextField"]
        XCTAssertTrue(filenameField.waitForExistence(timeout: 8),
                      "The fileExporter save panel should present after tapping Export")
        let proposedName = filenameField.value as? String ?? ""
        XCTAssertTrue(proposedName.contains("drinkpulse-backup"),
                      "Save panel should propose the backup file name, got '\(proposedName)'")

        tapSaveButton()

        let successAlert = app.alerts["Export complete"]
        XCTAssertTrue(waitForSuccessConfirmingReplaceIfNeeded(successAlert),
                      "An 'Export complete' alert should appear after a successful save")
        successAlert.buttons.firstMatch.tap()
    }

    func test_export_dismissWithoutSaving_showsNoFailureAlert() throws {
        launchApp()
        openDataSection()
        app.buttons["Export all data"].tap()

        let filenameField = app.textFields["DOCPicker.filenameTextField"]
        XCTAssertTrue(filenameField.waitForExistence(timeout: 8),
                      "Save panel should present before dismissal")

        app.swipeDown(velocity: .fast)

        XCTAssertFalse(app.alerts["Export Failed"].waitForExistence(timeout: 3),
                       "Dismissing the save panel must not surface a failure alert")
        XCTAssertFalse(app.alerts["Export complete"].exists,
                       "Dismissing without saving must not surface a success alert")
    }

    // MARK: - Helpers

    private func openDataSection() {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10),
                      "Settings tab should exist after launch")
        settingsTab.tap()

        let exportButton = app.buttons["Export all data"]
        if !exportButton.waitForExistence(timeout: 3) {
            app.swipeUp()
        }
    }

    private func tapSaveButton() {
        let navBar = app.navigationBars["FullDocumentManagerViewControllerNavigationBar"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 3),
                      "Document picker navigation bar should be present")
        let buttons = navBar.buttons
        let save = buttons.element(boundBy: buttons.count - 1)
        XCTAssertTrue(save.exists, "Save button should exist in the picker nav bar")
        save.tap()
    }

    private func waitForSuccessConfirmingReplaceIfNeeded(_ successAlert: XCUIElement) -> Bool {
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if successAlert.exists { return true }
            let systemAlert = app.alerts.firstMatch
            if systemAlert.exists, !successAlert.exists, systemAlert.buttons.count > 1 {
                systemAlert.buttons.element(boundBy: 0).tap()
            }
            usleep(300_000)
        }
        return successAlert.exists
    }
}
