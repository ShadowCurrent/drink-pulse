import SwiftUI
import SwiftData

struct RootShellView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showAddDrink = false
    @Environment(\.dpTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        ZStack {
            theme.primary.opacity(0.04).ignoresSafeArea()
            TabView(selection: $selectedTab) {
                Tab(String(localized: "tab.home"), systemImage: "house.fill", value: AppTab.home) {
                    NavigationStack {
                        DashboardView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    AddDrinkButton { showAddDrink = true }
                                }
                            }
                    }
                }

                Tab(String(localized: "tab.insights"), systemImage: "chart.bar.fill", value: AppTab.insights) {
                    NavigationStack {
                        InsightsView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    AddDrinkButton { showAddDrink = true }
                                }
                            }
                    }
                }

                Tab(String(localized: "tab.history"), systemImage: "clock.fill", value: AppTab.history) {
                    NavigationStack {
                        HistoryView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    AddDrinkButton { showAddDrink = true }
                                }
                            }
                    }
                }

                Tab(String(localized: "tab.settings"), systemImage: "gearshape.fill", value: AppTab.settings) {
                    NavigationStack {
                        SettingsView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    AddDrinkButton { showAddDrink = true }
                                }
                            }
                    }
                }
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: showAddDrink) { _, new in new }
            .sheet(isPresented: $showAddDrink) {
                AddDrinkView()
            }
            .onChange(of: profiles.isEmpty, initial: true) { _, isEmpty in
                if isEmpty { modelContext.insert(UserProfile()) }
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
