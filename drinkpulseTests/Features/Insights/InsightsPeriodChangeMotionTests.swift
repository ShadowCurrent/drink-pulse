import Testing
import Foundation
@testable import drinkpulse

struct InsightsPeriodChangeMotionTests {
    private let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func isRapid_false_whenNoPreviousChange() {
        #expect(!InsightsPeriodChangeMotion.isRapid(now: t0, last: nil))
    }

    @Test func isRapid_true_whenWithinInterval() {
        let now = t0.addingTimeInterval(InsightsPeriodChangeMotion.rapidInterval / 2)
        #expect(InsightsPeriodChangeMotion.isRapid(now: now, last: t0))
    }

    @Test func isRapid_false_justPastTheInterval() {
        let now = t0.addingTimeInterval(InsightsPeriodChangeMotion.rapidInterval + 0.001)
        #expect(!InsightsPeriodChangeMotion.isRapid(now: now, last: t0))
    }

    @Test func isRapid_false_whenClockWentBackwards() {
        let now = t0.addingTimeInterval(-0.1)
        #expect(!InsightsPeriodChangeMotion.isRapid(now: now, last: t0))
    }

    @Test func animation_present_forSpacedChange() {
        let now = t0.addingTimeInterval(1)
        #expect(InsightsPeriodChangeMotion.animation(now: now, last: t0, reduceMotion: false) != nil)
    }

    @Test func animation_nil_forRapidChange() {
        let now = t0.addingTimeInterval(InsightsPeriodChangeMotion.rapidInterval / 2)
        #expect(InsightsPeriodChangeMotion.animation(now: now, last: t0, reduceMotion: false) == nil)
    }

    @Test func animation_nil_whenReduceMotionOn() {
        #expect(InsightsPeriodChangeMotion.animation(now: t0, last: nil, reduceMotion: true) == nil)
    }
}
