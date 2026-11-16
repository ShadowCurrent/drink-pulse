import SwiftUI

/// Single decision seam for Reduce Motion.
///
/// `EnvironmentValues.accessibilityReduceMotion` is get-only, so a UI test cannot
/// override it through the environment and `XCUIDevice` has no Reduce Motion control.
/// `forced` is the UI-test-only override (`UITestSeed.forceReduceMotion`, gated on
/// `-dp_uitest`); in production it is always `false`.
nonisolated enum DPMotion {

    /// `true` when the system preference is on or the UI-test override forces it.
    static func isReduced(system: Bool, forced: Bool = UITestSeed.forceReduceMotion) -> Bool {
        system || forced
    }

    /// The animation to apply, or `nil` when Reduce Motion is on.
    static func animation(
        _ animation: Animation?,
        reduceMotion: Bool,
        forced: Bool = UITestSeed.forceReduceMotion
    ) -> Animation? {
        isReduced(system: reduceMotion, forced: forced) ? nil : animation
    }
}
