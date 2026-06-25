import XCTest

/// Shell navigation coverage (plan-0032, step 1).
///
/// Asserts the `RootShellView` `TabView` wiring end to end:
/// - all four tabs (Home / Insights / History / Settings) are reachable and
///   switching a tab swaps the visible screen (proven by each screen's own
///   `navigationBar`, which is distinct from the `tabBar` button of the same
///   English name);
/// - the "Add Drink" toolbar button is present on every tab and opening it
///   presents the Add Drink sheet;
/// - dismissing the Add Drink sheet returns to the tab it was opened from.
///
/// Locators key off app-rendered English text only (tab-bar buttons, nav-bar
/// titles, the "Add Drink" accessibility label). No accessibility identifiers
/// are required for the Shell. Launches with the gated `-dp_uitest` /
/// `-dp_onboarding_done` hooks so the app boots straight into the shell with a
/// seeded in-memory profile.
@MainActor
final class ShellNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    private let tabNames = ["Home", "Insights", "History", "Settings"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Builds and launches the app into the shell with the deterministic seed.
    /// Kept off the nonisolated `setUpWithError` override so the
    /// MainActor-isolated XCUI calls run on the MainActor.
    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
        ]
        app.launch()
    }

    // MARK: - Tabs reachable & switch content

    /// Taps each tab in turn and asserts the matching screen's navigation bar
    /// appears. The nav bar (`navigationBars[name]`) is a different element
    /// collection from the tab-bar button (`tabBars.buttons[name]`) of the same
    /// name, so its presence proves the content actually switched to that tab.
    func test_allFourTabs_areReachable_andSwitchContent() throws {
        launchApp()

        // Home is the default selection; confirm the shell finished launching.
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Home tab button should be visible after launch")

        for name in tabNames {
            let tabButton = app.tabBars.buttons[name]
            XCTAssertTrue(tabButton.waitForExistence(timeout: 5),
                          "\(name) tab button should exist in the tab bar")
            tabButton.tap()

            let screenNavBar = app.navigationBars[name]
            XCTAssertTrue(screenNavBar.waitForExistence(timeout: 5),
                          "Selecting the \(name) tab should show the \(name) "
                          + "screen's navigation bar")
        }
    }

    // MARK: - Add Drink button present on every tab

    /// On each tab the "Add Drink" toolbar button must be present and tapping it
    /// must present the Add Drink sheet. Each iteration cancels back so the next
    /// tab starts clean.
    func test_addDrinkButton_presentOnEveryTab_opensSheet() throws {
        launchApp()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10),
                      "Tab bar should be visible after launch")

        for name in tabNames {
            app.tabBars.buttons[name].tap()
            XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5),
                          "\(name) screen should be shown before opening Add Drink")

            let addButton = app.buttons["Add Drink"]
            XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                          "Add Drink button should be present on the \(name) tab")
            addButton.tap()

            let addNavBar = app.navigationBars["Add Drink"]
            XCTAssertTrue(addNavBar.waitForExistence(timeout: 5),
                          "Tapping Add Drink on the \(name) tab should present "
                          + "the Add Drink sheet")

            dismissAddDrinkSheet()
        }
    }

    // MARK: - Sheet dismiss returns to prior tab

    /// Opening Add Drink from a non-default tab (History) and dismissing it must
    /// land back on that same tab, not reset to Home.
    func test_dismissingAddDrink_returnsToPriorTab() throws {
        launchApp()

        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 10),
                      "History tab button should be visible after launch")
        historyTab.tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5),
                      "History screen should be shown before opening Add Drink")

        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "Add Drink button should be present on the History tab")
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5),
                      "Add Drink sheet should be presented from the History tab")

        dismissAddDrinkSheet()

        // The History screen's own nav bar must be back, and the Add Drink sheet
        // must be gone — proving we returned to the prior tab.
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5),
                      "Dismissing Add Drink should return to the History tab")
        XCTAssertFalse(app.navigationBars["Add Drink"].exists,
                       "Add Drink sheet should be dismissed")
    }

    // MARK: - Helpers

    /// Dismisses the presented Add Drink sheet via its app-rendered English
    /// "Cancel" toolbar button (locale-safe — an app string, not system UI).
    private func dismissAddDrinkSheet() {
        let cancelButton = app.navigationBars["Add Drink"].buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5),
                      "Add Drink sheet should have a Cancel button to dismiss it")
        cancelButton.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5),
                      "Add Drink sheet should be dismissed after tapping Cancel")
    }
}
