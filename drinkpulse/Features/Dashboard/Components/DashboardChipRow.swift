import SwiftUI

struct DashboardChipRow: View {
    let vm: DashboardViewModel

    var body: some View {
        HStack(spacing: 12) {
            DPChip(
                icon: "flame.fill",
                value: "\(vm.todayCaloriesKcal) kcal",
                label: String(localized: "dashboard.chip.calories"),
                accent: .dpAmber
            )
            DPChip(
                icon: "bolt.fill",
                value: "\(vm.todayDrinkCount)",
                label: String(localized: "dashboard.chip.drinks"),
                accent: .dpPurple
            )
        }
    }
}

#Preview {
    DashboardChipRow(vm: DashboardViewModel())
        .padding()
}
