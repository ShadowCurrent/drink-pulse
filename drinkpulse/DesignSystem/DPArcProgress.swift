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

    /// Fill visibility: hidden only when nothing is logged.
    nonisolated static func fillOpacity(_ pct: Double) -> Double {
        pct > 0 ? 1 : 0
    }

    var body: some View {
        ZStack {
            ArcShape(from: 0, to: 1)
                .stroke(color.opacity(Self.trackOpacity(contrast)), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            // Always in the tree, hidden at 0: the first log of the day changes `to` and sweeps
            // from empty instead of inserting a new arc (a zero-length round cap would be a dot).
            ArcShape(from: 0, to: min(max(pct, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .opacity(Self.fillOpacity(pct))
                .animation(arcAnimation, value: pct)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(arcLabel)
        // Settled after the first frame, so the initial value draws without a sweep but the
        // first change after appear (often the first log of the day) animates.
        .task { hasSettledOnce = true }
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
