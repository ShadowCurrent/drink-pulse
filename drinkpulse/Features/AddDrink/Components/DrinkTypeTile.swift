import SwiftUI

struct DrinkTypeTile: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let preset: DrinkTypePreset
    var isSelected: Bool = false

    var body: some View {
        // One element whose label is the name. Without it the name's accessibility frame spanned
        // the whole tile, so its contrast was measured against the emoji (plan 11-18).
        content
            .accessibilityElement(children: .combine)
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
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
        }
    }

    /// Decorative: the name carries the meaning, so the emoji is an unlabelled image.
    private var emoji: some View {
        DecorativeEmoji(emoji: preset.icon)
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
