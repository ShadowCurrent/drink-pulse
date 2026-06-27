import SwiftUI

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

#Preview("Over limit") {
    GuidelineAlertCard(weeklyPct: 1.3, guidelineName: "WHO")
        .padding()
}

#Preview("Caution") {
    GuidelineAlertCard(weeklyPct: 0.85, guidelineName: "UK NHS")
        .padding()
}
