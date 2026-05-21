import SwiftUI

struct AddDrinkButton: View {
    let action: () -> Void
    @Environment(\.dpTheme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .fontWeight(.semibold)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .tint(theme.primary)
        .accessibilityLabel(String(localized: "addDrink.title"))
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationTitle("Preview")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AddDrinkButton(action: {})
                }
            }
    }
}
