import SwiftUI

struct HistoryDayHeaderRow: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.footnote)
            .foregroundStyle(Color.dpSecondaryText)
            .textCase(.uppercase)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    List {
        HistoryDayHeaderRow(title: "Today")
            .historyListRowChrome(insets: HistoryListInsets.header)
    }
    .listStyle(.plain)
}
