import SwiftUI

struct DPChip: View {
    let icon: String
    let value: String
    let label: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(accent)
                .font(.system(size: 18, weight: .medium))
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
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
