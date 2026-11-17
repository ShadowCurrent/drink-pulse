import SwiftUI

struct DashboardHeroCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var scaledArcSize: Double = 100

    let vm: DashboardViewModel

    private var isAccessibilitySize: Bool { dynamicTypeSize.isAccessibilitySize }

    /// Grows with the text so the percentage inside the arc keeps fitting, capped so the arc
    /// stays inside the card at the largest sizes.
    private var arcSize: CGFloat { CGFloat(min(scaledArcSize, 220)) }

    var body: some View {
        DPAdaptiveStack(spacing: 16) {
            leftColumn
            Spacer(minLength: 0)
            arcWithLabel
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .dpGlassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(localized: "dashboard.hero.eyebrow") + ": " + vm.formattedAlcohol(vm.todayGrams)
        )
    }

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Not `.secondary`: a hierarchical style on the glass card is drawn vibrant and fails
            // the contrast audit (plan 11-17).
            Text(String(localized: "dashboard.hero.eyebrow"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dpSecondaryText)
                .textCase(.uppercase)

            valueText

            Text(limitCopy)
                .font(.caption)
                .foregroundStyle(Color.dpSecondaryText)

            if vm.todayPct > 1.0 {
                Label(String(localized: "dashboard.risk.exceeded"),
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dpRed)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.dpRed.opacity(0.12))
                    .clipShape(badgeShape)
            }
        }
    }

    private var arcWithLabel: some View {
        ZStack {
            DPArcProgress(pct: vm.todayPct, color: arcColor, size: arcSize, strokeWidth: 9)
            Text("\(Int((vm.todayPct * 100).rounded()))%")
                .font(.callout.bold())
                .fontDesign(.rounded)
                .foregroundStyle(arcColor)
        }
    }

    /// Two branches because the audit rejected a rounded, scale-limited value at accessibility
    /// sizes; there the plain `title3` bold value wraps instead of shrinking.
    @ViewBuilder
    private var valueText: some View {
        if isAccessibilitySize {
            Text(vm.formattedAlcohol(vm.todayGrams))
                .font(.title3.bold())
                .monospacedDigit()
        } else {
            Text(vm.formattedAlcohol(vm.todayGrams))
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private var badgeShape: AnyShape {
        isAccessibilitySize
            ? AnyShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            : AnyShape(Capsule())
    }

    private var arcColor: Color { vm.todayRiskLevel.chartColor }

    private var limitCopy: String {
        let formatted = vm.formattedAlcohol(vm.effectiveDailyLimitGrams)
        if vm.dailyLimitGrams > 0 {
            return String(format: String(localized: "dashboard.hero.dailyLimit"), formatted)
        } else {
            return String(format: String(localized: "dashboard.hero.dailyAvg"), formatted)
        }
    }
}

#Preview("Normal") {
    DashboardHeroCard(vm: DashboardViewModel())
        .padding()
}

#Preview("Accessibility 5") {
    DashboardHeroCard(vm: DashboardViewModel())
        .padding()
        .dynamicTypeSize(.accessibility5)
}
