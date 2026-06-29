import Foundation
import SwiftData

/// Launch-argument-gated test fixture support.
///
/// ALL behaviour in this file is guarded by `isActive`, which checks for
/// `-dp_uitest` in the process argument list. The check is resolved once at
/// app start from `ProcessInfo.processInfo.arguments` — an immutable,
/// process-scoped value — so the guard is always inert in production builds
/// and App Store submissions. No runtime flag, no UserDefaults, no network.
///
/// Usage (UI test side):
/// ```swift
/// app.launchArguments += ["-dp_uitest", "YES"]
/// app.launchArguments += ["-dp_uitest_unit", "usCustomary"] // optional
/// ```
///
/// When active the app:
/// - Uses an in-memory SwiftData store (never touches the real user store).
/// - Inserts a deterministic `UserProfile` + a 500 ml 5% beer `ConsumptionEvent`.
/// - Lets onboarding state and locale be driven by existing launch args
///   (`-dp_onboarding_done YES`, `-AppleLocale en_US`, etc.).
enum UITestSeed {

    /// `true` only when `-dp_uitest` is present in the process arguments.
    /// Evaluated once; never mutated. Inert in production.
    static let isActive: Bool = ProcessInfo.processInfo.arguments.contains("-dp_uitest")

    /// `true` when `-dp_force_onboarding YES` is in the process arguments.
    /// When true the app skips the AppStorage check and shows `OnboardingView`
    /// unconditionally — used by onboarding locale-default UI tests so that
    /// writing `onboardingDone = true` inside `OnboardingView.onFinish` is not
    /// blocked by an NSArgumentDomain override of `dp_onboarding_done`.
    /// Inert in production.
    static let forceShowOnboarding: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_force_onboarding"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].uppercased() == "YES"
    }()

    /// Clears transient `UserDefaults` that leak between UI-test runs — the
    /// simulator persists app-domain defaults across reinstalls, so a prior
    /// run that toggled the reminder on would leave `dp_reminder_enabled = true`
    /// and break the next run's "starts off" assumption. Resets only the
    /// reminder opt-in to its known-off baseline (no fixture seeds it). Gated on
    /// `isActive`; inert in production. The Health write-back opt-in (plan-0036)
    /// gets the same treatment so its "starts off" UI-test baseline holds.
    nonisolated static func resetTransientDefaults() {
        guard isActive else { return }
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.reminderEnabled)
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.healthWriteEnabled)
    }

    // MARK: - Container

    /// Returns an in-memory `ModelContainer` for the given schema.
    /// Call only when `isActive` is `true`.
    @MainActor
    static func makeContainer(schema: Schema) throws -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: [config])
    }

    // MARK: - Fixtures

    /// Seeds a deterministic profile and a 500 ml 5% beer event into `context`.
    ///
    /// The profile's `unitSystem` is controlled by the `-dp_uitest_unit` launch
    /// argument (values: `"metric"`, `"usCustomary"`, `"imperial"`; default: `"metric"`).
    ///
    /// Seeding is skipped when `-dp_force_onboarding YES` is set, because in that
    /// case the onboarding flow creates the profile itself — inserting a second
    /// profile would make Settings show the wrong unit.
    ///
    /// Fixture data is entirely synthetic — no PII, no health data, no real user
    /// values. The beer volume (500 ml) matches the unit-integrity regression test.
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

        // Fixture selection is mutually exclusive and priority-ordered so exactly
        // one synthetic data path runs: the multi-day Insights set takes precedence
        // over provenance, which takes precedence over the default single beer.
        if seedMultiDayFixture {
            seedMultiDayEvents(into: context)
            return
        }

        if seedProvenanceFixture {
            // plan-0031: a 568 ml beer logged in imperial. Its name resolves to
            // "Pint" via enteredUnit and must stay "Pint" (never "Stovepipe")
            // even when the profile unit is switched to US.
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

    /// `true` when `-dp_uitest_provenance YES` is set — seeds a single
    /// imperial-entered 568 ml beer instead of the default 500 ml event, for the
    /// provenance UI test. Inert in production.
    private static let seedProvenanceFixture: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_provenance"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].uppercased() == "YES"
    }()

    /// `true` when `-dp_uitest_dataset multiday` is set — seeds a deterministic
    /// spread of synthetic events across the last ~14 days (multiple weekdays,
    /// two categories, varied volumes) so the Insights period picker, area chart,
    /// weekday bar chart and guideline-comparison card all have data to render.
    /// Additive, synthetic-only, no PII. Inert in production.
    static let seedMultiDayFixture: Bool = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_dataset"),
              args.indices.contains(idx + 1)
        else { return false }
        return args[idx + 1].lowercased() == "multiday"
    }()

    private static func resolvedUnitSystem() -> UnitSystem {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-dp_uitest_unit"),
              args.indices.contains(idx + 1)
        else { return .metric }
        return UnitSystem(rawValue: args[idx + 1]) ?? .metric
    }
}
