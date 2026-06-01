import SwiftUI

/// Drink-type picker pushed from the edit-entry form. Reuses the shared
/// `DrinkTypeGrid`; selecting a type applies it and pops back to the form.
struct EditDrinkTypeSelectionView: View {
    let current: DrinkCategory
    let onSelect: (DrinkTypePreset) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DrinkTypeGrid(selected: current) { preset in
            onSelect(preset)
            dismiss()
        }
        .navigationTitle(String(localized: "editDrink.changeType"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EditDrinkTypeSelectionView(current: .beer) { _ in }
    }
}
