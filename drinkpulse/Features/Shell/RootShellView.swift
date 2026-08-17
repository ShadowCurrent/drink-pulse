import SwiftUI
import SwiftData

struct RootShellView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showAddDrink = false
    @AppStorage(AppStorageKeys.onboardingDone) private var onboardingDone = false
    @AppStorage(AppStorageKeys.pendingAddDrink) private var pendingAddDrink = false
    @AppStorage(AppStorageKeys.pendingOpenInsights) private var pendingOpenInsights = false
    @AppStorage(UITestHealthStore.sampleCountKey) private var healthSampleCount = 0
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    private let reminderService = ReminderService()
    private let weeklySummaryService = WeeklySummaryService()

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
            .overlay(alignment: .topLeading) {
                if UITestSeed.isActive {
                    Text(verbatim: "\(healthSampleCount)")
                        .font(.system(size: 1))
                        .foregroundStyle(.clear)
                        .accessibilityIdentifier("dp_health_sample_count")
                }
            }
            .onAppear {
                openAddDrinkIfPending()
                openInsightsIfPending()
                deleteProfileMidSessionIfUITest()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await reminderService.scheduleIfEnabled() }
                    Task { await weeklySummaryService.scheduleIfEnabled(context: modelContext) }
                }
            }
            .onChange(of: selectedTab) { _, _ in
                ViewLoadNavigation.markRequested()
            }
            .task {
                for await _ in NotificationCenter.default.notifications(
                    named: NotificationActionHandler.didTapReminder
                ) {
                    pendingAddDrink = false
                    showAddDrink = true
                }
            }
            .task {
                for await _ in NotificationCenter.default.notifications(
                    named: NotificationActionHandler.didTapWeeklySummary
                ) {
                    pendingOpenInsights = false
                    selectedTab = .insights
                }
            }
        }
    }

    private func openAddDrinkIfPending() {
        guard pendingAddDrink else { return }
        pendingAddDrink = false
        showAddDrink = true
    }

    private func openInsightsIfPending() {
        guard pendingOpenInsights else { return }
        pendingOpenInsights = false
        selectedTab = .insights
    }

    private func deleteProfileMidSessionIfUITest() {
        guard UITestSeed.isActive, UITestSeed.deleteProfileMidSession else { return }
        let existing = (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []
        for profile in existing {
            modelContext.delete(profile)
        }
        try? modelContext.save()
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
