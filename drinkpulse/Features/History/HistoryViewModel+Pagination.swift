import Foundation

/// One loaded page of the History list: the events to show and whether older ones exist.
struct HistoryListPage: Equatable {
    let events: [ConsumptionEvent]
    let hasMore: Bool
}

/// Count-based paging for the History list. The list `@Query` fetches `listFetchLimit`
/// newest events (one more than the page limit, to learn whether older events exist);
/// each load grows the limit by one page. Apple: `FetchDescriptor.init(predicate:sortBy:)`
/// recommends `fetchLimit`/`fetchOffset` when the number of fetched models may be high.
extension HistoryViewModel {

    static let listPageSize = 50

    func listFetchLimit(pageLimit: Int) -> Int { pageLimit + 1 }

    func nextPageLimit(after pageLimit: Int) -> Int { pageLimit + Self.listPageSize }

    /// `fetched` is newest first, at most `listFetchLimit(pageLimit:)` long. When it is over the
    /// limit, the oldest fetched day may be cut off, so it is held back until the next page and
    /// every shown day header total is the whole day. A single day bigger than the page shows
    /// the first `pageLimit` events rather than nothing.
    func listPage(
        from fetched: [ConsumptionEvent],
        pageLimit: Int,
        calendar: Calendar = .current
    ) -> HistoryListPage {
        guard fetched.count > pageLimit, let oldest = fetched.last else {
            return HistoryListPage(events: fetched, hasMore: false)
        }
        let cutDay = calendar.startOfDay(for: oldest.consumptionDate)
        let complete = fetched.filter { calendar.startOfDay(for: $0.consumptionDate) != cutDay }
        let events = complete.isEmpty ? Array(fetched.prefix(pageLimit)) : complete
        return HistoryListPage(events: events, hasMore: true)
    }
}
