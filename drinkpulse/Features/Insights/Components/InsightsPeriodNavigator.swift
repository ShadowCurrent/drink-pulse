import SwiftUI

/// Previous / next period with system bordered circle buttons (plan 0046, D0046-8; prototype
/// round 2). The centre is plain text; jumping back to the current period is the toolbar
/// "Today" button (Calendar pattern), so there is no "NOW" pill and no tappable centre.
struct InsightsPeriodNavigator: View {
    @Environment(\.numbersCountDown) private var countsDown
    let vm: InsightsViewModel
    let step: (Int) -> Void

    var body: some View {
        HStack {
            Button(String(localized: "insights.nav.prevPeriod"), systemImage: "chevron.left") { step(-1) }
                .disabled(vm.activeOffset <= vm.minAllowedOffset)
                .accessibilityIdentifier("insights.nav.previous")
            Spacer(minLength: 8)
            VStack(spacing: 2) {
                Text(vm.friendlyLabel)
                    .font(.headline)
                Text(vm.rangeLabel)
                    .font(.subheadline)
                    .foregroundStyle(Color.dpSecondaryText)
            }
            .contentTransition(.numericText(countsDown: countsDown))
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            Spacer(minLength: 8)
            Button(String(localized: "insights.nav.nextPeriod"), systemImage: "chevron.right") { step(1) }
                .disabled(vm.isCurrentPeriod)
                .accessibilityIdentifier("insights.nav.next")
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
    }
}

#Preview {
    InsightsPeriodNavigator(vm: InsightsViewModel.preview, step: { _ in })
        .padding()
        .brandBackground()
}

#Preview("AX5") {
    InsightsPeriodNavigator(vm: InsightsViewModel.preview, step: { _ in })
        .padding()
        .brandBackground()
        .dynamicTypeSize(.accessibility5)
}
