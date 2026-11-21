import SwiftUI

/// Daily-limit arc on the Today hero (plan 0046, D0046-3; prototype `HeroGauge`): the app's
/// `DPArcProgress` tinted by today's risk tone, with the percent inside in the brand ink. Size
/// follows Dynamic Type via `@ScaledMetric`. The arc element carries the accessibility label
/// ("Daily limit") and the percent value; the visible percent is hidden from VoiceOver.
struct HeroGauge: View {
    @ScaledMetric(relativeTo: .largeTitle) private var diameter: CGFloat = 88
    @ScaledMetric(relativeTo: .largeTitle) private var stroke: CGFloat = 9

    let fraction: Double
    let tone: Color
    let ink: Color

    var body: some View {
        ZStack {
            DPArcProgress(pct: fraction, color: tone, size: diameter, strokeWidth: stroke)
            Text(verbatim: DPArcProgress.percentText(fraction))
                .contentTransition(.numericText(value: fraction))
                .font(.headline)
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(stroke)
                .frame(width: diameter, height: diameter)
                .accessibilityHidden(true)
        }
        .padding(stroke / 2)
    }
}

#Preview("Risk states") {
    HStack(spacing: 16) {
        ForEach([0.45, 0.88, 1.6], id: \.self) { f in
            HeroGauge(fraction: f, tone: RiskLevel.from(pct: f).tone, ink: Brand.ink(for: .light))
        }
    }
    .padding()
}

#Preview("AX5") {
    HeroGauge(fraction: 0.62, tone: RiskLevel.caution.tone, ink: Brand.ink(for: .light))
        .padding()
        .dynamicTypeSize(.accessibility5)
}
