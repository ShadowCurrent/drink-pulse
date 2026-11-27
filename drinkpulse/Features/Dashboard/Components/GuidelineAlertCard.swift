import SwiftUI

/// Weekly limit warning (plan 0046, D0046-7): a `GroupBox` with a `Label` in the exceeded tone,
/// not a custom tinted card. Shown when the rolling 7-day total is over the weekly limit.
struct GuidelineAlertCard: View {
    let weeklyPct: Double
    let guidelineName: String

    private var percentText: String { "\(Int((weeklyPct * 100).rounded()))%" }

    var body: some View {
        GroupBox {
            Text(String(format: String(localized: "dashboard.alert.body"), percentText, guidelineName))
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(String(localized: "dashboard.alert.title"), systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(RiskLevel.exceeded.tone)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("today.alert")
    }
}

#Preview("Over limit") {
    GuidelineAlertCard(weeklyPct: 1.3, guidelineName: "WHO (Global)")
        .padding()
        .brandBackground()
}

#Preview("Over limit · Dark") {
    GuidelineAlertCard(weeklyPct: 1.3, guidelineName: "WHO (Global)")
        .padding()
        .brandBackground()
        .preferredColorScheme(.dark)
}

#Preview("Over limit · AX5") {
    GuidelineAlertCard(weeklyPct: 1.3, guidelineName: "UK NHS")
        .padding()
        .brandBackground()
        .dynamicTypeSize(.accessibility5)
}
