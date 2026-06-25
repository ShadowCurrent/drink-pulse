import XCTest

/// End-to-end UI test for the manual backup export flow (Settings → Data →
/// Export). Verifies the `.fileExporter` save panel presents without freezing
/// the UI, that the proposed filename is the backup name, and that completing a
/// save surfaces the "Export complete" alert.
///
/// Onboarding is skipped via a launch argument that overrides the
/// `dp_onboarding_done` default through the NSArgumentDomain — no app-side test
/// hook required.
///
/// Locale independence: the save panel runs in a separate process and its
/// controls are localized to the *simulator's* system language. The test never
/// matches the picker by a localized label — it keys off the stable
/// `DOCPicker.filenameTextField` identifier, the document-manager nav bar's
/// trailing (Save) button, and (for the replace prompt) button position rather
/// than text. The app's own alerts are English (the app is en-only), so
/// asserting "Export complete" by title is safe.
@MainActor
final class ExportUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Builds and launches the app. Kept off the nonisolated `setUpWithError`
    /// override so the MainActor-isolated XCUI calls run on the MainActor.
    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += ["-dp_onboarding_done", "YES"]
        app.launch()
    }

    /// Happy path: open Settings, tap Export, confirm the save panel presents
    /// with the backup filename (proves no main-thread freeze on tap), save, and
    /// assert the success alert. Robust to repeated same-day runs: if the dated
    /// backup file already exists, iOS asks to replace and the test confirms it.
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

    /// Probe: dismissing the save panel without saving (swipe down) must NOT
    /// surface the failure alert — `userCancelled` is treated as a no-op.
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

    /// Taps the picker's confirm (Save) button. Its label is localized, so we
    /// target the trailing button of the document-manager nav bar instead.
    private func tapSaveButton() {
        let navBar = app.navigationBars["FullDocumentManagerViewControllerNavigationBar"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 3),
                      "Document picker navigation bar should be present")
        let buttons = navBar.buttons
        let save = buttons.element(boundBy: buttons.count - 1)
        XCTAssertTrue(save.exists, "Save button should exist in the picker nav bar")
        save.tap()
    }

    /// Waits for the app's success alert. If the dated backup already exists,
    /// iOS first shows a "Replace Existing Items?" system alert; its confirm
    /// ("Replace") is the first button regardless of locale, so we tap by index.
    private func waitForSuccessConfirmingReplaceIfNeeded(_ successAlert: XCUIElement) -> Bool {
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if successAlert.exists { return true }
            let systemAlert = app.alerts.firstMatch
            // Any alert that isn't our success alert is the replace prompt.
            if systemAlert.exists, !successAlert.exists, systemAlert.buttons.count > 1 {
                systemAlert.buttons.element(boundBy: 0).tap()
            }
            usleep(300_000)
        }
        return successAlert.exists
    }
}
