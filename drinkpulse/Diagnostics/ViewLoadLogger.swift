import SwiftUI
import OSLog

/// Dev-diagnostics view-load-time logger (source todo:
/// `add-view-load-time-logger-for-cold-start-and-tab-switches`). Measures how
/// long a top-level tab view takes to appear after a navigation event (cold
/// launch or tab switch), for Xcode-session/Instruments use only.
///
/// Logs only a static view-name string and an integer millisecond duration —
/// never drink contents, notes, body metrics, or any other user data — and is
/// entirely compiled out of Release builds via `#if DEBUG`.
#if DEBUG
@MainActor
enum ViewLoadLogger {
    private static let logger = Logger(subsystem: "com.drinkpulse.app", category: "performance")
    private static let signposter = OSSignposter(subsystem: "com.drinkpulse.app", category: "performance")

    private static var pending: (start: ContinuousClock.Instant, state: OSSignpostIntervalState)?

    /// Marks the moment a navigation that should be timed was requested
    /// (cold-start container ready, or a tab switch). A new mark supersedes
    /// any unconsumed prior one — ending its signpost interval first rather
    /// than leaking it — so a rapid double-navigation never leaves a
    /// dangling interval.
    static func markNavigationRequested() {
        if let pending {
            signposter.endInterval("ViewLoad", pending.state)
        }
        pending = (ContinuousClock().now, signposter.beginInterval("ViewLoad"))
    }

    /// Logs elapsed time since the last mark for the named view's appear,
    /// then consumes the mark. A no-op if this view was never reached via a
    /// tracked navigation (no pending mark).
    static func logAppear(_ viewName: String) {
        guard let pending else { return }
        signposter.endInterval("ViewLoad", pending.state)
        let elapsedMs = milliseconds(pending.start.duration(to: ContinuousClock().now))
        logger.notice("View '\(viewName, privacy: .public)' appeared in \(elapsedMs, privacy: .public) ms")
        Self.pending = nil
    }

    /// Whole-millisecond truncation of a `Duration`, for coarse `os.Logger`
    /// timing output only — mirrors the private `Duration.milliseconds`
    /// extension in `drinkpulseApp.swift`. Internal (not private) so the test
    /// target can exercise it via `@testable import`. `nonisolated`: pure
    /// arithmetic that touches no actor-isolated state, so it is callable
    /// from a plain test context without hopping to the main actor.
    nonisolated static func milliseconds(_ duration: Duration) -> Int64 {
        let (seconds, attoseconds) = duration.components
        return seconds * 1000 + attoseconds / 1_000_000_000_000_000
    }
}
#endif

/// Always-compiled call-site surface: a true no-op outside `#if DEBUG` so
/// `RootShellView` and `drinkpulseApp` never need their own `#if DEBUG`.
/// `@MainActor`-isolated to match every call site (`.onAppear`, `.onChange`,
/// `containerState` mutation) — all of which already run on the main actor —
/// so the mark happens synchronously, not on a later runloop tick.
enum ViewLoadNavigation {
    @MainActor
    static func markRequested() {
        #if DEBUG
        ViewLoadLogger.markNavigationRequested()
        #endif
    }
}

extension View {
    /// Logs this view's load duration since the last tracked navigation mark.
    /// Compiles to `self` (unmodified) in Release builds.
    func dp_logViewLoad(_ viewName: String) -> some View {
        #if DEBUG
        return onAppear { ViewLoadLogger.logAppear(viewName) }
        #else
        return self
        #endif
    }
}
