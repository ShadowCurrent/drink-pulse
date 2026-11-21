import SwiftUI

/// Empty state shared by screens that have nothing to show before the first logged drink
/// (plan 0046, D0046-13; prototype round 17). System `ContentUnavailableView` with one action
/// that opens Add Drink. Bordered, not prominent, so it does not compete with the toolbar `+`.
struct NoDrinksYetView: View {
    @Environment(\.addDrink) private var addDrink
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            Button(String(localized: "common.logADrink")) { addDrink() }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("empty.logADrink")
        }
    }
}

#Preview("Empty") {
    NavigationStack {
        NoDrinksYetView(title: "No Drinks Yet", message: "Drinks you log appear here.",
                        systemImage: "wineglass")
            .navigationTitle(Text(verbatim: "History"))
    }
}

#Preview("Empty · AX5") {
    NavigationStack {
        NoDrinksYetView(title: "No Insights Yet",
                        message: "Your totals and trends appear once you log a drink.",
                        systemImage: "chart.bar")
    }
    .dynamicTypeSize(.accessibility5)
}
