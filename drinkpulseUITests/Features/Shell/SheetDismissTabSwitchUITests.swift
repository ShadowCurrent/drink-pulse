import UIKit
import XCTest

/// Measurement harness for the owner-reported glass flicker (gap closure D1, plan 09-06): open Add
/// Drink, tap Cancel, switch to another tab, then sample frames after the tab landing. The tests
/// assert navigability only; the flash metric is emitted as `DP_FLASH_METRIC` lines (environment
/// file, standard output, and a test attachment) and is never asserted.
@MainActor
final class SheetDismissTabSwitchUITests: XCTestCase {
    private enum Mode: String {
        case sheet
        case control
        case emptyControl = "empty-control"
        case emptySheet = "empty-sheet"

        var opensSheet: Bool { self == .sheet || self == .emptySheet }
    }

    private enum Landing: String {
        case home = "Today"
        case insights = "Insights"

        var other: Landing { self == .home ? .insights : .home }
    }

    private static let gridWidth = 48
    private static let gridHeight = 96
    private static let sampleOffsets: [TimeInterval] = [0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0]
    private static let settledOffset: TimeInterval = 3.0
    private static let landingsPerTab = 10

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Tests

    /// Skipped unless `DP_RUN_FLASH_HARNESS=1` is set in the test runner environment (for xcodebuild:
    /// `TEST_RUNNER_DP_RUN_FLASH_HARNESS=1`): this sheet-mode cycle intermittently crashes the app on
    /// the iOS 27 simulator inside private Liquid Glass code. D1 is deferred out of Phase 09; see
    /// `.planning/todos/pending/2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md`. Remove
    /// the guard when D1 is fixed.
    func test_sheetCancelThenTabSwitch_cycle_staysNavigable_recordsFrameDeltas() throws {
        try skipUnlessFlashHarnessEnabled()
        launchApp(multiday: true)
        warmUp()
        runCycles(mode: .sheet, landings: 2 * Self.landingsPerTab)
    }

    func test_tabSwitchWithoutSheet_control_recordsFrameDeltas() throws {
        launchApp(multiday: true)
        warmUp()
        runCycles(mode: .control, landings: 2 * Self.landingsPerTab)
    }

    /// Held back for the conditional data-dependence measurement in plan 09-07; not part of the
    /// baseline run. Launches without a dataset argument, so only the profile is seeded.
    /// Also skipped unless `DP_RUN_FLASH_HARNESS=1`, for the same D1 simulator crash (its `.emptySheet`
    /// phase opens the sheet); see `.planning/todos/pending/2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md`.
    func test_sheetCancelThenTabSwitch_emptyStore_recordsFrameDeltas() throws {
        try skipUnlessFlashHarnessEnabled()
        launchApp(multiday: false)
        warmUp()
        runCycles(mode: .emptyControl, landings: 2 * Self.landingsPerTab)
        runCycles(mode: .emptySheet, landings: 2 * Self.landingsPerTab)
    }

    /// Sheet-mode runs crash the app on the iOS 27 simulator (deferred defect D1), so they run only
    /// on explicit opt-in. The skip reason is reported in the test results.
    private func skipUnlessFlashHarnessEnabled() throws {
        let enabled = ProcessInfo.processInfo.environment["DP_RUN_FLASH_HARNESS"] == "1"
        try XCTSkipUnless(
            enabled,
            "Deferred defect D1: the sheet cycle crashes the app on the iOS 27 simulator. "
                + "Set DP_RUN_FLASH_HARNESS=1 to run. See todo 2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal."
        )
    }

    // MARK: - Cycle routine

    private func launchApp(multiday: Bool) {
        app = XCUIApplication()
        app.launchArguments += ["-dp_onboarding_done", "YES", "-dp_uitest", "YES"]
        if multiday {
            app.launchArguments += ["-dp_uitest_dataset", "multiday"]
        }
        app.launch()
        XCTAssertTrue(app.tabBars.buttons[UITestTabs.today].waitForExistence(timeout: 10),
                      "Tab bar should be visible after launch")
    }

    /// Uncounted warm-up visit to Insights, then Home, so the measured landings start on Home.
    private func warmUp() {
        tapTab(.insights)
        tapTab(.home)
    }

    /// Alternates Insights and Home landings, starting from Home. A sheet-mode cycle opens Add
    /// Drink on the current tab and cancels it before the tab switch; a control cycle only
    /// switches tabs.
    private func runCycles(mode: Mode, landings: Int) {
        var current = Landing.home
        for cycle in 1...landings {
            let target = current.other
            if mode.opensSheet {
                openAndCancelAddDrink(on: current)
            }
            let tapTime = tapTab(target)
            let deltas = sampleDeltas(after: tapTime)
            record(mode: mode, landing: target, cycle: cycle, deltas: deltas)
            assertTabBarHittable()
            current = target
        }
    }

