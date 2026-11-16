import SwiftUI

struct DrinkTypeTile: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let preset: DrinkTypePreset
    var isSelected: Bool = false

    var body: some View {
        content
            .dpGlassCard(.chip)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
    }

    /// A square tile with the name under the emoji at regular sizes; a full-width row with the
    /// emoji beside the name at accessibility sizes, so names wrap instead of truncating.
    @ViewBuilder
    private var content: some View {
        if dynamicTypeSize.isAccessibilitySize {
            HStack(spacing: 12) {
                emoji
                name
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: 18) {
                emoji
                name
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
        }
    }

    private var emoji: some View {
        Text(preset.icon)
            .font(.largeTitle)
            .accessibilityHidden(true)
    }

    private var name: some View {
        Text(preset.name)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
    }
}

#Preview {
    HStack {
        DrinkTypeTile(preset: .beer, isSelected: false)
        DrinkTypeTile(preset: .wine, isSelected: true)
    }
    .padding()
}

#Preview("Accessibility 5") {
    VStack {
        DrinkTypeTile(preset: .beer, isSelected: false)
        DrinkTypeTile(preset: .wine, isSelected: true)
    }
    .padding()
    .dynamicTypeSize(.accessibility5)
}
