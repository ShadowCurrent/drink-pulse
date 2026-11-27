import SwiftData
import OSLog

/// Work the shell runs once when it first appears: the UI-test fixture seed and the
/// `RecordDeduplicator` sweep. Moved from `drinkpulseApp`, which now always shows the shell and
/// presents onboarding as a cover over it (plan 0048, D0048-1). While onboarding is up, the store
/// is empty, so both are cheap no-ops then.
@MainActor
enum ShellStartup {
    private static let logger = Logger(subsystem: "com.drinkpulse.app", category: "startup")

    static func run(context: ModelContext) {
        seedIfUITest(context: context)
        let clock = ContinuousClock()
        let start = clock.now
        RecordDeduplicator.sweep(in: context)
        let elapsed = start.duration(to: clock.now)
        let ms = elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000
        logger.notice("RecordDeduplicator.sweep finished in \(ms, privacy: .public) ms")
    }

    private static func seedIfUITest(context: ModelContext) {
        guard UITestSeed.isActive else { return }
        // UI-test path only, unchanged from `drinkpulseApp`: a failed count seeds as if empty.
        let existing = (try? context.fetchCount(FetchDescriptor<ConsumptionEvent>())) ?? 0
        guard existing == 0 else { return }
        UITestSeed.seedFixtures(into: context)
    }
}
