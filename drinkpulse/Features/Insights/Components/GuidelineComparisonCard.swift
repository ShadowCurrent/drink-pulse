import SwiftUI

/// Guideline Comparison (plan 0046, D0046-12): one `LimitGaugeRow` per guideline over the active
/// period; the user's own guideline is marked with a check mark in its title.
struct GuidelineComparisonCard: View {
    let vm: InsightsViewModel

    var body: some View {
        GroupBox {
            VStack(spacing: 16) {
                ForEach(vm.guidelineComparisons) { item in
                    LimitGaugeRow(
                        title: item.guideline == vm.guidelineChoice ? "\(item.name) ✓" : item.name,
                        consumedGrams: item.consumedGrams,
                        limitGrams: item.limitGrams,
                        format: { vm.formattedNumber($0) },
                        unitLabel: vm.displayUnitLabel
                    )
                }
            }
            .padding(.top, 8)
        } label: {
            CardTitle("insights.section.guidelineComparison")
        }
    }
}

#Preview("Comparison") {
    ScrollView { GuidelineComparisonCard(vm: InsightsViewModel.preview).padding() }
        .brandBackground()
}

#Preview("Comparison · AX5") {
    ScrollView { GuidelineComparisonCard(vm: InsightsViewModel.preview).padding() }
        .brandBackground()
        .dynamicTypeSize(.accessibility5)
}
