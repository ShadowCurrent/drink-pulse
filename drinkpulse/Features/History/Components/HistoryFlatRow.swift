import Foundation

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

enum HistoryRowGroupPosition {
    case only
    case first
    case middle
    case last

    var isLastInDay: Bool {
        switch self {
        case .only, .last: true
        case .first, .middle: false
        }
    }
}

extension Array where Element == DaySection {
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
