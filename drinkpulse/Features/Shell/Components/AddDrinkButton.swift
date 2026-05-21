import SwiftUI

struct AddDrinkButton: View {
    let action: () -> Void
    @Environment(\.dpTheme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .foregroundStyle(.white)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(theme.gradient, in: Circle())
        }
        .buttonStyle(.plain)
        .clipShape(Circle())
        .accessibilityLabel(String(localized: "addDrink.title"))
        .accessibilityAddTraits(.isButton)
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
