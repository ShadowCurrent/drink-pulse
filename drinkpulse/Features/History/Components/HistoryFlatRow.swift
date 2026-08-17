import Foundation

/// One row in History's flat, one-List-row-per-event architecture (see
/// `.planning/debug/contextmenu-zoom-glitch.md`): SwiftUI's `.contextMenu`
/// does not correctly scope multiple sibling `.contextMenu`s nested inside
/// one shared `List` row — that shared-row shape (the retired
/// `HistoryDaySectionCard`, one List row per DAY hosting every event of
/// that day as a nested sibling subview) caused both a transient whole-day
/// highlight flash AND, more severely, silently routed Duplicate/Delete to
/// the WRONG event whenever the pressed row was not the first one in its
/// day. The List's own top-level `ForEach` now yields ONE row per
/// `ConsumptionEvent`, plus non-interactive day-header pseudo-rows in the
/// SAME flat `ForEach` — each one still a single top-level view (the "unary
/// row" shape List needs to stay lazily cell-reuse-backed and avoid Apple
/// Feedback FB11280425, exactly as the day-card rows this replaces already
/// did).
enum HistoryFlatRow: Identifiable {
    case header(id: Date, title: String)
    case event(ConsumptionEvent, position: HistoryRowGroupPosition)

    var id: AnyHashable {
        switch self {
        case .header(let id, _): id
        case .event(let event, _): event.uuid
        }
    }
}

/// Where one event sits within its day's contiguous run of List rows. Drives
/// which outer corners of the row's OWN Liquid Glass background
/// (`HistoryEventCardRow`) are rounded, so several adjacent single-event
/// rows for the same day still read as one seamless "day card" even though
/// none of them share a List row anymore — square corners between
/// consecutive same-day rows, no visible seam, as if it were still one card.
enum HistoryRowGroupPosition {
    case only    // the day's only event — all four corners rounded
    case first   // first of 2+ — top corners rounded, bottom square
    case middle  // neither first nor last — all corners square
    case last    // last of 2+ — bottom corners rounded, top square

    /// Whether this is the LAST event rendered for its day — drives both
    /// `EventRowButton`'s divider (no divider after the last row of a day,
    /// unchanged from the pre-flattening behavior) and the extra vertical
    /// List row inset that separates this day's rows from the next day's
    /// header pseudo-row.
    var isLastInDay: Bool {
        switch self {
        case .only, .last: true
        case .first, .middle: false
        }
    }
}

extension Array where Element == DaySection {
    /// Flattens day sections (already grouped/ordered by
    /// `HistoryViewModel.daySections`) into the List's actual flat row
    /// sequence, computing each event's `HistoryRowGroupPosition` from its
    /// place in its own day's (already date-ordered) event list.
    func flattenedForHistoryList() -> [HistoryFlatRow] {
        flatMap { section -> [HistoryFlatRow] in
            let lastIndex = section.events.count - 1
            let eventRows: [HistoryFlatRow] = section.events.enumerated().map { index, event in
                let position: HistoryRowGroupPosition = switch (index == 0, index == lastIndex) {
                case (true, true): .only
                case (true, false): .first
                case (false, true): .last
                case (false, false): .middle
                }
                return .event(event, position: position)
            }
            return [.header(id: section.id, title: section.title)] + eventRows
        }
    }
}
