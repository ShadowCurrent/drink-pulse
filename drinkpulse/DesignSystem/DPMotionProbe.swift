import SwiftUI

/// One-point, non-text probe that reports a site's Reduce Motion decision to UI tests.
/// Rendered only under the `-dp_uitest` launch argument; nothing is rendered in production.
struct DPMotionProbe: View {
    let site: String
    let reduceMotion: Bool

    /// Test-only state word. A typed `String`, so it does not enter the string catalog.
    private var stateLabel: String {
        let reduced: String = "reduced"
        let animated: String = "animated"
        return DPMotion.isReduced(system: reduceMotion) ? reduced : animated
    }

    var body: some View {
        if UITestSeed.isActive {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("dp_motion.\(site)")
                .accessibilityLabel(stateLabel)
        }
    }
}

#Preview {
    Rectangle().fill(.gray).frame(width: 80, height: 40)
        .overlay { DPMotionProbe(site: "preview", reduceMotion: true) }
}
