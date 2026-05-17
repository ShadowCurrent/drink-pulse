import SwiftUI
import SwiftData

@main
struct drinkpulseApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DrinkTemplate.self,
            ConsumptionEvent.self,
            UserProfile.self,
            GuidelineProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let count = (try? container.mainContext.fetchCount(FetchDescriptor<UserProfile>())) ?? 0
            if count == 0 { container.mainContext.insert(UserProfile()) }
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
