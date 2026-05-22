import SwiftUI

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

// MARK: - Health Metrics Card

struct HealthMetricsCard: View {
    let vm: InsightsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "insights.section.healthMetrics"))
                .font(.headline)
            Divider()
            riskRow
            Divider()
            caloriesRow
            if vm.bingeEpisodesThisMonth > 0 {
                Divider()
                bingeRow
            }
            if let spend = vm.monthSpend {
                Divider()
                spendRow(spend)
            }
        }
        .padding()
        .dpGlassCard()
    }

    private var riskRow: some View {
        HealthMetricRow(
            icon: riskIcon,
            iconColor: riskColor,
            title: String(localized: "insights.metric.riskLevel"),
            value: riskLabel
        )
    }

    private var caloriesRow: some View {
        HealthMetricRow(
            icon: "flame.fill",
            iconColor: .orange,
            title: String(localized: "insights.metric.calories"),
            value: "\(vm.monthCaloriesKcal) kcal"
        )
    }

    private var bingeRow: some View {
        HealthMetricRow(
            icon: "exclamationmark.triangle.fill",
            iconColor: .dpRiskHigh,
            title: String(localized: "insights.metric.bingeEpisodes"),
            value: "\(vm.bingeEpisodesThisMonth)"
        )
    }

    private func spendRow(_ spend: Double) -> some View {
        HealthMetricRow(
            icon: "dollarsign.circle.fill",
            iconColor: .green,
            title: String(localized: "insights.metric.spend"),
            value: vm.formattedSpend(spend)
        )
    }

    private var riskLabel: String {
        switch vm.currentRiskLevel {
        case .safe:     return String(localized: "insights.metric.risk.low")
        case .caution:  return String(localized: "insights.metric.risk.moderate")
        case .exceeded: return String(localized: "insights.metric.risk.high")
        }
    }

    private var riskIcon: String {
        switch vm.currentRiskLevel {
        case .safe:     return "checkmark.circle.fill"
        case .caution:  return "exclamationmark.circle.fill"
        case .exceeded: return "xmark.circle.fill"
        }
    }

    private var riskColor: Color {
        switch vm.currentRiskLevel {
        case .safe:     return .dpRiskLow
        case .caution:  return .dpRiskModerate
        case .exceeded: return .dpRiskHigh
        }
    }
}

#Preview {
    let vm = InsightsViewModel()
    vm.events = [.previewBeer, .previewWine]
    vm.profile = .preview
    return HealthMetricsCard(vm: vm).padding()
}
