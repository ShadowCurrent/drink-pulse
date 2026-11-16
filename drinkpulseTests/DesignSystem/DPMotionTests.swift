import SwiftUI
import Testing
@testable import drinkpulse

@Suite struct DPMotionTests {

    @Test func isReduced_returnsTrue_whenSystemReduceMotionIsOn() {
        #expect(DPMotion.isReduced(system: true, forced: false))
    }

    @Test func isReduced_returnsTrue_whenForced() {
        #expect(DPMotion.isReduced(system: false, forced: true))
    }

    @Test func isReduced_returnsFalse_whenNeitherIsSet() {
        #expect(!DPMotion.isReduced(system: false, forced: false))
    }

    @Test func animation_returnsNil_whenSystemReduceMotionIsOn() {
        #expect(DPMotion.animation(.easeOut, reduceMotion: true, forced: false) == nil)
    }

    @Test func animation_returnsNil_whenForced() {
        #expect(DPMotion.animation(.easeOut, reduceMotion: false, forced: true) == nil)
    }

    @Test func animation_passesThrough_whenNotReduced() {
        #expect(DPMotion.animation(.easeOut, reduceMotion: false, forced: false) == .easeOut)
    }

    @Test func animation_staysNil_whenInputIsNil() {
        #expect(DPMotion.animation(nil, reduceMotion: false, forced: false) == nil)
    }
}
