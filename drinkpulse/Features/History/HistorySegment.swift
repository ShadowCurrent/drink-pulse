import Foundation

enum HistorySegment: String, CaseIterable {
    case list, calendar

    var label: String {
        switch self {
        case .list:     return String(localized: "history.segment.list")
        case .calendar: return String(localized: "history.segment.calendar")
        }
    }
}
