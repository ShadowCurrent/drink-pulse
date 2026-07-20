import SwiftUI
import SwiftData
import UserNotifications

@main
struct drinkpulseApp: App {
    @AppStorage(AppStorageKeys.onboardingDone) private var onboardingDone = false
    @AppStorage(AppStorageKeys.colorScheme) private var colorSchemeRaw: String = "system"
    /// Retained delegate that routes a reminder tap to "open Add Drink"
    /// (plan-0016). Set as the notification-centre delegate in `init` so a
    /// cold launch from a tapped reminder is still captured.
    private let notificationHandler = NotificationActionHandler()
    /// Single shared Apple Health write-back service (plan-0036). Provided into
    /// the environment so Settings (W4), onboarding (W8) and the write hooks (W5)
    /// share one instance (its per-event serialization holds only per instance).
    /// Picks the real `HKHealthStore` adapter, or the non-prompting UI-test stub
    /// under `-dp_uitest`.
    @State private var healthService = HealthService()

    init() {
        // Clear cross-run UserDefaults pollution before any view reads it
        // (no-op in production). Keeps reminder UI tests deterministic.
        UITestSeed.resetTransientDefaults()
        // ENGG-07 tap-routing UI test hook: stands in for a real weekly-summary
        // notification tap having already happened before this cold launch.
        // Gated purely on the launch argument; inert whenever it is absent, i.e.
        // always inert in production.
        if UITestSeed.seedPendingOpenInsights {
            UserDefaults.standard.set(true, forKey: AppStorageKeys.pendingOpenInsights)
        }
        UNUserNotificationCenter.current().delegate = notificationHandler
    }
    /// One-shot flag: when `-dp_force_onboarding YES` is active, starts `true`
    /// and flips to `false` after `OnboardingView.onFinish` fires, allowing
    /// the normal `onboardingDone` gate to take over. Inert in production
    /// (UITestSeed.forceShowOnboarding is always false outside UI tests).
    @State private var forceOnboardingPending = UITestSeed.forceShowOnboarding

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": .light
        case "dark":  .dark
        default:      nil
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DrinkTemplate.self,
            ConsumptionEvent.self,
            UserProfile.self,
        ])
        // UI-test hook: in-memory store when -dp_uitest is present so tests
        // never touch the real user store. Inert (skipped) in production.
        if UITestSeed.isActive {
            do {
                return try UITestSeed.makeContainer(schema: schema)
            } catch {
                fatalError("UITestSeed: could not create in-memory container: \(error)")
            }
        }
        // CloudKit OFF (plan-0023 Phase B gated) — the single flip point lives in
        // StoreBootstrap.productionConfiguration.
        let modelConfiguration = StoreBootstrap.productionConfiguration(schema: schema)
        do {
            return try StoreBootstrap.makeContainer(schema: schema, configuration: modelConfiguration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                // forceOnboardingPending starts true when -dp_force_onboarding YES
                // is in the launch args (onboarding locale-default UI tests). It is
                // cleared by onFinish, after which normal routing resumes. Inert in
                // production — UITestSeed.forceShowOnboarding is always false there.
                if onboardingDone && !forceOnboardingPending {
                    RootShellView()
                        .onAppear {
                            seedIfUITest()
                            // Cross-device de-dup (plan-0023): collapse any records
                            // that share a uuid (backup re-import, or — Phase B —
                            // a CloudKit sync that delivered the same logical record
                            // twice). Idempotent: a clean store is a no-op.
                            RecordDeduplicator.sweep(in: sharedModelContainer.mainContext)
                        }
                } else {
                    OnboardingView(onFinish: {
                        onboardingDone = true
                        forceOnboardingPending = false
                    })
                }
            }
            .preferredColorScheme(preferredColorScheme)
            .environment(\.healthService, healthService)
        }
        .modelContainer(sharedModelContainer)
    }

    // Inserts deterministic fixtures into the in-memory store when the UI-test
    // hook is active. No-op in production (UITestSeed.isActive is false).
    private func seedIfUITest() {
        guard UITestSeed.isActive else { return }
        let context = sharedModelContainer.mainContext
        // Idempotent: .onAppear can fire more than once; only seed an empty store
        // so the shell re-appearing never inserts duplicate fixtures.
        let existing = (try? context.fetchCount(FetchDescriptor<ConsumptionEvent>())) ?? 0
        guard existing == 0 else { return }
        UITestSeed.seedFixtures(into: context)
    }
}
