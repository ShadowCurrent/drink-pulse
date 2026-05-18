import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label(String(localized: "tab.home"), systemImage: "house.fill") }

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label(String(localized: "tab.history"), systemImage: "calendar") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(String(localized: "tab.settings"), systemImage: "gear") }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(UserProfile.preview)
    return ContentView()
        .modelContainer(container)
}
