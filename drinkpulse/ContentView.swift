import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab(String(localized: "tab.home"), systemImage: "house.fill") {
                NavigationStack {
                    DashboardView()
                }
            }
            Tab(String(localized: "tab.history"), systemImage: "calendar") {
                NavigationStack {
                    HistoryView()
                }
            }
            Tab(String(localized: "tab.settings"), systemImage: "gear") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self, GuidelineProfile.self],
            inMemory: true
        )
}
