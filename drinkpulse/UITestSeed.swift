import Foundation
import SwiftData

// UI-test hooks compile in Debug only (plan 0052, D0052-5). Release gets the stub at the end of
// this file: same API, every flag `false`, so production call sites build unchanged.
#if DEBUG
enum UITestSeed {

    nonisolated static let isActive: Bool = ProcessInfo.processInfo.arguments.contains("-dp_uitest")

    static let forceShowOnboarding: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_force_onboarding"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].uppercased() == "YES"
    }()

    static let deleteProfileMidSession: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_delete_profile_midsession"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].uppercased() == "YES"
    }()

    static let seedPendingOpenInsights: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_pending_open_insights"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].uppercased() == "YES"
    }()

    static let armWarmWeeklySummaryTap: Bool = {
        guard isActive else { return false }
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_warm_weekly_tap"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].uppercased() == "YES"
    }()

    nonisolated static let forceReduceMotion: Bool = {
        guard isActive else { return false }
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_reduce_motion"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].uppercased() == "YES"
    }()

    static let forceStoreFailure: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_force_store_failure"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].uppercased() == "YES"
    }()

    nonisolated static func resetTransientDefaults() {
        guard isActive else { return }
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.reminderEnabled)
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.healthWriteEnabled)
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.weeklySummaryEnabled)
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.pendingOpenInsights)
        UserDefaults.standard.removeObject(forKey: UITestHealthStore.sampleCountKey)
    }

    // MARK: - Container

    struct UITestForcedStoreFailure: Error {}

    @MainActor
    static func makeContainer(schema: Schema) throws -> ModelContainer {
        if forceStoreFailure {
            throw UITestForcedStoreFailure()
        }
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: [config])
    }

    // MARK: - Fixtures

    @MainActor
    static func seedFixtures(into context: ModelContext) {
        guard !forceShowOnboarding else { return }
        let unitSystem = resolvedUnitSystem()
        let profile = UserProfile(
            bodyWeightKg: 80.0,
            biologicalSex: .male,
            guidelineChoice: resolvedGuideline(),
            unitSystem: unitSystem
        )
        context.insert(profile)

        if seedMultiDayFixture {
            seedMultiDayEvents(into: context)
            return
        }

        if seedPaginationStressFixture {
            seedPaginationStressEvents(into: context)
            return
        }

        if seedSameDayFixture {
            seedSameDayEvents(into: context)
            return
        }

        if seedOutsideWindowFixture {
            seedOutsideWindowEvents(into: context)
            return
        }

        if seedSearchFixture {
            seedSearchEvents(into: context)
            return
        }

        // Profile only, no events: the History empty state (plan 0045, D0045-10).
        if seedEmptyFixture { return }

        if datasetArgument == "overweekly" {
            seedOverWeeklyEvents(into: context)
            return
        }

        if datasetArgument == "alcoholfreetoday" {
            seedAlcoholFreeTodayEvents(into: context)
            return
        }

        if seedProvenanceFixture {
            let pint = ConsumptionEvent(
                consumptionDate: .now, volumeMl: 568, abv: 0.05, quantity: 1,
                enteredUnit: .imperial, category: .beer, icon: "🍺"
            )
            context.insert(pint)
            return
        }

        let beer = ConsumptionEvent(
            consumptionDate: .now,
            volumeMl: 500,
            abv: 0.05,
            quantity: 1,
            category: .beer,
            icon: "🍺"
        )
        context.insert(beer)
    }

    // MARK: - Private

    private static let seedProvenanceFixture: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_provenance"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].uppercased() == "YES"
    }()

    static let seedMultiDayFixture: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_dataset"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].lowercased() == "multiday"
    }()

    static let seedPaginationStressFixture: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_dataset"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].lowercased() == "paginationstress"
    }()

    static let seedSameDayFixture: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_dataset"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].lowercased() == "sameday"
    }()

    static let seedOutsideWindowFixture: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_dataset"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].lowercased() == "outsidewindow"
    }()

    static let seedEmptyFixture: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_dataset"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].lowercased() == "empty"
    }()

    /// The lowercased `-dp_uitest_dataset` value, if any.
    static let datasetArgument: String? = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_dataset"),
              args.indices.contains(idx + 1)
        else { return nil }
        return args[idx + 1].lowercased()
    }()

    static let seedSearchFixture: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_dataset"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].lowercased() == "search"
    }()

    private static func resolvedUnitSystem() -> UnitSystem {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_unit"),
              args.indices.contains(idx + 1)
        else { return .metric }
        return UnitSystem(rawValue: args[idx + 1]) ?? .metric
    }

    /// `-dp_uitest_guideline <rawValue>` seeds the profile's guideline (default WHO), e.g. `uk`
    /// for a guideline without a daily limit (plan 0046 review).
    private static func resolvedGuideline() -> GuidelineChoice {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_guideline"),
              args.indices.contains(idx + 1)
        else { return .who }
        return GuidelineChoice(rawValue: args[idx + 1]) ?? .who
    }
}
#else
enum UITestSeed {
    nonisolated static let isActive = false
    static let forceShowOnboarding = false
    static let deleteProfileMidSession = false
    static let seedPendingOpenInsights = false
    static let armWarmWeeklySummaryTap = false
    nonisolated static let forceReduceMotion = false

    struct UITestForcedStoreFailure: Error {}

    nonisolated static func resetTransientDefaults() {}

    /// Unreachable in Release: callers check `isActive` first.
    @MainActor
    static func makeContainer(schema: Schema) throws -> ModelContainer {
        throw UITestForcedStoreFailure()
    }

    @MainActor
    static func seedFixtures(into context: ModelContext) {}
}
#endif
