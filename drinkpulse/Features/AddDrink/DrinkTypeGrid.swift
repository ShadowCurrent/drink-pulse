import SwiftUI

/// Shared drink-type tile grid used by both the Add-Drink flow and the
/// edit-entry "change type" flow. Emits the picked preset via `onSelect`;
/// each caller decides what navigation that triggers (push to detail vs.
/// apply + pop).
struct DrinkTypeGrid: View {
    /// Currently-selected category, highlighted in the grid (edit flow).
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

struct DrinkTypeTile: View {
    let preset: DrinkTypePreset
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 18) {
            Text(preset.icon)
                .font(.system(size: 34))
                .accessibilityHidden(true)
            Text(preset.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .dpGlassCard(.chip)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            }
        }
    }
}

#Preview {
    DrinkTypeGrid(selected: .wine) { _ in }
}