    private func openAndCancelAddDrink(on tab: Landing) {
        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "Add Drink button should be present on the \(tab.rawValue) tab")
        addButton.tap()

        let sheetBar = app.navigationBars["Add Drink"]
        XCTAssertTrue(sheetBar.waitForExistence(timeout: 5),
                      "Tapping Add Drink on the \(tab.rawValue) tab should present the sheet")
        let cancel = sheetBar.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "Add Drink should offer Cancel")
        cancel.tap()
        XCTAssertTrue(sheetBar.waitForNonExistence(timeout: 5),
                      "Cancel should dismiss the Add Drink sheet")
    }

    @discardableResult
    private func tapTab(_ landing: Landing) -> Date {
        let button = app.tabBars.buttons[landing.rawValue]
        XCTAssertTrue(button.waitForExistence(timeout: 5),
                      "\(landing.rawValue) tab button should exist")
        button.tap()
        let tapTime = Date()
        XCTAssertTrue(app.navigationBars[landing.rawValue].waitForExistence(timeout: 5),
                      "Selecting \(landing.rawValue) should show its navigation bar")
        return tapTime
    }

    private func assertTabBarHittable() {
        for name in [UITestTabs.today, "Insights"] {
            XCTAssertTrue(app.tabBars.buttons[name].isHittable,
                          "\(name) tab button should stay hittable")
        }
    }

    // MARK: - Frame sampling

    /// Eight samples at 0.6 ... 2.0 s after the tab tap, then a settled reference at 3.0 s. Each
    /// delta is the mean absolute grayscale difference to the reference on a 0 to 1 scale.
    private func sampleDeltas(after tapTime: Date) -> [Double] {
        var grids: [[UInt8]] = []
        for offset in Self.sampleOffsets + [Self.settledOffset] {
            let wait = tapTime.addingTimeInterval(offset).timeIntervalSinceNow
            if wait > 0 { Thread.sleep(forTimeInterval: wait) }
            grids.append(grayGrid(XCUIScreen.main.screenshot()))
        }
        guard let reference = grids.last else { return [] }
        return grids.dropLast().map { meanAbsoluteDifference($0, reference) }
    }

    /// 48 by 96 grayscale grid over the central band, excluding the top and bottom 12 percent so the
    /// status bar and tab bar do not contribute.
    private func grayGrid(_ screenshot: XCUIScreenshot) -> [UInt8] {
        guard let image = screenshot.image.cgImage else {
            XCTFail("Screenshot has no CGImage")
            return []
        }
        let top = Int(Double(image.height) * 0.12)
        let band = Int(Double(image.height) * 0.76)
        let crop = CGRect(x: 0, y: top, width: image.width, height: band)
        guard let cropped = image.cropping(to: crop) else {
            XCTFail("Screenshot band crop failed")
            return []
        }
        let width = Self.gridWidth
        let height = Self.gridHeight
        var pixels = [UInt8](repeating: 0, count: width * height)
        pixels.withUnsafeMutableBytes { raw in
            guard let context = CGContext(
                data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return }
            context.interpolationQuality = .high
            context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return pixels
    }

    private func meanAbsoluteDifference(_ lhs: [UInt8], _ rhs: [UInt8]) -> Double {
        guard !lhs.isEmpty, lhs.count == rhs.count else { return 1 }
        var total = 0
        for index in lhs.indices {
            total += abs(Int(lhs[index]) - Int(rhs[index]))
        }
        return Double(total) / Double(lhs.count) / 255.0
    }

    // MARK: - Metric emission

    private func record(mode: Mode, landing: Landing, cycle: Int, deltas: [Double]) {
        let maxDelta = deltas.max() ?? 1
        let joined = deltas.map { String(format: "%.5f", $0) }.joined(separator: ",")
        let line = "DP_FLASH_METRIC mode=\(mode.rawValue) landing=\(landing.rawValue) "
            + "cycle=\(cycle) maxDelta=\(String(format: "%.5f", maxDelta)) deltas=\(joined)"

        if let path = ProcessInfo.processInfo.environment["DP_FLASH_METRICS_PATH"], !path.isEmpty {
            append(line, toFileAt: path)
        }
        print(line)
        let attachment = XCTAttachment(string: line)
        attachment.name = "flash-\(mode.rawValue)-\(landing.rawValue)-\(cycle)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func append(_ line: String, toFileAt path: String) {
        let data = Data((line + "\n").utf8)
        if let handle = FileHandle(forWritingAtPath: path) {
            do {
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.close()
            } catch {
                XCTFail("Could not append metric line to \(path): \(error)")
            }
        } else if !FileManager.default.createFile(atPath: path, contents: data) {
            XCTFail("Could not create metrics file at \(path)")
        }
    }
}
