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

    // Exact fraction of mode-mass vs the physical-gram limit — the clean unit math now
    // lands "2.0 / 2.0 units" on exactly 100 % without any rounding workaround.
    private var pct: Double { vm.fraction(consumedGrams: consumedGrams, limitGrams: limitGrams) }
    private var pctClamped: Double { min(pct, 1) }

    private var color: Color { RiskLevel.from(pct: pct).color }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                pctBadge
                Spacer()
                valueLabel
            }
            progressBar
            if pct > 1 {
                // Overage in the user's unit. formattedNumber divides by the same gramsPerUnit
                // constant, so this equals displayedConsumed − displayedLimit exactly.
                let over = consumedGrams - limitGrams
                Text(String(
                    format: String(localized: "dashboard.overview.overLimit"),
                    vm.formattedNumber(over) + " " + vm.unitLabel
                ))
                .font(.caption2)
                .foregroundStyle(color)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var pctBadge: some View {
        Text("\(Int(pct * 100))%")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private var valueLabel: some View {
        HStack(spacing: 0) {
            Text(vm.formattedNumber(consumedGrams))
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(" / \(vm.formattedNumber(limitGrams)) \(vm.unitLabel)")
                .foregroundStyle(.tertiary)
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
            .animation(.easeOut(duration: 0.5), value: pctClamped)
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
    let event1 = ConsumptionEvent(timestamp: now, volumeMl: 568, abv: 0.05,
                                  name: "Beer", category: .beer, icon: "🍺")
    let minus2 = cal.date(byAdding: .day, value: -2, to: now)!
    let event2 = ConsumptionEvent(timestamp: minus2, volumeMl: 330, abv: 0.05,
                                  name: "Beer", category: .beer, icon: "🍺")
    vm.events = [event1, event2]
    vm.profile = UserProfile.preview
    return ConsumptionOverviewCard(vm: vm)
        .padding()
}

#Preview("Empty") {
    ConsumptionOverviewCard(vm: DashboardViewModel())
        .padding()
}
