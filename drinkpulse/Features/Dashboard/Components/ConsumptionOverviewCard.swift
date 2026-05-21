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

    private var pct: Double { limitGrams > 0 ? consumedGrams / limitGrams : 0 }
    private var pctClamped: Double { min(pct, 1) }

    private var color: Color {
        if pct < 0.5 { return .dpGreen }
        if pct < 1.0 { return .dpAmber }
        return .dpRed
    }

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
                Text(String(
                    format: String(localized: "dashboard.overview.overLimit"),
                    vm.formattedNumber(consumedGrams - limitGrams) + " " + vm.alcoholUnit.unitLabel
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
            Text(" / \(vm.formattedNumber(limitGrams)) \(vm.alcoholUnit.unitLabel)")
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
               vm.alcoholUnit.unitLabel,
               Int(pct * 100))
    }
}
