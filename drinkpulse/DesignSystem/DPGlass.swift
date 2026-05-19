import SwiftUI

enum DPGlassSize {
    case chip   // 16 — badges, tags
    case card   // 22 — content cards (default)
    case sheet  // 28 — sheet top corners

    var cornerRadius: CGFloat {
        switch self {
        case .chip:  16
        case .card:  22
        case .sheet: 28
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
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: size.cornerRadius))
        } else {
            let r = size.cornerRadius
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: r))
                .overlay {
                    RoundedRectangle(cornerRadius: r)
                        .stroke(
                            scheme == .dark ? .white.opacity(0.12) : .white.opacity(0.75),
                            lineWidth: 0.5
                        )
                }
                .shadow(
                    color: scheme == .dark ? .black.opacity(0.30) : .black.opacity(0.06),
                    radius: scheme == .dark ? 24 : 16,
                    y: scheme == .dark ? 4 : 2
                )
        }
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
