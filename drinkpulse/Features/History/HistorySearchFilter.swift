import Foundation
import SwiftData

/// Which empty state the search results show when nothing matches.
enum HistorySearchEmptyState: Equatable, Sendable {
    case noMatches
    case unnamedHasNoName
}

/// Maps the History search text and scope to a SwiftData predicate.
///
/// Text matches `customName` only, via `localizedStandardContains`
/// (case- and diacritic-insensitive, locale-aware). An empty-string
/// `customName` (possible after import) counts as unnamed.
struct HistorySearchFilter: Equatable, Sendable {
    let query: String
    let scope: HistorySearchScope

    init(text: String, scope: HistorySearchScope) {
        self.query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.scope = scope
    }

    var isActive: Bool { !query.isEmpty || scope != .all }

    var emptyState: HistorySearchEmptyState {
        scope == .unnamed && !query.isEmpty ? .unnamedHasNoName : .noMatches
    }

    var predicate: Predicate<ConsumptionEvent> {
        let query = self.query
        switch (scope, query.isEmpty) {
        case (.all, true):
            return #Predicate<ConsumptionEvent> { _ in true }
        case (.all, false):
            return #Predicate<ConsumptionEvent> { event in
                event.customName?.localizedStandardContains(query) == true
            }
        case (.named, true):
            return #Predicate<ConsumptionEvent> { event in
                event.customName != nil && event.customName != ""
            }
        case (.named, false):
            return #Predicate<ConsumptionEvent> { event in
                event.customName?.localizedStandardContains(query) == true
            }
        case (.unnamed, true):
            return #Predicate<ConsumptionEvent> { event in
                event.customName == nil || event.customName == ""
            }
        case (.unnamed, false):
            return #Predicate<ConsumptionEvent> { _ in false }
        }
    }
}
