import SwiftUI

struct DrinkTypeGridView: View {
    let dismissSheet: DismissAction

    @State private var selection: DrinkTypePreset?

    var body: some View {
        DrinkTypeGrid { selection = $0 }
            .navigationTitle(String(localized: "addDrink.title"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selection) { preset in
                DrinkDetailInputView(preset: preset, dismissSheet: dismissSheet)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) { dismissSheet() }
                }
            }
    }
}

#Preview {
    AddDrinkView()
}
