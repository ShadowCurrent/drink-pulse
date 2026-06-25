import XCTest

/// Fresh onboarding picks `unitSystem` from the device locale (plan-0030).
/// Asserted by driving onboarding to completion and checking that the Settings
/// volume-unit picker reflects the expected default.
///
/// Two sub-tests cover the two most important locale mappings:
///   - `en_US` → US fl oz  (Locale.MeasurementSystem.us → .usCustomary)
///   - `de_DE` → Millilitres (Locale.MeasurementSystem.metric → .metric)
///
/// Note on `en_GB`: on iOS 26 the simulator reports
/// `Locale.current.measurementSystem` as `.metric` for the `en_GB` locale
/// (Foundation changed the UK measurement-system classification from `.uk`
/// to metric in iOS 26). The `OnboardingViewModel.unitSystem(for:)` unit test
/// exercises the `.uk → .imperial` mapping directly via
/// `Locale(identifier: "en_GB")` which does return `.uk` on the host macOS;
/// the UI-test layer therefore only needs to cover the two mappings that are
/// stable in the iOS 26 simulator (US and metric).
@MainActor
final class OnboardingLocaleDefaultUITests: XCTestCase {

    /// `en_US` locale should default to US fl oz after onboarding.
    func test_onboarding_enUS_defaultsToUsFlOz() throws {
        let app = makeApp(locale: "en_US")
        app.launch()
        driveOnboardingToCompletion(in: app)
        assertVolumeUnitInSettings(app: app, contains: "US fl oz",
                                   failMessage: "en_US locale should default to 'US fl oz' in Settings")
    }

    /// `de_DE` locale (metric) should default to Millilitres after onboarding.
    func test_onboarding_deDE_defaultsToMillilitres() throws {
        let app = makeApp(locale: "de_DE")
        app.launch()
        driveOnboardingToCompletion(in: app)
        assertVolumeUnitInSettings(app: app, contains: "Millilitres",
                                   failMessage: "de_DE locale should default to 'Millilitres (ml)' in Settings")
    }

    // MARK: - Helpers

    private func makeApp(locale: String) -> XCUIApplication {
        let a = XCUIApplication()
        // -dp_force_onboarding YES tells the app to ignore the AppStorage
        // onboardingDone flag and always show OnboardingView. This avoids the
        // NSArgumentDomain-blocks-UserDefaults-write problem: if we used
        // "-dp_onboarding_done NO", writing onboardingDone=true inside the app
        // would be silently overridden by NSArgumentDomain, so the app would
        // never transition to RootShellView. The force flag is a separate,
        // app-managed one-time gate that lets the transition happen normally.
        // In-memory store so no leftover SwiftData state interferes.
        a.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_force_onboarding", "YES",
            "-AppleLocale", locale,
            "-AppleLanguages", "(en)",
        ]
        return a
    }

    /// Drives through all three onboarding steps using the app's English labels
    /// (stable regardless of simulator system locale).
    ///
    /// Flow (from OnboardingView): Welcome → Profile → Guidelines → done.
    /// - Welcome: CTA = "Get Started" (onboarding.welcome.cta)
    /// - Profile: continue = "Continue" (onboarding.step.continue)
    /// - Guidelines: done = "Get Started" (onboarding.guideline.done)
    private func driveOnboardingToCompletion(in app: XCUIApplication) {
        continueAfterFailure = false

        // Step 1: Welcome — tap "Get Started".
        let welcomeGetStarted = app.buttons["Get Started"]
        XCTAssertTrue(welcomeGetStarted.waitForExistence(timeout: 10),
                      "Welcome step 'Get Started' button should appear at launch")
        welcomeGetStarted.tap()

        // Step 2: Profile — tap "Continue" (onboarding.step.continue).
        let profileContinue = app.buttons["Continue"]
        XCTAssertTrue(profileContinue.waitForExistence(timeout: 5),
                      "Profile step 'Continue' button should appear")
        profileContinue.tap()

        // Step 3: Guidelines — tap "Get Started" (onboarding.guideline.done).
        let guidelineDone = app.buttons["Get Started"]
        XCTAssertTrue(guidelineDone.waitForExistence(timeout: 5),
                      "Guideline step 'Get Started' button should appear")
        guidelineDone.tap()

        // After completion RootShellView shows the tab bar.
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10),
                      "Tab bar should appear after onboarding completion")
    }

    /// Opens Settings and asserts the volume-unit picker shows the expected label.
    private func assertVolumeUnitInSettings(app: XCUIApplication,
                                            contains label: String,
                                            failMessage: String) {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5),
                      "Settings tab must be reachable")
        settingsTab.tap()

        // The Volume unit Picker (.pickerStyle(.menu)) is a Button whose label
        // reflects the current selection.
        let volumeUnitPicker = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Millilitres' OR label CONTAINS 'fl oz'")
        ).firstMatch
        XCTAssertTrue(volumeUnitPicker.waitForExistence(timeout: 5),
                      "Volume unit picker should be visible in Settings")
        XCTAssertTrue(volumeUnitPicker.label.contains(label),
                      "\(failMessage). Picker label was: '\(volumeUnitPicker.label)'")
    }
}
