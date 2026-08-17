import SwiftUI

struct DrinkTypeGrid: View {
    var selected: DrinkCategory?
    let onSelect: (DrinkTypePreset) -> Void

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(DrinkTypePreset.all) { preset in
                    tile(for: preset)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func tile(for preset: DrinkTypePreset) -> some View {
        let isSelected = preset.category == selected
        Button { onSelect(preset) } label: {
            DrinkTypeTile(preset: preset, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preset.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    DrinkTypeGrid(selected: .wine) { _ in }
}
