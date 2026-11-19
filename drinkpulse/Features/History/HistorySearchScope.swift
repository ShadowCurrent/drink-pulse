import Foundation

/// Search scopes offered by the History list search field.
enum HistorySearchScope: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all, named, unnamed

    var id: Self { self }

    var label: String {
        switch self {
        case .all:     return String(localized: "history.search.scope.all")
        case .named:   return String(localized: "history.search.scope.named")
        case .unnamed: return String(localized: "history.search.scope.unnamed")
        }
    }
}
