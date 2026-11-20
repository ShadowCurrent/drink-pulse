import SwiftUI

struct DPArcProgress: View {
    let pct: Double
    let color: Color
    var size: CGFloat = 100
    var strokeWidth: CGFloat = 9

    @State private var hasSettledOnce = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    /// Track opacity: 0.2, doubled under Increase Contrast so the unfilled arc stays visible.
    nonisolated static func trackOpacity(_ contrast: ColorSchemeContrast) -> Double {
        contrast == .increased ? 0.4 : 0.2
    }

    var body: some View {
        ZStack {
            ArcShape(from: 0, to: 1)
                .stroke(color.opacity(Self.trackOpacity(contrast)), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            if pct > 0 {
                ArcShape(from: 0, to: min(pct, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                    .animation(arcAnimation, value: pct)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(arcLabel)
        .onChange(of: pct) { _, _ in hasSettledOnce = true }
        // Outside the single accessibility element above, so the probe stays its own element.
        .overlay { DPMotionProbe(site: "heroArc", reduceMotion: reduceMotion) }
    }

    private var arcAnimation: Animation? {
        guard hasSettledOnce else { return nil }
        return DPMotion.animation(.easeOut(duration: 0.4), reduceMotion: reduceMotion)
    }

    private var arcLabel: String {
        let pctInt = Int((min(pct, 1) * 100).rounded())
        return "\(pctInt)% of daily limit"
    }
}

/// Arc from `from` to `to` (fractions of the 240° sweep). `animatableData` animates `to`, so a
/// change of the fill sweeps instead of jumping (SwiftUI docs, `Animatable.animatableData`).
nonisolated struct ArcShape: Shape {
    var from: Double
    var to: Double

    var animatableData: Double {
        get { to }
        set { to = newValue }
    }

    private static let startDeg = 60.0
    private static let sweepDeg = 240.0

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2 - 1,
            startAngle: .degrees(Self.startDeg + Self.sweepDeg * from),
            endAngle:   .degrees(Self.startDeg + Self.sweepDeg * to),
            clockwise: false
        )
        return p
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack(spacing: 32) {
            DPArcProgress(pct: 0.65, color: RiskLevel.safe.tone,     size: 120, strokeWidth: 10)
            DPArcProgress(pct: 0.90, color: RiskLevel.caution.tone, size: 100, strokeWidth: 9)
            DPArcProgress(pct: 1.25, color: RiskLevel.exceeded.tone,size: 80,  strokeWidth: 8)
            DPArcProgress(pct: 0,    color: RiskLevel.safe.tone)
        }
        .padding()
    }
}
