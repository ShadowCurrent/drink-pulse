import Testing
import SwiftUI
@testable import drinkpulse

/// Unit tests for `HistoryView.edge(forEntering:)`, the pure, stateless
/// direction-mapping function that drives the List/Calendar directional
/// transition (HIST-01, D-01, D-03). This function reads only the
/// destination segment and never diffs against the previous segment,
/// which structurally eliminates the alternating-switch direction-lag bug
/// documented in Apple Developer Forums thread 749606 (RESEARCH.md Pitfall 1).
@MainActor
struct HistoryViewTests {

    @Test func edgeForEntering_calendar_returnsTrailing() {
        #expect(HistoryView.edge(forEntering: .calendar) == .trailing)
    }

    @Test func edgeForEntering_list_returnsLeading() {
        #expect(HistoryView.edge(forEntering: .list) == .leading)
    }

    @Test func shouldAnimate_whenReduceMotionOff_returnsTrue() {
        #expect(HistoryView.shouldAnimate(reduceMotion: false) == true)
    }

    @Test func shouldAnimate_whenReduceMotionOn_returnsFalse() {
        #expect(HistoryView.shouldAnimate(reduceMotion: true) == false)
    }
}
