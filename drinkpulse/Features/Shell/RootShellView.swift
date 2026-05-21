import SwiftUI
import SwiftData

struct RootShellView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showAddDrink = false
    @Environment(\.dpTheme) private var theme

    var body: some View {
        ZStack {
            theme.primary.opacity(0.04).ignoresSafeArea()
            TabView(selection: $selectedTab) {
                Tab(value: AppTab.home) {
                    NavigationStack {
                        DashboardView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    AddDrinkButton { showAddDrink = true }
                                }
                            }
                    }
                } label: {
                    Label("tab.home", systemImage: selectedTab == .home ? "house.fill" : "house")
                        .environment(\.symbolVariants, .none)
                }

                Tab(value: AppTab.insights) {
                    NavigationStack {
                        InsightsView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    AddDrinkButton { showAddDrink = true }
                                }
                            }
                    }
                } label: {
                    Label("tab.insights", systemImage: selectedTab == .insights ? "chart.bar.fill" : "chart.bar")
                        .environment(\.symbolVariants, .none)
                }

                Tab(value: AppTab.history) {
                    NavigationStack {
                        HistoryView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    AddDrinkButton { showAddDrink = true }
                                }
                            }
                    }
                } label: {
                    Label("tab.history", systemImage: selectedTab == .history ? "clock.fill" : "clock")
                        .environment(\.symbolVariants, .none)
                }

                Tab(value: AppTab.settings) {
                    NavigationStack {
                        SettingsView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    AddDrinkButton { showAddDrink = true }
                                }
                            }
                    }
                } label: {
                    Label("tab.settings", systemImage: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                        .environment(\.symbolVariants, .none)
                }
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: showAddDrink) { _, new in new }
            .sheet(isPresented: $showAddDrink) {
                AddDrinkView()
            }
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
