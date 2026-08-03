import XCTest

/// Dynamic Type survival for the History row at the largest accessibility size
/// (finding C14-3). CLAUDE.md requires layouts to work up to AX5; the row was a
/// rigid three-column `HStack` with a hard-coded icon frame and divider inset and
/// no Dynamic Type handling at all, so this is the gate that keeps it honest.
///
/// **Why every assertion is made on the row element rather than on separate name
/// and amount elements:** `EventRow` applies `.accessibilityElement(children: .combine)`,
/// which collapses its `Text`s into one element — the individual labels are not
/// separately queryable from XCUITest. The combined row is the only addressable
/// element, so its accessibility label (content) and its frame (geometry) are what
/// can be objectively asserted. That is sufficient: label content proves nothing was
/// truncated out of what VoiceOver reads, and the frame proves the row grew, stayed
/// on screen and stayed hittable.
///
/// Locale rule (matching the rest of the History UI suite): the simulator's system
/// locale is Polish, so only app-rendered ENGLISH text and stable numeric values are
/// matched — never system-process UI or locale-formatted dates.
@MainActor
final class HistoryDynamicTypeUITests: XCTestCase {
    private var app: XCUIApplication!

    /// The volume marker carried by the `-dp_uitest` fixture's single seeded beer.
    private let volumeMarker = "500 ml"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// `UIContentSizeCategory.large` — the default. Note the value is the constant's
    /// RAW VALUE, not its symbol name.
    private let defaultCategory = "UICTContentSizeCategoryL"

    /// `UIContentSizeCategory.accessibilityExtraExtraExtraLarge` (AX5).
    ///
    /// It must be the raw value `UICTContentSizeCategoryAccessibilityXXXL`, verified
    /// against the iOS 26.5 simulator runtime's UIKitCore binary. Spelling it out as
    /// `UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge` — the symbol name
    /// with the raw-value prefix glued on — is NOT valid: UIKit silently ignores an
    /// unrecognised value, the app launches at the default size, and the whole suite
    /// then measures the default size while appearing to test AX5.
    private let ax5Category = "UICTContentSizeCategoryAccessibilityXXXL"

    /// Standard History fixture plus a forced content size category.
    /// `-UIPreferredContentSizeCategoryName` is a system-provided launch argument: it
    /// alters no app state and seeds no data.
    private func launchApp(contentSizeCategory: String) {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
            "-UIPreferredContentSizeCategoryName", contentSizeCategory,
        ]
        app.launch()
    }

    private func openHistoryTab() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 15),
                      "History tab should be accessible after launch")
        tab.tap()
    }

    /// The seeded row, addressed by the combined accessibility label's volume marker.
    private func seededRow() -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", volumeMarker)
        ).firstMatch
    }

    /// The row grows with the content size category, stays hittable, stays inside the
    /// window, keeps its spoken content and still opens the editor at AX5.
    func test_row_growsAndStaysHittable_atAX5() throws {
        // Pass 1 — default size, to establish the baseline height.
        launchApp(contentSizeCategory: defaultCategory)
        openHistoryTab()

        let defaultRow = seededRow()
        XCTAssertTrue(defaultRow.waitForExistence(timeout: 15),
                      "The seeded \(volumeMarker) row should exist at the default content size")
        let defaultHeight = defaultRow.frame.height
        app.terminate()

        // Pass 2 — AX5.
        launchApp(contentSizeCategory: ax5Category)
        openHistoryTab()

        let axRow = seededRow()
        XCTAssertTrue(axRow.waitForExistence(timeout: 15),
                      "The seeded \(volumeMarker) row should exist at AX5")
        let axFrame = axRow.frame

        // This assertion is also the suite's precondition check: if the launch
        // argument did not take effect, the two heights are equal and every
        // assertion below would be measuring the default size instead of AX5.
        // Do not relax it — a passing-but-meaningless suite is worse than a
        // failing one.
        XCTAssertGreaterThan(
            axFrame.height, defaultHeight,
            "The row must grow at AX5 (default \(defaultHeight), AX5 \(axFrame.height)). "
            + "Equal heights mean -UIPreferredContentSizeCategoryName did not take effect, "
            + "or the row is clipped to a fixed height."
        )

        XCTAssertTrue(axRow.isHittable, "The row must still be hittable at AX5")

        let window = app.windows.firstMatch
        XCTAssertLessThanOrEqual(
            axFrame.maxX, window.frame.maxX,
            "The row must not overflow the window horizontally at AX5 "
            + "(row maxX \(axFrame.maxX), window maxX \(window.frame.maxX))"
        )

        XCTAssertTrue(
            axRow.label.contains(volumeMarker),
            "The combined row label must still carry the volume at AX5 (got: \(axRow.label))"
        )

        axRow.tap()
        XCTAssertTrue(app.navigationBars["Edit Drink"].waitForExistence(timeout: 5),
                      "The row must still open the Edit Drink sheet at AX5")
    }
}
