import SwiftUI
import SwiftData

struct RootShellView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showAddDrink = false
    @AppStorage(AppStorageKeys.onboardingDone) private var onboardingDone = false
    @Query private var profiles: [UserProfile]

    var body: some View {
        ZStack {
            Color.dpAccent.opacity(0.04).ignoresSafeArea()
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
                    Label(String(localized: "tab.home"), systemImage: "house")
                        .environment(\.symbolVariants, selectedTab == .home ? .fill : .none)
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
                    Label(String(localized: "tab.insights"), systemImage: "chart.bar")
                        .environment(\.symbolVariants, selectedTab == .insights ? .fill : .none)
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
                    Label(String(localized: "tab.history"), systemImage: "clock")
                        .environment(\.symbolVariants, selectedTab == .history ? .fill : .none)
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
                    Label(String(localized: "tab.settings"), systemImage: "gearshape")
                        .environment(\.symbolVariants, selectedTab == .settings ? .fill : .none)
                }
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: showAddDrink) { _, new in new }
            .sheet(isPresented: $showAddDrink) {
                AddDrinkView()
            }
            .onChange(of: profiles.isEmpty) { _, isEmpty in
                if isEmpty { onboardingDone = false }
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
