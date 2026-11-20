import SwiftUI

struct ConsumptionOverviewCard: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "dashboard.overview.title"))
                .font(.headline)
                .padding(.bottom, 14)
            VStack(spacing: 14) {
                IntakePeriodRow(
                    label: String(localized: "dashboard.section.today"),
                    consumedGrams: vm.todayGrams,
                    limitGrams: vm.effectiveDailyLimitGrams,
                    vm: vm
                )
                Divider()
                IntakePeriodRow(
                    label: String(localized: "dashboard.overview.days7"),
                    consumedGrams: vm.sevenDayGrams,
                    limitGrams: vm.weeklyLimitGrams,
                    vm: vm
                )
                Divider()
                IntakePeriodRow(
                    label: String(localized: "dashboard.overview.days30"),
                    consumedGrams: vm.thirtyDayGrams,
                    limitGrams: vm.thirtyDayLimitGrams,
                    vm: vm
                )
            }
        }
        .padding()
        .dpGlassCard()
    }
}

struct IntakePeriodRow: View {
    let label: String
    let consumedGrams: Double
    let limitGrams: Double
    let vm: DashboardViewModel

    private var pct: Double { vm.fraction(consumedGrams: consumedGrams, limitGrams: limitGrams) }
    private var pctClamped: Double { min(pct, 1) }

    private var color: Color { RiskLevel.from(pct: pct).tone }
    private var textColor: Color { RiskLevel.from(pct: pct).tone }

    @State private var hasSettledOnce = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DPAdaptiveStack(verticalAlignment: .firstTextBaseline, spacing: 4) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                pctBadge
                Spacer(minLength: 0)
                valueLabel
            }
            progressBar
            if pct > 1 {
                let over = consumedGrams - limitGrams
                Text(String(
                    format: String(localized: "dashboard.overview.overLimit"),
                    vm.formattedNumber(over) + " " + vm.unitLabel
                ))
                .font(.caption)
                .foregroundStyle(textColor)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .onChange(of: pctClamped) { _, _ in hasSettledOnce = true }
        // Outside the combined element above, so the probe stays its own accessibility element.
        .overlay { DPMotionProbe(site: "overviewBar", reduceMotion: reduceMotion) }
    }

    private var pctBadge: some View {
        Text("\(Int(pct * 100))%")
            .font(.caption.weight(.semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            // No risk-tinted fill: under the Dark exceeded tone it fell below 4.5:1 on the glass
            // card (plan 0042). Today is redesigned in port step 6.
            .background(Capsule().strokeBorder(color, lineWidth: 1))
    }

    private var valueLabel: some View {
        HStack(spacing: 0) {
            Text(vm.formattedNumber(consumedGrams))
                .fontWeight(.semibold)
                .foregroundStyle(textColor)
            // Not `.tertiary`: a hierarchical style on the glass card is drawn vibrant and fails
            // the contrast audit (plan 11-17).
            Text(" / \(vm.formattedNumber(limitGrams)) \(vm.unitLabel)")
                .foregroundStyle(Color.dpSecondaryText)
        }
        .font(.subheadline)
        .monospacedDigit()
    }

    private var progressBar: some View {
        Capsule()
            .fill(Color(.systemFill))
            .frame(height: 10)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * pctClamped)
                }
            }
            .animation(barAnimation, value: pctClamped)
    }

    private var barAnimation: Animation? {
        guard hasSettledOnce else { return nil }
        return DPMotion.animation(.easeOut(duration: 0.5), reduceMotion: reduceMotion)
    }

    private var accessibilityText: String {
        String(format: "%@: %@ of %@ %@, %d percent",
               label,
               vm.formattedNumber(consumedGrams),
               vm.formattedNumber(limitGrams),
               vm.unitLabel,
               Int(pct * 100))
    }
}

#Preview("With data") {
    let vm = DashboardViewModel()
    let cal = Calendar.current
    let now = Date.now
    let event1 = ConsumptionEvent(consumptionDate: now, volumeMl: 568, abv: 0.05,
                                  category: .beer, icon: "🍺")
    let minus2 = cal.date(byAdding: .day, value: -2, to: now)!
    let event2 = ConsumptionEvent(consumptionDate: minus2, volumeMl: 330, abv: 0.05,
                                  category: .beer, icon: "🍺")
    vm.events = [event1, event2]
    vm.profile = UserProfile.preview
    return ConsumptionOverviewCard(vm: vm)
        .padding()
}

#Preview("Empty") {
    ConsumptionOverviewCard(vm: DashboardViewModel())
        .padding()
}

#Preview("Accessibility 5") {
    ConsumptionOverviewCard(vm: DashboardViewModel())
        .padding()
        .dynamicTypeSize(.accessibility5)
}
