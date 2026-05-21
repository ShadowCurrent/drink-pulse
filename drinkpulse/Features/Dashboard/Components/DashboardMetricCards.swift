import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let iconName: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(accent)
                .font(.system(size: 20, weight: .medium))
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .dpGlassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct StreakCard: View {
    let value: Int
    let label: String
    let iconName: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(accent)
                .font(.system(size: 22))
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.title2.bold())
                    .monospacedDigit()
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
        .accessibilityLabel("\(label): \(value)")
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
