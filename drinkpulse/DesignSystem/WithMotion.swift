import SwiftUI

/// The single helper for animated store mutations (insert, duplicate, delete).
///
/// Runs `change` exactly once: inside `withAnimation(.snappy)`, or without animation when
/// Reduce Motion is on. The decision goes through `DPMotion`, so the UI-test Reduce Motion
/// override applies here too. Pass the system value of `accessibilityReduceMotion`.
@MainActor
func withMotion(reduceMotion: Bool, _ change: () -> Void) {
    if let animation = DPMotion.animation(.snappy, reduceMotion: reduceMotion) {
        withAnimation(animation, change)
    } else {
        change()
    }
}
