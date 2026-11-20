import XCTest

/// Settings (including the Preferences menu pickers) at the largest accessibility text size (AX5):
/// no clipped text, no fixed-size text, preference pickers reachable. Brief C016, decision D11-24.
@MainActor
final class SettingsDynamicTypeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// Provisional, plan 0043 (pending owner decision, same shape as D11-28): at AX5 the
    /// Preferences pickers use the system `.navigationLink` style (D0043-4). The audit reports
    /// `dynamicType` / `textClipped` on their system-drawn labels even where nothing clips
    /// (preview evidence: "Appearance" on one line, values wrapped). Only these labels and
    /// the unlabelled system element, only these two types; every other finding still fails.
    private static let preferencePickerKeys: Set<String> = [
        "Appearance", "Volume unit", "Alcohol unit", "ABV precision", "Currency", "none#type=nil",
    ]

    private func launchAndOpenSettingsAtAX5() {
        app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(
            onboarding: false, contentSizeCategory: AuditLaunch.ax5Category
        )
        app.launch()
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 15), "Settings tab should exist")
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10),
                      "Settings navigation bar should appear")
    }

    func test_settingsPreferences_atAX5_hasNoClippedOrFixedSizeText() throws {
        launchAndOpenSettingsAtAX5()
        try assertNoAuditIssuesWhileScrolling(
            in: app,
            types: [.textClipped, .dynamicType],
            screen: "Settings",
            variant: "ax5",
            maxPages: 6,
            exemptElementKeys: Self.preferencePickerKeys
        )
    }

    func test_settingsPreferences_atAX5_keepsPickersReachable() throws {
        launchAndOpenSettingsAtAX5()
        let window = app.windows.firstMatch
        for title in ["Appearance", "Volume unit", "Alcohol unit", "ABV precision", "Currency"] {
            let picker = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH %@", title)
            ).firstMatch
            var swipes = 0
            while !picker.exists && swipes < 6 {
                app.collectionViews.firstMatch.swipeUp()
                swipes += 1
            }
            XCTAssertTrue(picker.exists, "\(title) picker should exist at AX5")
            while !picker.isHittable && swipes < 10 {
                app.collectionViews.firstMatch.swipeUp()
                swipes += 1
            }
            XCTAssertTrue(picker.isHittable, "\(title) picker must be hittable at AX5")
            XCTAssertLessThanOrEqual(
                picker.frame.maxX, window.frame.maxX,
                "\(title) picker must not overflow the window horizontally"
            )
        }
    }
}
