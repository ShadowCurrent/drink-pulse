import Testing
import CoreGraphics
@testable import drinkpulse

/// First-run entrance motion values (plan 0048, D0048-12).
struct FirstRunRevealTests {
    @Test("offset is 24 pt while hidden with motion on")
    func offset_is24_whenHidden_andMotionOn() {
        #expect(FirstRunRevealMotion.offset(revealed: false, reduced: false) == 24)
    }

    @Test("offset is zero once revealed")
    func offset_isZero_whenRevealed() {
        #expect(FirstRunRevealMotion.offset(revealed: true, reduced: false) == 0)
    }

    @Test("offset is zero under Reduce Motion")
    func offset_isZero_whenReduced() {
        #expect(FirstRunRevealMotion.offset(revealed: false, reduced: true) == 0)
    }

    @Test("delay is 70 ms per order step")
    func delay_is70msPerOrder() {
        #expect(abs(FirstRunRevealMotion.delay(order: 3, reduced: false) - 0.21) < 1e-9)
        #expect(FirstRunRevealMotion.delay(order: 0, reduced: false) == 0)
    }

    @Test("delay is zero under Reduce Motion")
    func delay_isZero_whenReduced() {
        #expect(FirstRunRevealMotion.delay(order: 5, reduced: true) == 0)
    }
}
