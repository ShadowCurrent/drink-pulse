import SwiftUI
import Charts

struct InsightsHeroCard: View {
    let vm: InsightsViewModel
    @Environment(\.dpTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerRow
            AlcoholAreaChart(data: vm.seriesData, period: vm.period)
        }
        .padding()
        .dpGlassCard()
        .accessibilityElement(children: .contain)
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "insights.hero.total"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(vm.formattedValue(vm.periodTotalGrams))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(vsPrevLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            TrendBadge(fraction: vm.trendFraction)
                .padding(.top, 6)
        }
    }

    private var vsPrevLabel: String {
        let prev = vm.formattedValue(vm.prevPeriodTotalGrams)
        let period = vm.period.localizedLabel.lowercased()
        return String(format: String(localized: "insights.hero.vsPrev"), period, prev)
    }
}

// MARK: - Trend badge

private struct TrendBadge: View {
    let fraction: Double

    private var isUnchanged: Bool { abs(fraction) <= 0.01 }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(label)
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(badgeColor.opacity(0.15), in: Capsule())
    }

    private var icon: String {
        if isUnchanged { return "equal" }
        return fraction < 0 ? "arrow.down" : "arrow.up"
    }

    private var label: String {
        if isUnchanged { return String(localized: "insights.trend.unchanged") }
        return "\(Int((abs(fraction) * 100).rounded()))%"
    }

    private var badgeColor: Color {
        if isUnchanged { return .secondary }
        return fraction < 0 ? .dpGreen : .dpRed
    }
}

#Preview("Hero card") {
    InsightsHeroCard(vm: InsightsViewModel())
        .padding()
}
