import XCTest

/// Ungated accessibility audit of the Insights tab (plan 11-19, audit groups A11Y-AUDIT-G04 and G05).
///
/// Audits the launch viewport with every audit type, the same coverage as the gated
/// `AccessibilityAuditUITests` Insights methods, at the default text size in light and dark
/// appearance and at AX5. It runs in the normal suite and every reported issue fails the test,
/// with two owner-approved exceptions, each recorded as a warning with its key and frame and
/// counted per variant:
/// - D11-30: `hitRegion` issues on the labelled day-mark elements of the area chart, which Swift
///   Charts cannot enlarge;
/// - D11-29 (standard and dark only): `contrast` and `textClipped` issues on the second row of the
///   Health Impact card, which lies under the system tab bar at the launch scroll position.
@MainActor
final class InsightsAccessibilityAuditUITests: XCTestCase {
    private static let areaChartLabel = "Alcohol Over Time"
    private var app: XCUIApplication?
    private var heroValueDuringHold = ""
    private var selectedDateDuringHold = ""

    override func setUpWithError() throws {
        // Collect every issue of a pass; each is its own failure.
        continueAfterFailure = true
    }

    /// Returns the app on Insights, or nil (after a recorded failure) when navigation fails, so a
    /// navigation failure never reaches the audit.
    private func launchAndOpenInsights(
        appearance: XCUIDevice.Appearance,
        contentSizeCategory: String?
    ) -> XCUIApplication? {
        pinAppearance(appearance)
        let app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(onboarding: false, contentSizeCategory: contentSizeCategory)
        app.launch()
        let tab = app.tabBars.buttons["Insights"]
        let hasTab = tab.waitForExistence(timeout: 15)
        XCTAssertTrue(hasTab, "Insights tab should exist")
        guard hasTab else { return nil }
        tab.tap()
        let shown = app.navigationBars["Insights"].waitForExistence(timeout: 10)
        XCTAssertTrue(shown, "Insights screen should be shown")
        return shown ? app : nil
    }

    func test_insights_standard_hasNoAuditIssues() throws {
        guard let app = launchAndOpenInsights(appearance: .light, contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(
            in: app, types: .all, screen: "Insights", variant: "standard",
            ignoreTabBarOccludedContent: true,
            ignoreTabBarElementlessContrast: true, // D11-31 (plan 0046 Task 7)
            exemptChartDayMarkHitRegionsOf: Self.areaChartLabel
        )
    }

    func test_insights_dark_hasNoAuditIssues() throws {
        guard let app = launchAndOpenInsights(appearance: .dark, contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(
            in: app, types: .all, screen: "Insights", variant: "dark",
            ignoreTabBarOccludedContent: true,
            ignoreTabBarElementlessContrast: true, // D11-31 (plan 0046 Task 7)
            exemptChartDayMarkHitRegionsOf: Self.areaChartLabel
        )
    }

    func test_insights_ax5_hasNoAuditIssues() throws {
        guard let app = launchAndOpenInsights(appearance: .light, contentSizeCategory: AuditLaunch.ax5Category) else {
            return
        }
        try assertNoAuditIssues(
            in: app, types: .all, screen: "Insights", variant: "ax5",
            exemptElementKeys: AuditBarControls.keys,
            exemptChartDayMarkHitRegionsOf: Self.areaChartLabel
        )
    }

    // MARK: - Chart day marks (audit group A11Y-AUDIT-G05)

    /// Every day mark of the area chart is one element described by its date and its value, the
    /// value is the same text the hero total shows while that day is scrubbed, and no element exposes
    /// the raw category key (a numeric timestamp). While a day is scrubbed, the hero shows its total
    /// and its date (plan 0046, D0046-9; no callout), and a mark's label equals that date.
    func test_insights_standard_markLabelMatchesSelectedDate() throws {
        guard let app = launchAndOpenInsights(appearance: .light, contentSizeCategory: nil) else { return }
        self.app = app
        let chart = app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", "Alcohol Over Time")
        ).firstMatch
        XCTAssertTrue(chart.waitForExistence(timeout: 10), "Area chart should be present on Insights")

        // One element per day; the daily-limit rule is its own element (plan 0046, D0046-9).
        let marks = chart.children(matching: .any).allElementsBoundByIndex
            .filter { $0.label != "Daily limit" }
        XCTAssertEqual(marks.count, 7, "The Week chart should expose one element per day")
        for mark in marks {
            XCTAssertNil(Double(mark.label), "A mark label must not be a number, got '\(mark.label)'")
            XCTAssertFalse(mark.label.isEmpty, "A mark must have a label")
            XCTAssertFalse((mark.value as? String ?? "").isEmpty, "Mark '\(mark.label)' must have a value")
        }

        heroValueDuringHold = ""
        let timer = Timer(timeInterval: 1.0, target: self, selector: #selector(sampleHeroValue),
                          userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        let start = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.5))
        let end = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.5))
        start.press(forDuration: 0.3, thenDragTo: end, withVelocity: .default, thenHoldForDuration: 2.0)

        XCTAssertFalse(heroValueDuringHold.isEmpty, "The hero total should show the scrubbed day's value")
        XCTAssertFalse(selectedDateDuringHold.isEmpty, "The hero should show the scrubbed day's date")
        let labels = marks.map(\.label)
        XCTAssertTrue(labels.contains(selectedDateDuringHold),
                      "A mark label should equal the date under the hero total '\(selectedDateDuringHold)', got \(labels)")
        let values = marks.map { $0.value as? String ?? "" }
        XCTAssertTrue(values.contains(heroValueDuringHold),
                      "A mark value should equal the scrubbed value '\(heroValueDuringHold)', got \(values)")

        let rawKey = "^[0-9]{6,}(\\.[0-9]+)?$"
        let rawKeyed = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier MATCHES %@ OR label MATCHES %@", rawKey, rawKey)
        )
        XCTAssertEqual(rawKeyed.count, 0, "No element may expose a raw timestamp as identifier or label")
    }

    @objc private func sampleHeroValue(_ timer: Timer) {
        let total = app?.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", " std")).firstMatch
        heroValueDuringHold = total?.exists == true ? (total?.label ?? "") : ""
        let date = app?.descendants(matching: .any)["insights.hero.selectedDate"]
        selectedDateDuringHold = date?.exists == true ? (date?.label ?? "") : ""
    }
}
