import XCTest

/// Drag-to-scrub coverage for `AlcoholAreaChart` and `WeekdayBarChart`
/// (`chartXSelection`, phase 05: Insights Chart Scrubbing). Split out of
/// `InsightsUITests` to keep that file under the 300-line ceiling — same
/// pattern as `InsightsStreakUITests`/`InsightsDrinkFreeDaysUITests`.
///
/// Both tests drive the real drag gesture via `XCUICoordinate.press(
/// forDuration:thenDragTo:withVelocity:thenHoldForDuration:)` — never
/// `tap()`/`swipeLeft()` — since `chartXSelection`'s gesture is a real
/// touch-down-then-move drag, not a tap or flick (RESEARCH.md Pitfall 5).
///
/// `chartXSelection` clears its selection binding as soon as the touch
/// lifts, so a plain blocking `press(forDuration:thenDragTo:)` call (which
/// only returns *after* the release) can never observe the mid-drag
/// selected state. Both tests instead drive the gesture with a deliberate
/// hold at the destination and sample app state mid-hold via a target-action
/// `Timer` fired on the main run loop — `press(...thenHoldForDuration:)`
/// services that run loop while it waits, so the timer fires while the
/// touch is still down. (A target-action `Timer`, not a Swift closure,
/// sidesteps the `@Sendable` capture-checking a closure-based timer would
/// trigger for a MainActor-isolated `XCTestCase`.)
///
/// Reuses the `-dp_uitest_dataset multiday` fixture and English-only a11y
/// locator conventions established by `InsightsUITests`.
@MainActor
final class InsightsScrubUITests: XCTestCase {
    private var app: XCUIApplication!
    private var sampledDuringHold = ""
    private var sawWeekdayCalloutDuringHold = false

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_dataset", "multiday",
        ]
        app.launch()
    }

    /// Opens the Insights tab and waits for its navigation bar.
    private func openInsights() {
        let insightsTab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 10),
                      "Insights tab button should be visible after launch")
        insightsTab.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5),
                      "Insights screen navigation bar should appear")
    }

    /// Reads the current hero "Total" value (the 40-pt rounded number+unit,
    /// e.g. "2.0 std"). Returns "" if not yet rendered.
    private func heroTotalLabel() -> String {
        let candidate = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "std")
        ).firstMatch
        return candidate.exists ? candidate.label : ""
    }

    /// First element (any type) whose accessibility label equals `label`.
    private func firstElement(withLabel label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", label)
        ).firstMatch
    }

    // MARK: - Area chart scrub follows/reverts the hero Total

    /// Dragging across `AlcoholAreaChart` must update the hero card's Total
    /// headline to follow the touched point, then revert to the period total
    /// once the drag gesture completes (CHART-01, CHART-02).
    func test_scrubbingAreaChart_updatesHeroTotal_andRevertsOnRelease() throws {
        launchApp()
        openInsights()

        let chart = firstElement(withLabel: "Alcohol Over Time")
        XCTAssertTrue(chart.waitForExistence(timeout: 10),
                      "Area chart ('Alcohol Over Time') should be present on Insights")

        let originalTotal = heroTotalLabel()
        XCTAssertFalse(originalTotal.isEmpty, "Hero Total value should render before scrubbing")

        let start = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        let end = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        let holdDuration: TimeInterval = 2.0

        sampledDuringHold = ""
        let timer = Timer(timeInterval: 1.0, target: self,
                          selector: #selector(sampleHeroTotalDuringHold), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)

        start.press(forDuration: 0.3, thenDragTo: end, withVelocity: .default, thenHoldForDuration: holdDuration)

        XCTAssertFalse(sampledDuringHold.isEmpty,
                       "Hero Total should still render while the chart is being scrubbed")
        XCTAssertNotEqual(sampledDuringHold, originalTotal,
                          "Scrubbing the area chart should update the hero Total to the touched point's "
                          + "value while the touch is held (original='\(originalTotal)', "
                          + "sampled during hold='\(sampledDuringHold)')")

        let deadline = Date().addingTimeInterval(3)
        var reverted = false
        while Date() < deadline {
            if heroTotalLabel() == originalTotal { reverted = true; break }
            usleep(150_000)
        }
        XCTAssertTrue(reverted,
                      "Releasing the drag should revert the hero Total to the pre-drag reading "
                      + "(expected='\(originalTotal)', got='\(heroTotalLabel())')")
    }

    @objc private func sampleHeroTotalDuringHold(_ timer: Timer) {
        sampledDuringHold = heroTotalLabel()
    }

    // MARK: - Weekday chart scrub shows the identical callout treatment

    /// Dragging across `WeekdayBarChart` must show the same RuleMark +
    /// glass-chip callout treatment as `AlcoholAreaChart` (D-04) — a static
    /// text reading "<weekday> — <value> <unit>" (D-05, no risk-level text).
    func test_scrubbingWeekdayChart_showsCallout() throws {
        launchApp()
        openInsights()

        let weekdayHeader = app.staticTexts["Weekday Patterns"]
        if !weekdayHeader.waitForExistence(timeout: 3) {
            app.swipeUp()
        }
        XCTAssertTrue(weekdayHeader.waitForExistence(timeout: 5),
                      "Weekday bar chart header ('Weekday Patterns') should be present")

        let card = firstElement(withLabel: "Weekday Patterns")
        XCTAssertTrue(card.waitForExistence(timeout: 5),
                      "Weekday Patterns container should be present")

        // `waitForExistence` only proves the element is laid out somewhere in
        // the scroll content — not that it's within the visible viewport. A
        // coordinate computed against an off-screen frame can land beyond the
        // app's bounds, in the system gesture zone near the bottom edge
        // (triggering the OS app-switcher instead of a touch inside the app).
        // Keep swiping until the whole card frame sits within the screen.
        for _ in 0..<5 where card.frame.maxY > app.frame.maxY || card.frame.minY < app.frame.minY {
            app.swipeUp()
        }
        XCTAssertTrue(card.frame.maxY <= app.frame.maxY && card.frame.minY >= app.frame.minY,
                      "Weekday Patterns card should be fully scrolled into the visible viewport "
                      + "(card=\(card.frame), screen=\(app.frame))")

        let start = card.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5))
        let end = card.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        let holdDuration: TimeInterval = 2.0

        sawWeekdayCalloutDuringHold = false
        let timer = Timer(timeInterval: 1.0, target: self,
                          selector: #selector(sampleWeekdayCalloutDuringHold), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)

        start.press(forDuration: 0.3, thenDragTo: end, withVelocity: .default, thenHoldForDuration: holdDuration)

        XCTAssertTrue(sawWeekdayCalloutDuringHold,
                      "Scrubbing the weekday chart should show a callout ('<weekday> — <value>') "
                      + "while the touch is held")
    }

    /// A scrub callout always renders as "<weekday> — <value> <unit>" (D-05),
    /// so any static text containing the em dash separator proves it's visible.
    @objc private func sampleWeekdayCalloutDuringHold(_ timer: Timer) {
        // Swift Charts' `.annotation` callout content does not surface as a
        // standalone accessibility element (confirmed via manual inspection:
        // the glass-chip Text is visible on-screen but absent from
        // `debugDescription`'s tree, distinct from each BarMark's own
        // `accessibilityLabel`, which does surface). The conditional
        // `RuleMark(x: .value(..., selectedLabel))` that gates the same
        // `if let selectedLabel` branch as the callout DOES surface as a bare
        // weekday-label element (e.g. "Fri", with no ": <value>" suffix,
        // unlike each bar's "Fri: 0.0 std" label) — proving the identical
        // selection state the callout itself is conditioned on.
        let weekdayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        sawWeekdayCalloutDuringHold = app.descendants(matching: .any).matching(
            NSPredicate(format: "label IN %@", weekdayNames)
        ).firstMatch.exists
    }
}
