import SwiftUI

/// One-point, non-text probe that reports a site's Reduce Motion decision to UI tests.
/// Rendered only under the `-dp_uitest` launch argument; nothing is rendered in production.
struct DPMotionProbe: View {
    let site: String
    let reduceMotion: Bool

    var body: some View {
        if UITestSeed.isActive {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("dp_motion.\(site)")
                .accessibilityLabel(DPMotion.isReduced(system: reduceMotion) ? "reduced" : "animated")
        }
    }
}

#Preview {
    Rectangle().fill(.gray).frame(width: 80, height: 40)
        .overlay { DPMotionProbe(site: "preview", reduceMotion: true) }
}
