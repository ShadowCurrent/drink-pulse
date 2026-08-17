import Foundation
import SwiftData

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
            guidelineChoice: .who,
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

    private static func resolvedUnitSystem() -> UnitSystem {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_unit"),
              args.indices.contains(idx + 1)
        else { return .metric }
        return UnitSystem(rawValue: args[idx + 1]) ?? .metric
    }
}
