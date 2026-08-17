import XCTest

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

    private func openInsights() {
        let insightsTab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 10),
                      "Insights tab button should be visible after launch")
        insightsTab.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5),
                      "Insights screen navigation bar should appear")
    }

    private func heroTotalLabel() -> String {
        let candidate = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "std")
        ).firstMatch
        return candidate.exists ? candidate.label : ""
    }

    private func firstElement(withLabel label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", label)
        ).firstMatch
    }

    // MARK: - Area chart scrub follows/reverts the hero Total

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

    @objc private func sampleWeekdayCalloutDuringHold(_ timer: Timer) {
        let weekdayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        sawWeekdayCalloutDuringHold = app.descendants(matching: .any).matching(
            NSPredicate(format: "label IN %@", weekdayNames)
        ).firstMatch.exists
    }
}
