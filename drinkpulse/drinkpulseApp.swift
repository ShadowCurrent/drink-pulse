import SwiftUI
import SwiftData

@main
struct drinkpulseApp: App {
    @AppStorage(AppStorageKeys.onboardingDone) private var onboardingDone = false
    @AppStorage(AppStorageKeys.colorScheme) private var colorSchemeRaw: String = "system"
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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
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
                        .onAppear { seedIfUITest() }
                } else {
                    OnboardingView(onFinish: {
                        onboardingDone = true
                        forceOnboardingPending = false
                    })
                }
            }
            .preferredColorScheme(preferredColorScheme)
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
