import SwiftUI

/// First-run entrance (plan 0048, D0048-12, prototype round 20): after onboarding's Done the
/// cover slides down onto Today, then Today's cards rise in one after another. The shell sets
/// `firstRunRevealed` to false only while the first-run cover is up and to true in the cover's
/// `onDismiss`; the default `true` leaves every other screen and later launches unchanged.
/// Reduce Motion: cards fade in place, no movement and no stagger (HIG Motion).
extension EnvironmentValues {
    @Entry var firstRunRevealed = true
}

/// The entrance's motion values, kept pure so they are unit tested.
nonisolated enum FirstRunRevealMotion {
    static let hiddenOffset: CGFloat = 24
    static let stagger: Double = 0.07

    static func offset(revealed: Bool, reduced: Bool) -> CGFloat {
        revealed || reduced ? 0 : hiddenOffset
    }

    static func delay(order: Int, reduced: Bool) -> Double {
        reduced ? 0 : stagger * Double(order)
    }
}

private struct FirstRunReveal: ViewModifier {
    @Environment(\.firstRunRevealed) private var revealed
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    let order: Int

    func body(content: Content) -> some View {
        let reduced = DPMotion.isReduced(system: systemReduceMotion)
        content
            .opacity(revealed ? 1 : 0)
            .offset(y: FirstRunRevealMotion.offset(revealed: revealed, reduced: reduced))
            .animation(
                reduced
                    ? .easeInOut(duration: 0.25)
                    : .smooth(duration: 0.5).delay(FirstRunRevealMotion.delay(order: order, reduced: false)),
                value: revealed
            )
    }
}

extension View {
    /// First-run entrance; `order` sets the stagger: 0 first, then 70 ms per step.
    func firstRunReveal(_ order: Int) -> some View { modifier(FirstRunReveal(order: order)) }
}
