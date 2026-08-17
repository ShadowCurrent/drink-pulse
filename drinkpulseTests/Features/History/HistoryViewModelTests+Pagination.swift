import Testing
import Foundation
@testable import drinkpulse

@MainActor
extension HistoryViewModelTests {

    func gregorian() -> Calendar { Calendar(identifier: .gregorian) }

    @Test func hasMoreToLoad_nilEarliest_returnsFalse() {
        #expect(vm.hasMoreToLoad(earliest: nil, windowStart: .now) == false)
    }

    @Test func hasMoreToLoad_earliestBeforeWindow_returnsTrue() {
        let window = Date(timeIntervalSince1970: 1_700_000_000)
        let earliest = window.addingTimeInterval(-86_400)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == true)
    }

    @Test func hasMoreToLoad_earliestInsideWindow_returnsFalse() {
        let window = Date(timeIntervalSince1970: 1_700_000_000)
        let earliest = window.addingTimeInterval(86_400)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == false)
    }

    @Test func hasMoreToLoad_earliestEqualsWindow_returnsFalse() {
        let window = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(vm.hasMoreToLoad(earliest: window, windowStart: window) == false)
    }

    @Test func initialWindowStart_isOnePageBeforeNow() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let start = vm.initialWindowStart(from: now, calendar: gregorian())
        let expected = gregorian().date(byAdding: .day, value: -HistoryViewModel.listPageDays, to: now)
        #expect(start == expected)
    }

    @Test func initialWindowStart_isInThePast() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(vm.initialWindowStart(from: now, calendar: gregorian()) < now)
    }

    @Test func extendedWindowStart_movesBackOnePage() {
        let current = Date(timeIntervalSince1970: 1_700_000_000)
        let extended = vm.extendedWindowStart(from: current, calendar: gregorian())
        let expected = gregorian().date(byAdding: .day, value: -HistoryViewModel.listPageDays, to: current)
        #expect(extended == expected)
    }

    @Test func extendedWindowStart_isEarlierThanCurrent() {
        let current = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(vm.extendedWindowStart(from: current, calendar: gregorian()) < current)
    }

    @Test func extendedWindowStart_repeatedCalls_keepMovingBack() {
        let cal = gregorian()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let once = vm.extendedWindowStart(from: start, calendar: cal)
        let twice = vm.extendedWindowStart(from: once, calendar: cal)
        #expect(twice < once)
        let expected = cal.date(byAdding: .day, value: -2 * HistoryViewModel.listPageDays, to: start)
        #expect(twice == expected)
    }

    @Test func extendedWindowThenHasMore_eventuallyCoversEarliest() {
        let cal = gregorian()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let earliest = cal.date(byAdding: .day, value: -20, to: now)!
        var window = vm.initialWindowStart(from: now, calendar: cal)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == true)
        window = vm.extendedWindowStart(from: window, calendar: cal)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == true)
        window = vm.extendedWindowStart(from: window, calendar: cal)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == false)
    }

    // MARK: - extendedWindowStart(from:earliest:) — gap-collapsing overload

    @Test func extendedWindowStart_withEarliest_collapsesMultiPageGapInOneCall() {
        let cal = gregorian()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let earliest = cal.date(byAdding: .day, value: -20, to: now)!
        let window = vm.initialWindowStart(from: now, calendar: cal)

        let extended = vm.extendedWindowStart(from: window, earliest: earliest, calendar: cal)

        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: extended) == false)
        let twoHops = vm.extendedWindowStart(
            from: vm.extendedWindowStart(from: window, calendar: cal),
            calendar: cal
        )
        #expect(extended == twoHops)
    }

    @Test func extendedWindowStart_withEarliest_matchesSinglePage_whenOnePageSuffices() {
        let cal = gregorian()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let earliest = cal.date(byAdding: .day, value: -3, to: now)!
        let window = vm.initialWindowStart(from: now, calendar: cal)

        let extended = vm.extendedWindowStart(from: window, earliest: earliest, calendar: cal)
        let onePage = vm.extendedWindowStart(from: window, calendar: cal)

        #expect(extended == onePage)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: extended) == false)
    }

    @Test func extendedWindowStart_withNilEarliest_behavesAsSinglePage() {
        let cal = gregorian()
        let current = Date(timeIntervalSince1970: 1_700_000_000)
        let extended = vm.extendedWindowStart(from: current, earliest: nil, calendar: cal)
        let onePage = vm.extendedWindowStart(from: current, calendar: cal)
        #expect(extended == onePage)
    }

    @Test func extendedWindowStart_withEarliest_convergesOverLargeGap() {
        let cal = gregorian()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let earliest = cal.date(byAdding: .day, value: -365, to: now)!
        let window = vm.initialWindowStart(from: now, calendar: cal)

        let extended = vm.extendedWindowStart(from: window, earliest: earliest, calendar: cal)

        #expect(extended <= earliest)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: extended) == false)
    }
}
