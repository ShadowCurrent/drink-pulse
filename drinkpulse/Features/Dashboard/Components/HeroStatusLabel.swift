import SwiftUI

/// Status text + risk glyph on the Today hero (plan 0046, D0046-3; prototype round 9, owner
/// choice "cut-out"): glyph fill = the arc's risk tone; mark white in Light, mesh navy in Dark,
/// so the glyph keeps contrast on the Frost mesh. Replace communicates a change of state
/// (HIG SF Symbols › Animations).
struct HeroStatusLabel: View {
    @Environment(\.colorScheme) private var scheme
    let level: RiskLevel

    private var markColor: Color {
        scheme == .dark ? Brand.heroMesh(for: .dark)[1] : .white
    }

    var body: some View {
        Label {
            Text(level.statusTitle)
        } icon: {
            Image(systemName: level.statusSymbol)
                .symbolRenderingMode(.palette)
                .foregroundStyle(markColor, level.tone)
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityIdentifier("today.status")
    }
}

#Preview("Levels") {
    VStack(alignment: .leading, spacing: 12) {
        HeroStatusLabel(level: .safe)
        HeroStatusLabel(level: .caution)
        HeroStatusLabel(level: .exceeded)
    }
    .font(.subheadline.weight(.semibold))
    .padding()
}

#Preview("Levels · Dark") {
    VStack(alignment: .leading, spacing: 12) {
        HeroStatusLabel(level: .safe)
        HeroStatusLabel(level: .exceeded)
    }
    .font(.subheadline.weight(.semibold))
    .padding()
    .background(Brand.heroMesh(for: .dark)[1])
    .preferredColorScheme(.dark)
}
