import SwiftUI

// Debug-only onboarding rehearsal (plan 0052). `RootShellView` injects the action; the Settings
// Developer section calls it. Nil outside the shell, so previews show no-op rows.
#if DEBUG
/// Starts the rehearsal, called like a function (`replayOnboarding?()`), as `DismissAction` is.
/// A bare closure in `@Entry` cannot be compared, so every shell update would invalidate its
/// readers (compiler warning). Only the shell creates one, and its closure only writes the
/// shell's `@State`, so every instance is interchangeable: equality is always `true`.
struct OnboardingReplayAction: Equatable {
    let action: @MainActor () -> Void

    @MainActor
    func callAsFunction() { action() }

    static func == (lhs: Self, rhs: Self) -> Bool { true }
}

extension EnvironmentValues {
    @Entry var replayOnboarding: OnboardingReplayAction?
}
#endif
