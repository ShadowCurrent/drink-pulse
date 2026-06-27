import SwiftUI

struct StreakCard: View {
    let value: Int
    let label: String
    let iconName: String
    let accent: Color
    var zeroStateCopy: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(accent)
                .font(.system(size: 22))
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                if value == 0, let copy = zeroStateCopy {
                    Text(copy)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    Text("\(value)")
                        .font(.title2.bold())
                        .monospacedDigit()
                }
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
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
