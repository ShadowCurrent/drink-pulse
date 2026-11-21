import XCTest

@MainActor
final class InsightsScrubUITests: XCTestCase {
    private var app: XCUIApplication!
    private var sampledDuringHold = ""
    private var sawSelectedDateDuringHold = false

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

        XCTAssertTrue(sawSelectedDateDuringHold,
                      "While scrubbing, the selected point's date should replace the trend line under the total")
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
        sawSelectedDateDuringHold = app.descendants(matching: .any)["insights.hero.selectedDate"].exists
    }
}
