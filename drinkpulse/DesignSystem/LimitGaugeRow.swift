import SwiftUI

/// A labelled linear capacity gauge (plan 0046, D0046-5; prototype `CardComponents`): replaces
/// the hand-drawn capsule + `GeometryReader` bars. The tint is the risk tone of the fraction;
/// risk is never colour alone (percent and "over the limit" text carry it too).
struct LimitGaugeRow: View {
    @Environment(\.numbersCountDown) private var countsDown
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let consumedGrams: Double
    let limitGrams: Double
    /// Formats grams in the user's unit, without the unit label.
    let format: (Double) -> String
    let unitLabel: String
    /// Reduce Motion probe site for UI tests (Today's rows keep `overviewBar`).
    var motionProbeSite: String? = nil

    /// 0 when there is no limit (a profile without a daily limit must not divide by zero).
    nonisolated static func fraction(consumed: Double, limit: Double) -> Double {
        limit > 0 ? consumed / limit : 0
    }

    private var fraction: Double { Self.fraction(consumed: consumedGrams, limit: limitGrams) }
    private var tone: Color { RiskLevel.from(pct: fraction).tone }
    private var percentText: String { "\(Int(fraction * 100))%" }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Gauge(value: min(fraction, 1)) {
                LabeledContent {
                    Text(verbatim: "\(format(consumedGrams)) / \(format(limitGrams)) \(unitLabel) · \(percentText)")
                        .contentTransition(.numericText(countsDown: countsDown))
                        .monospacedDigit()
                        .foregroundStyle(Color.dpSecondaryText)
                } label: {
                    Text(title)
                }
                .font(.subheadline)
            }
            .gaugeStyle(.linearCapacity)
            .tint(tone)

            if fraction > 1 {
                Text(String(
                    format: String(localized: "dashboard.overview.overLimit"),
                    format(consumedGrams - limitGrams) + " " + unitLabel
                ))
                .font(.footnote)
                .foregroundStyle(tone)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityValue(Text(verbatim: accessibilityValueText))
        .overlay {
            if let motionProbeSite {
                DPMotionProbe(site: motionProbeSite, reduceMotion: reduceMotion)
            }
        }
    }

    private var accessibilityValueText: String {
        String(format: "%@ of %@ %@, %d percent",
               format(consumedGrams), format(limitGrams), unitLabel, Int(fraction * 100))
    }
}

#Preview("Rows") {
    GroupBox {
        VStack(spacing: 14) {
            LimitGaugeRow(title: "Today", consumedGrams: 17, limitGrams: 20,
                          format: { String(format: "%.1f", $0 / 10) }, unitLabel: "std")
            LimitGaugeRow(title: "7 Days", consumedGrams: 140, limitGrams: 100,
                          format: { String(format: "%.1f", $0 / 10) }, unitLabel: "std")
            LimitGaugeRow(title: "No limit", consumedGrams: 20, limitGrams: 0,
                          format: { String(format: "%.1f", $0 / 10) }, unitLabel: "std")
        }
    } label: {
        CardTitle("Guideline Limits")
    }
    .groupBoxStyle(BrandCardStyle())
    .padding()
    .brandBackground()
}

#Preview("Rows · Dark") {
    GroupBox {
        LimitGaugeRow(title: "7 Days", consumedGrams: 140, limitGrams: 100,
                      format: { String(format: "%.1f", $0 / 10) }, unitLabel: "std")
    }
    .groupBoxStyle(BrandCardStyle())
    .padding()
    .brandBackground()
    .preferredColorScheme(.dark)
}

#Preview("Rows · AX5") {
    GroupBox {
        LimitGaugeRow(title: "30 Days", consumedGrams: 300, limitGrams: 430,
                      format: { String(format: "%.1f", $0 / 10) }, unitLabel: "std")
    }
    .groupBoxStyle(BrandCardStyle())
    .padding()
    .dynamicTypeSize(.accessibility5)
}
