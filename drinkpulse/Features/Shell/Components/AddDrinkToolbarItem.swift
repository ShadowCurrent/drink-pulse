import SwiftUI

/// The `+` primary action of a screen that logs drinks (Today, Insights, History).
/// Settings has none (plan 0044 D0044-1).
struct AddDrinkToolbarItem: ToolbarContent {
    @Environment(\.addDrink) private var addDrink

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(String(localized: "addDrink.title"), systemImage: "plus") {
                addDrink()
            }
            .buttonStyle(.glassProminent)
            .accessibilityIdentifier("addDrink.button")
        }
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationTitle("Preview")
            .toolbar { AddDrinkToolbarItem() }
    }
}
