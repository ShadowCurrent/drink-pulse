import SwiftUI

struct DPArcProgress: View {
    let pct: Double
    let color: Color
    var size: CGFloat = 100
    var strokeWidth: CGFloat = 9

    @State private var hasSettledOnce = false

    var body: some View {
        ZStack {
            ArcShape(from: 0, to: 1)
                .stroke(color.opacity(0.2), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            if pct > 0 {
                ArcShape(from: 0, to: min(pct, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                    .animation(hasSettledOnce ? .easeOut(duration: 0.4) : nil, value: pct)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(arcLabel)
        .onChange(of: pct) { _, _ in hasSettledOnce = true }
    }

    private var arcLabel: String {
        let pctInt = Int((min(pct, 1) * 100).rounded())
        return "\(pctInt)% of daily limit"
    }
}

nonisolated private struct ArcShape: Shape {
    let from: Double
    let to: Double

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
            DPArcProgress(pct: 0.65, color: .dpRiskLow,      size: 120, strokeWidth: 10)
            DPArcProgress(pct: 0.90, color: .dpRiskModerate, size: 100, strokeWidth: 9)
            DPArcProgress(pct: 1.25, color: .dpRiskHigh,     size: 80,  strokeWidth: 8)
            DPArcProgress(pct: 0,    color: .dpRiskLow)
        }
        .padding()
    }
}
