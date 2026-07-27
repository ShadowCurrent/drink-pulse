import XCTest

/// Regression coverage for STARTUP-01/D-01/D-03 (ADR-0012): `onboardingDone`
/// is the *sole* authoritative source of truth for the `RootShellView` vs.
/// `OnboardingView` gate. A live `@Query profiles` result must never flip it.
///
/// Complements the existing onboarding UI test files
/// (`OnboardingFlowUITests`, `OnboardingLocaleDefaultUITests`,
/// `OnboardingHealthStepUITests`, `OnboardingWeeklySummaryUITests`), which
/// cover the onboarding walkthrough itself and are unaffected by this change.
///
/// All assertions key off the app's own English strings and tab bar — never
/// system-process UI or locale-formatted numbers (the simulator system
/// locale is Polish; the app's strings are English-only, so app text is
/// safe to match).
///
/// Launch uses the existing gated hooks:
///   - `-dp_uitest YES`                          → in-memory store.
///   - `-dp_onboarding_done YES`                  → starts already onboarded.
///   - `-dp_uitest_delete_profile_midsession YES` → deletes the seeded
///     profile on `RootShellView.onAppear`, simulating an out-of-band
///     mid-session profile deletion.
@MainActor
final class OnboardingAuthorityUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Deleting the only `UserProfile` mid-session must NOT revert the app
    /// from `RootShellView` back to `OnboardingView` — `onboardingDone`
    /// alone gates the view, independent of `@Query profiles` state.
    func test_midSessionProfileDeletion_staysOnRootShell_doesNotResetToOnboarding() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_onboarding_done", "YES",
            "-dp_uitest_delete_profile_midsession", "YES",
        ]
        app.launch()

        // Stays on RootShellView: Home tab present...
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Home tab should remain present after a mid-session " +
                      "profile deletion — onboardingDone alone gates the shell")

        // ...and never falls back to OnboardingView's Welcome step.
        XCTAssertFalse(app.buttons["Get Started"].exists,
                       "OnboardingView's 'Get Started' button must never " +
                       "reappear after a mid-session profile deletion")
    }
}
