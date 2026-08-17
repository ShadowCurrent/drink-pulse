import SwiftUI

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
