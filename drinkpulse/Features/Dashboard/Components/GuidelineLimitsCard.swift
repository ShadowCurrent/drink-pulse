import SwiftUI

/// Guideline Limits card (plan 0046, D0046-5): Today, 7 Days and 30 Days as `LimitGaugeRow`s on
/// the existing view-model values. Today's rows keep the `overviewBar` Reduce Motion probe.
struct GuidelineLimitsCard: View {
    let vm: DashboardViewModel

    var body: some View {
        GroupBox {
            VStack(spacing: 16) {
                row(String(localized: "dashboard.section.today"), vm.todayGrams, vm.effectiveDailyLimitGrams)
                row(String(localized: "dashboard.overview.days7"), vm.sevenDayGrams, vm.weeklyLimitGrams)
                row(String(localized: "dashboard.overview.days30"), vm.thirtyDayGrams, vm.thirtyDayLimitGrams)
            }
            .padding(.top, 8)
        } label: {
            CardTitle("dashboard.overview.title")
        }
    }

    private func row(_ title: String, _ consumed: Double, _ limit: Double) -> some View {
        LimitGaugeRow(
            title: title,
            consumedGrams: consumed,
            limitGrams: limit,
            format: { vm.formattedNumber($0) },
            unitLabel: vm.unitLabel,
            motionProbeSite: "overviewBar"
        )
    }
}

#Preview("With data") {
    let vm = DashboardViewModel()
    let minus2 = Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
    vm.events = [
        ConsumptionEvent(consumptionDate: .now, volumeMl: 568, abv: 0.05, category: .beer, icon: "🍺"),
        ConsumptionEvent(consumptionDate: minus2, volumeMl: 330, abv: 0.05, category: .beer, icon: "🍺"),
    ]
    vm.profile = UserProfile.preview
    return GuidelineLimitsCard(vm: vm)
        .padding()
        .brandBackground()
}

#Preview("Empty · AX5") {
    GuidelineLimitsCard(vm: DashboardViewModel())
        .padding()
        .brandBackground()
        .dynamicTypeSize(.accessibility5)
}
