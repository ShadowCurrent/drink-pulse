import SwiftUI

struct DPChip: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let icon: String
    let value: String
    let label: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(accent)
                .font(.body.weight(.medium))
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.7)
            // Not `.secondary`: a hierarchical style on the glass card is drawn vibrant and fails
            // the contrast audit (plan 11-17).
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.dpSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .dpGlassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    HStack(spacing: 12) {
        DPChip(icon: "flame.fill", value: "142 kcal", label: "Calories", accent: .dpAmber)
        DPChip(icon: "bolt.fill",  value: "2",        label: "Drinks",   accent: .dpPurple)
    }
    .padding()
}

#Preview("Accessibility 5") {
    DPAdaptiveStack(spacing: 12) {
        DPChip(icon: "flame.fill", value: "142 kcal", label: "Calories", accent: .dpAmber)
        DPChip(icon: "bolt.fill",  value: "2",        label: "Drinks",   accent: .dpPurple)
    }
    .padding()
    .dynamicTypeSize(.accessibility5)
}
