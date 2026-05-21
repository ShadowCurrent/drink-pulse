import SwiftUI

struct DashboardHeroCard: View {
    let vm: DashboardViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            leftColumn
            Spacer(minLength: 0)
            arcWithLabel
        }
        .padding()
        .dpGlassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(localized: "dashboard.hero.eyebrow") + ": " + vm.formattedAlcohol(vm.todayGrams)
        )
    }

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "dashboard.hero.eyebrow"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(vm.formattedAlcohol(vm.todayGrams))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(limitCopy)
                .font(.caption)
                .foregroundStyle(.secondary)

            if vm.todayPct > 1.0 {
                Label(String(localized: "dashboard.risk.exceeded"),
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dpRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.dpRed.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    private var arcWithLabel: some View {
        ZStack {
            DPArcProgress(pct: vm.todayPct, color: arcColor, size: 100, strokeWidth: 9)
            Text("\(Int(min(vm.todayPct, 1.0) * 100))%")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(arcColor)
        }
    }

    private var arcColor: Color {
        switch vm.riskLevel {
        case .safe:     return .dpRiskLow
        case .caution:  return .dpRiskModerate
        case .exceeded: return .dpRiskHigh
        }
    }

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
