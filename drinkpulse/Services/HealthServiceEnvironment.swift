import SwiftUI

extension EnvironmentValues {
    /// Shared `HealthService` for the Apple Health write-back integration
    /// (plan-0036). Provided once at the app root (`drinkpulseApp`) so the
    /// Settings toggle (W4), the onboarding opt-in (W8) and the Add/Edit/Delete
    /// write hooks (W5) all read the SAME instance — its per-event serialization
    /// (which prevents an edit→delete race on one event) only holds within a
    /// single instance.
    ///
    /// Optional with a `nil` default so the generated `EnvironmentKey` default
    /// never constructs the `@MainActor` service in a nonisolated context (which
    /// would be a Swift 6 isolation error). The app root always supplies a real
    /// instance; consumers treat `nil` as "Health unavailable" and no-op.
    @Entry var healthService: HealthService? = nil
}
