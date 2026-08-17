import SwiftUI
import OSLog

#if DEBUG
@MainActor
enum ViewLoadLogger {
    private static let logger = Logger(subsystem: "com.drinkpulse.app", category: "performance")
    private static let signposter = OSSignposter(subsystem: "com.drinkpulse.app", category: "performance")

    private static var pending: (start: ContinuousClock.Instant, state: OSSignpostIntervalState)?

    static func markNavigationRequested() {
        if let pending {
            signposter.endInterval("ViewLoad", pending.state)
        }
        pending = (ContinuousClock().now, signposter.beginInterval("ViewLoad"))
    }

    static func logAppear(_ viewName: String) {
        guard let pending else { return }
        signposter.endInterval("ViewLoad", pending.state)
        let elapsedMs = milliseconds(pending.start.duration(to: ContinuousClock().now))
        logger.notice("View '\(viewName, privacy: .public)' appeared in \(elapsedMs, privacy: .public) ms")
        Self.pending = nil
    }

    nonisolated static func milliseconds(_ duration: Duration) -> Int64 {
        let (seconds, attoseconds) = duration.components
        return seconds * 1000 + attoseconds / 1_000_000_000_000_000
    }
}
#endif

enum ViewLoadNavigation {
    @MainActor
    static func markRequested() {
        #if DEBUG
        ViewLoadLogger.markNavigationRequested()
        #endif
    }
}

extension View {
    func dp_logViewLoad(_ viewName: String) -> some View {
        #if DEBUG
        return onAppear { ViewLoadLogger.logAppear(viewName) }
        #else
        return self
        #endif
    }
}
