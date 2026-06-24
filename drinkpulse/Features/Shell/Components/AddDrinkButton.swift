import SwiftUI

struct AddDrinkButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .fontWeight(.semibold)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
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
