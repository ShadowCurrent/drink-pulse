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
        }
        .padding(24)
    }
}
