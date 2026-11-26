import SwiftUI

// Debug-only onboarding rehearsal (plan 0052). `RootShellView` injects the action; the Settings
// Developer section calls it. Nil outside the shell, so previews show no-op rows.
#if DEBUG
extension EnvironmentValues {
    @Entry var replayOnboarding: (@MainActor () -> Void)?
}
#endif
