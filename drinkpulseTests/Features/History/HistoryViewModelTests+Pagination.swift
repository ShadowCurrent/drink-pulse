import Testing
import Foundation
@testable import drinkpulse

/// Pagination-window unit tests for `HistoryViewModel`. Split into its own
/// file to keep `HistoryViewModelTests.swift` from growing past the project's
/// 300-line ceiling — mirrors the `HistoryInteractionUITests+Helpers.swift`
/// split pattern already used in the UI test target.
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
        // 7-day window does not yet reach a 20-day-old event.
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == true)
        // One more page (14 days) still short; two pages (21) covers it.
        window = vm.extendedWindowStart(from: window, calendar: cal)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == true)
        window = vm.extendedWindowStart(from: window, calendar: cal)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: window) == false)
    }

    // MARK: - extendedWindowStart(from:earliest:) — gap-collapsing overload

    /// A gap that needs two single-page hops (see
    /// `extendedWindowThenHasMore_eventuallyCoversEarliest` above) is crossed
    /// in ONE call to the `earliest:`-aware overload — the sentinel only ever
    /// needs to fire once, no matter how large the empty stretch.
    @Test func extendedWindowStart_withEarliest_collapsesMultiPageGapInOneCall() {
        let cal = gregorian()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let earliest = cal.date(byAdding: .day, value: -20, to: now)!
        let window = vm.initialWindowStart(from: now, calendar: cal)

        let extended = vm.extendedWindowStart(from: window, earliest: earliest, calendar: cal)

        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: extended) == false)
        // Matches the two-single-hop result from the plain overload.
        let twoHops = vm.extendedWindowStart(
            from: vm.extendedWindowStart(from: window, calendar: cal),
            calendar: cal
        )
        #expect(extended == twoHops)
    }

    /// When one page is already enough, the gap-aware overload matches the
    /// plain single-page overload exactly (no over-extension).
    @Test func extendedWindowStart_withEarliest_matchesSinglePage_whenOnePageSuffices() {
        let cal = gregorian()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // 3 days ago is comfortably inside a single extended page.
        let earliest = cal.date(byAdding: .day, value: -3, to: now)!
        let window = vm.initialWindowStart(from: now, calendar: cal)

        let extended = vm.extendedWindowStart(from: window, earliest: earliest, calendar: cal)
        let onePage = vm.extendedWindowStart(from: window, calendar: cal)

        #expect(extended == onePage)
        #expect(vm.hasMoreToLoad(earliest: earliest, windowStart: extended) == false)
    }

    /// `earliest: nil` (no events at all) behaves exactly like the plain
    /// single-page overload — no gap to collapse, nothing to guard against.
    @Test func extendedWindowStart_withNilEarliest_behavesAsSinglePage() {
        let cal = gregorian()
        let current = Date(timeIntervalSince1970: 1_700_000_000)
        let extended = vm.extendedWindowStart(from: current, earliest: nil, calendar: cal)
        let onePage = vm.extendedWindowStart(from: current, calendar: cal)
        #expect(extended == onePage)
    }

    /// A large, sparse gap (e.g. a year with a single old event) still
    /// converges to exactly cover `earliest` in one call, not just "closer."
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
