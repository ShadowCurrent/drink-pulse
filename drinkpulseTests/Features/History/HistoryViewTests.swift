import Testing
import SwiftUI
@testable import drinkpulse

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
