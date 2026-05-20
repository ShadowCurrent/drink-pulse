import SwiftUI
import SwiftData

struct RootShellView: View {
    @State private var selectedTab: AppTab = .home
    @State private var lastRealTab: AppTab = .home
    @State private var showAddDrink = false

    var body: some View {
        if #available(iOS 26, *) {
            tabContent
                .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            tabContent
        }
    }

    private var tabContent: some View {
        TabView(selection: $selectedTab) {
            Tab("tab.home", systemImage: "house", value: AppTab.home) {
                NavigationStack { DashboardView() }
            }
            Tab("tab.insights", systemImage: "chart.bar", value: AppTab.insights) {
                NavigationStack { InsightsView() }
            }
            Tab("tab.history", systemImage: "clock", value: AppTab.history) {
                NavigationStack { HistoryView() }
            }
            Tab("tab.settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack { SettingsView() }
            }
            Tab("tab.add", systemImage: "plus", value: AppTab.addDrink, role: .search) {
                Color.clear
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .addDrink {
                selectedTab = lastRealTab
                showAddDrink = true
            } else {
                lastRealTab = newValue
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: showAddDrink) { _, new in new }
        .sheet(isPresented: $showAddDrink) {
            AddDrinkView()
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
    return RootShellView().modelContainer(container)
}
