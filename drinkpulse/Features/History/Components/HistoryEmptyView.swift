import SwiftUI

/// History with no drinks at all: system empty state with a Log a Drink action
/// (plan 0045, D0045-10; prototype round 17).
struct HistoryEmptyView: View {
    @Environment(\.addDrink) private var addDrink

    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "history.emptyTitle"), systemImage: "wineglass")
        } description: {
            Text(String(localized: "history.emptyDescription"))
        } actions: {
            Button(String(localized: "history.logADrink")) { addDrink() }
                .buttonStyle(.bordered)
        }
    }
}

#Preview("Empty") {
    NavigationStack {
        HistoryEmptyView()
            .navigationTitle(Text(verbatim: "History"))
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Empty · AX5") {
    NavigationStack { HistoryEmptyView() }
        .dynamicTypeSize(.accessibility5)
}
