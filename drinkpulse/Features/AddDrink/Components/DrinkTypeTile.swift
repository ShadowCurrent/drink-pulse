import SwiftUI

/// Single selectable tile displayed inside `DrinkTypeGrid`.
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
    HStack {
        DrinkTypeTile(preset: .beer, isSelected: false)
        DrinkTypeTile(preset: .wine, isSelected: true)
    }
    .padding()
}
