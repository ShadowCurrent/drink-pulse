import SwiftUI

/// Row insets shared by the History list and the History search results.
enum HistoryListInsets {
    static let event = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
    static let header = EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
}

extension View {
    func historyListRowChrome(
        insets: EdgeInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    ) -> some View {
        listRowInsets(insets)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
