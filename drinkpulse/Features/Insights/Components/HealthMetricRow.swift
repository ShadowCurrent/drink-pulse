import SwiftUI

// Generic list-row metric. Kept for potential reuse outside the Insights grid.
struct HealthMetricRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var badge: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body.weight(.semibold))
            }
            Spacer()
            if let badge {
                Text(badge)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    VStack(spacing: 0) {
        HealthMetricRow(icon: "flame.fill", iconColor: .orange,
                        title: "Calories", value: "840 kcal")
        Divider()
        HealthMetricRow(icon: "trophy.fill", iconColor: .yellow,
                        title: "Streak", value: "7 days", badge: "Best")
    }
    .padding()
    .dpGlassCard()
    .padding()
}
