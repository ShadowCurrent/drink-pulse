import SwiftUI

struct DrinkTypeGridView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selection: DrinkTypePreset?

    var body: some View {
        DrinkTypeGrid { selection = $0 }
            .navigationTitle(String(localized: "addDrink.title"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selection) { preset in
                DrinkDetailInputView(preset: preset)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
            }
    }
}

#Preview {
    NavigationStack {
        DrinkTypeGridView()
    }
}
