import SwiftData

/// Lifecycle of the app's `ModelContainer` (STARTUP-02, ADR-0009).
///
/// `sharedModelContainer` used to be an eagerly-evaluated stored property
/// that ran `ModelContainer(for:...)` synchronously as part of `App.init`,
/// blocking the first frame on disk I/O and crashing the whole app via
/// `fatalError` if it threw. `drinkpulseApp` now holds a `@State private var
/// containerState: ContainerLoadState` populated from a `.task` that runs
/// after the first frame renders, so `.loading` is drawn immediately and the
/// real container-open work never blocks launch.
enum ContainerLoadState {
    /// Nothing has resolved yet — shown for the brief window between the
    /// first frame rendering and `StoreBootstrap.makeContainer` returning.
    case loading
    /// The container opened successfully; `.modelContainer(_:)` attaches
    /// only to this case's subtree (STARTUP-02, Pitfall 2).
    case ready(ModelContainer)
    /// The container failed to open even after `StoreBootstrap.makeContainer`'s
    /// own internal non-destructive recovery attempt (STARTUP-03).
    case failed(StartupError)
}
