import SwiftUI

struct HistoryView: View {
    var body: some View {
        Text(String(localized: "history.placeholder"))
            .foregroundStyle(.secondary)
            .navigationTitle(String(localized: "tab.history"))
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
