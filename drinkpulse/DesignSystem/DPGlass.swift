import SwiftUI

enum DPGlassSize {
    case chip   // 16 — badges, tags
    case card   // 22 — content cards (default)
    case sheet  // 28 — sheet top corners

    var cornerRadius: CGFloat {
        switch self {
        case .chip:  14
        case .card:  24
        case .sheet: 20
        }
    }
}

extension View {
    func dpGlassCard(_ size: DPGlassSize = .card) -> some View {
        modifier(DPGlassModifier(size: size))
    }
}

private struct DPGlassModifier: ViewModifier {
    let size: DPGlassSize

    func body(content: Content) -> some View {
        content
            .glassEffect(.regular, in: .rect(cornerRadius: size.cornerRadius))
    }
}

// Insights chart scrub-callout background ONLY. Liquid Glass and system
// materials must never be used as an Insights scrub-callout background
// inside a Swift Charts `.annotation` again: an on-device probe found
// `.glassEffect` renders zero pixels and `.regularMaterial` renders an
// opaque black rectangle in that context, and Apple DTS states plainly
// that "Liquid Glass is not a part of Swift Charts" (Developer Forums
// thread 788041). See
// `.planning/debug/insights-chart-scrub-marker-height-and-missing-x-value.md`
// for the full on-device evidence trail. This modifier is intentionally
// separate from `DPGlassModifier`/`dpGlassCard(_:)` — do not merge them.
extension View {
    func dpChartCalloutBackground(cornerRadius: CGFloat = DPGlassSize.chip.cornerRadius) -> some View {
        modifier(DPChartCalloutBackgroundModifier(cornerRadius: cornerRadius))
    }
}

private struct DPChartCalloutBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(shape.fill(Color(.secondarySystemGroupedBackground)))
            .overlay(shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
    }
}

#Preview("Light / Dark") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Glass Card")
                .font(.headline)
                .padding(20)
                .frame(maxWidth: .infinity)
                .dpGlassCard(.card)
            Text("Chip")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .dpGlassCard(.chip)
            Text("Chart Callout")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .dpChartCalloutBackground()
        }
        .padding(24)
    }
}
