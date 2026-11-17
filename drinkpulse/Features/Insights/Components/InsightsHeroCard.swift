import SwiftUI
import Charts

struct InsightsHeroCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let vm: InsightsViewModel

    @State private var selectedKey: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerRow
            AlcoholAreaChart(
                data: vm.seriesData, period: vm.period,
                selectedKey: $selectedKey,
                formattedValue: vm.formattedValue
            )
        }
        .padding()
        .dpGlassCard()
        .accessibilityElement(children: .contain)
        .onChange(of: vm.period) { selectedKey = nil }
    }

    private var headerRow: some View {
        DPAdaptiveStack(verticalAlignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                // Not `.secondary`: a hierarchical style on the glass card is drawn vibrant and
                // fails the contrast audit (plan 11-17 token, reused in plan 11-19).
                Text(String(localized: "insights.hero.total"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dpSecondaryText)
                    .textCase(.uppercase)

                totalText

                Text(vm.isAllTime ? "" : vsPrevLabel)
                    .font(.caption)
                    .foregroundStyle(Color.dpSecondaryText)
                    .opacity(vm.isAllTime ? 0 : 1)
                    .accessibilityHidden(vm.isAllTime)
            }

            Spacer(minLength: 8)

            if !vm.isAllTime {
                TrendBadge(fraction: vm.trendFraction)
                    .padding(.top, 6)
            }
        }
    }

    /// Two branches: at accessibility sizes the plain `title3` bold value wraps instead of
    /// shrinking (the audit rejects a rounded, scale-limited value there, as on Home).
    @ViewBuilder
    private var totalText: some View {
        let text = vm.formattedValue(selectedGrams ?? vm.periodTotalGrams)
        if dynamicTypeSize.isAccessibilitySize {
            Text(text)
                .font(.title3.bold())
                .monospacedDigit()
        } else {
            Text(text)
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    private var selectedGrams: Double? {
        guard let selectedKey else { return nil }
        return vm.seriesData.first(where: { ChartPoint.key(for: $0.date) == selectedKey })?.grams
    }

    private var vsPrevLabel: String {
        let prev = vm.formattedValue(vm.prevPeriodTotalGrams)
        let period = vm.period.localizedLabel.lowercased()
        return String(format: String(localized: "insights.hero.vsPrev"), period, prev)
    }
}

// MARK: - Trend badge

private struct TrendBadge: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let fraction: Double

    /// A capsule clips a label that wraps, so accessibility sizes use a rounded rectangle.
    private var badgeShape: AnyShape {
        dynamicTypeSize.isAccessibilitySize
            ? AnyShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            : AnyShape(Capsule())
    }

    private var isUnchanged: Bool { abs(fraction) <= 0.01 }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(label)
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(badgeColor.opacity(0.15), in: badgeShape)
    }

    /// Text tokens of plan 11-17: the fill colors below are under 4.5:1 for small text on the tint.
    private var textColor: Color {
        if isUnchanged { return .dpSecondaryText }
        return fraction < 0 ? RiskLevel.safe.textColor : RiskLevel.exceeded.textColor
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
    InsightsHeroCard(vm: InsightsViewModel.preview)
        .padding()
}

#Preview("Accessibility 5") {
    ScrollView {
        InsightsHeroCard(vm: InsightsViewModel.preview)
            .padding()
    }
    .dynamicTypeSize(.accessibility5)
}
