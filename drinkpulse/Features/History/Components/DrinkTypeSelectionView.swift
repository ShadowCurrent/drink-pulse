import SwiftUI

/// Edit Drink's type list: the Add Drink sections without Recent or search, with a checkmark on
/// the current type (HIG Lists and tables: a list of options marks the chosen row).
struct DrinkTypeSelectionView: View {
    let current: DrinkCategory
    /// Called on every tap with the new category, or nil when the row is the current type;
    /// the caller closes the list.
    let onSelect: (DrinkCategory?) -> Void

    var body: some View {
        List {
            Group {
                DrinkTypeSections(query: "") { preset in
                    row(preset)
                }
            }
            .brandRowBackground()
        }
        .brandListBackground()
        .navigationTitle(String(localized: "editDrink.changeType"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ preset: DrinkTypePreset) -> some View {
        let isSelected = DrinkTypeSelection.isSelected(preset.category, current: current)
        return Button {
            onSelect(DrinkTypeSelection.apply(preset.category, to: current))
        } label: {
            HStack {
                DrinkTypeLabel(preset: preset)
                    .foregroundStyle(Color.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityIdentifier("addDrink.type.\(preset.category.rawValue)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Light") {
    NavigationStack { DrinkTypeSelectionView(current: .cognac) { _ in } }
}

#Preview("Dark") {
    NavigationStack { DrinkTypeSelectionView(current: .beer) { _ in } }
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    NavigationStack { DrinkTypeSelectionView(current: .wine) { _ in } }
        .dynamicTypeSize(.accessibility5)
}
