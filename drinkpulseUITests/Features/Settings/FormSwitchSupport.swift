import XCTest

extension XCTestCase {
    /// Taps the switch of a `Toggle` row in a `Form`. The row's switch element spans the whole
    /// row, so a plain `tap()` lands on the label in the middle, which does not toggle. Tap the
    /// inner switch when the row exposes one, else the trailing edge where the switch is drawn.
    @MainActor
    func tapSwitch(_ toggle: XCUIElement) {
        let inner = toggle.switches.firstMatch
        if inner.exists {
            inner.tap()
        } else {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        }
    }
}
