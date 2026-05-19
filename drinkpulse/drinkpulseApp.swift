import SwiftUI
import SwiftData

@main
struct drinkpulseApp: App {
    @AppStorage("dp_onboarding_done") private var onboardingDone = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DrinkTemplate.self,
            ConsumptionEvent.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema changed without a migration plan (dev-only: wipe and recreate).
            // Replace with a SchemaMigrationPlan before App Store submission.
            let storeURL = modelConfiguration.url
            try? FileManager.default.removeItem(at: storeURL)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            if onboardingDone {
                ContentView()
            } else {
                OnboardingView(onFinish: { onboardingDone = true })
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
