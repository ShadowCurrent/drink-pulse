import XCTest

/// Shared onboarding walk for UI tests (plan 0048). About You needs a sex before Continue works
/// (D0048-4), so every walk past it chooses one.
@MainActor
enum OnboardingWalk {
    /// Taps the sex option by its label ("Female" / "Male"). Matches the segmented control's
    /// segment at regular sizes; at accessibility sizes the choice rows carry the same label.
    static func chooseSex(_ label: String, in app: XCUIApplication,
                          file: StaticString = #filePath, line: UInt = #line) {
        let option = app.buttons[label]
        XCTAssertTrue(option.waitForExistence(timeout: 5),
                      "About You sex option '\(label)' should be shown", file: file, line: line)
        option.tap()
    }

    /// From a fresh onboarding launch: Get Started, choose a sex, Continue past About You and Your
    /// Guideline, and stop on Apple Health (its "Done" button shown).
    static func walkToHealth(in app: XCUIApplication, sex: String = "Female",
                             file: StaticString = #filePath, line: UInt = #line) {
        tap("Get Started", in: app, file: file, line: line)
        chooseSex(sex, in: app, file: file, line: line)
        tap("Continue", in: app, file: file, line: line)
        tap("Continue", in: app, file: file, line: line)
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5),
                      "Apple Health 'Done' should be shown", file: file, line: line)
    }

    private static func tap(_ label: String, in app: XCUIApplication, file: StaticString, line: UInt) {
        let button = app.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "'\(label)' should be shown", file: file, line: line)
        button.tap()
    }
}
