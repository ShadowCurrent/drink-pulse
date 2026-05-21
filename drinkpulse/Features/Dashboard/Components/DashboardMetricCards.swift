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
        .frame(maxWidth: .infinity)
        .dpGlassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if value == 0, let copy = zeroStateCopy { return "\(label): \(copy)" }
        return "\(label): \(value)"
    }
}

struct GuidelineAlertCard: View {
    let weeklyPct: Double
    let guidelineName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.dpRed)
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "dashboard.alert.title"))
                    .font(.subheadline.bold())
                Text(String(format: "%.0f%% of %@ weekly limit", weeklyPct * 100, guidelineName))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .dpGlassCard()
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.dpRed.opacity(0.10))
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(
            format: "%@. %.0f%% of %@ guideline.",
            String(localized: "dashboard.alert.title"), weeklyPct * 100, guidelineName
        ))
    }
}
