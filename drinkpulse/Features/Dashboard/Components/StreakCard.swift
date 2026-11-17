import SwiftUI

struct StreakCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title2) private var iconWidth: Double = 30

    let value: Int
    let label: String
    let iconName: String
    let accent: Color
    var zeroStateCopy: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(accent)
                .font(.title2)
                .frame(width: iconWidth)
            VStack(alignment: .leading, spacing: 2) {
                if value == 0, let copy = zeroStateCopy {
                    Text(copy)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dpSecondaryText)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                } else {
                    Text("\(value)")
                        .font(.title2.bold())
                        .monospacedDigit()
                }
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.dpSecondaryText)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dpGlassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if value == 0, let copy = zeroStateCopy { return "\(label): \(copy)" }
        return "\(label): \(value)"
    }
}

#Preview("With streak") {
    HStack(spacing: 12) {
        StreakCard(
            value: 5,
            label: "Sober streak (days)",
            iconName: "flame.fill",
            accent: .dpAmber
        )
        StreakCard(
            value: 12,
            label: "Sober days this month",
            iconName: "moon.stars.fill",
            accent: .dpPurple
        )
    }
    .padding()
}

#Preview("Accessibility 5") {
    DPAdaptiveStack(spacing: 12) {
        StreakCard(
            value: 0,
            label: "Sober streak (days)",
            iconName: "flame.fill",
            accent: .dpAmber,
            zeroStateCopy: "Start a streak tomorrow"
        )
        StreakCard(
            value: 12,
            label: "Sober days this month",
            iconName: "moon.stars.fill",
            accent: .dpPurple
        )
    }
    .padding()
    .dynamicTypeSize(.accessibility5)
}

#Preview("Zero state") {
    HStack(spacing: 12) {
        StreakCard(
            value: 0,
            label: "Sober streak (days)",
            iconName: "flame.fill",
            accent: .dpAmber,
            zeroStateCopy: "Start a streak tomorrow"
        )
        StreakCard(
            value: 0,
            label: "Sober days this month",
            iconName: "moon.stars.fill",
            accent: .dpPurple
        )
    }
    .padding()
}
