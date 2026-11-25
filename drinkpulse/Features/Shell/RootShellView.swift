import SwiftUI
import SwiftData
import OSLog

/// Drives the logging haptic: a new value per logged drink.
private struct LogPulse: Equatable {
    let id: UUID
    let feedback: SensoryFeedback
}

struct RootShellView: View {
    private static let logger = Logger(subsystem: "com.drinkpulse.app", category: "Shell")

    @State private var selectedTab: AppTab = .home
    @State private var showAddDrink = false
    @State private var logPulse: LogPulse?
    @State private var warmTapArmed = UITestSeed.armWarmWeeklySummaryTap
    @State private var hasEnteredBackground = false
    /// First run: onboarding is a full-screen cover over the shell (D0048-1).
    @State private var showsOnboarding = Self.startsWithOnboarding
    /// False while the first-run cover is up; Today's entrance plays when it turns true (D0048-12).
    @State private var firstRunRevealed = !Self.startsWithOnboarding
    @AppStorage(AppStorageKeys.onboardingDone) private var onboardingDone = false
    @AppStorage(AppStorageKeys.pendingAddDrink) private var pendingAddDrink = false
    @AppStorage(AppStorageKeys.pendingOpenInsights) private var pendingOpenInsights = false
    @AppStorage(UITestHealthStore.sampleCountKey) private var healthSampleCount = 0
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    private let reminderService = ReminderService()
    private let weeklySummaryService = WeeklySummaryService()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: AppTab.home) {
                NavigationStack { DashboardView() }
            } label: {
                Label(String(localized: "tab.home"), systemImage: "house")
            }

            Tab(value: AppTab.insights) {
                NavigationStack { InsightsView() }
            } label: {
                Label(String(localized: "tab.insights"), systemImage: "chart.bar")
            }

            Tab(value: AppTab.history) {
                NavigationStack { HistoryView() }
            } label: {
                Label(String(localized: "tab.history"), systemImage: "clock")
            }

            Tab(value: AppTab.settings) {
                NavigationStack { SettingsView() }
            } label: {
                Label(String(localized: "tab.settings"), systemImage: "gearshape")
            }
        }
        .sensoryFeedback(trigger: logPulse) { _, new in new?.feedback }
        .sheet(isPresented: $showAddDrink) {
            AddDrinkView()
        }
        .fullScreenCover(isPresented: $showsOnboarding, onDismiss: revealFirstRun) {
            OnboardingView(onFinish: {
                onboardingDone = true
                showsOnboarding = false
            })
        }
        .overlay(alignment: .topLeading) {
            if UITestSeed.isActive {
                // One point, non-text element: a 1 point Text is reported by the accessibility
                // audit (contrast, dynamicType). The label carries the Health sample count.
                let sampleCountLabel: String = "\(healthSampleCount)"
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier("dp_health_sample_count")
                    .accessibilityLabel(sampleCountLabel)
            }
        }
        .onAppear {
            ShellStartup.run(context: modelContext)
            openAddDrinkIfPending()
            openInsightsIfPending()
            deleteProfileMidSessionIfUITest()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                hasEnteredBackground = true
            }
            if phase == .active {
                deliverArmedWarmTapIfNeeded()
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
                // While the first-run cover is up the pending flag stays set (D0048-3).
                guard !showsOnboarding else { continue }
                pendingAddDrink = false
                showAddDrink = true
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(
                named: NotificationActionHandler.didTapWeeklySummary
            ) {
                guard !showsOnboarding else { continue }
                pendingOpenInsights = false
                selectedTab = .insights
            }
        }
        .environment(\.addDrink, AddDrinkAction { showAddDrink = true })
        .environment(\.drinkLogged, DrinkLoggedAction { playLogFeedback(for: $0) })
    }

    /// One haptic per logged drink: `.warning` when it takes today over the daily limit.
    /// The fetch sees the unsaved insert (`FetchDescriptor.includePendingChanges` is `true`).
    private func playLogFeedback(for event: ConsumptionEvent) {
        let now = Date.now
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        let feedback: SensoryFeedback
        do {
            let today = try modelContext.fetch(FetchDescriptor<ConsumptionEvent>(
                predicate: #Predicate { $0.consumptionDate >= start }
            ))
            let profile = try modelContext.fetch(FetchDescriptor<UserProfile>()).first
            feedback = LogFeedback.feedback(
                todayEvents: today, logged: event, profile: profile, now: now, calendar: calendar
            )
        } catch {
            Self.logger.error("Log feedback fetch failed: \(String(describing: type(of: error)), privacy: .public)")
            feedback = .success
        }
        logPulse = LogPulse(id: UUID(), feedback: feedback)
    }

    /// Onboarding shows on a fresh install, or when a UI test forces it.
    private static var startsWithOnboarding: Bool {
        !UserDefaults.standard.bool(forKey: AppStorageKeys.onboardingDone) || UITestSeed.forceShowOnboarding
    }

    /// After the cover is dismissed: start Today's entrance, then run the actions that waited.
    private func revealFirstRun() {
        firstRunRevealed = true
        openAddDrinkIfPending()
        openInsightsIfPending()
    }

    /// Pending notification actions wait while the first-run cover is up (D0048-3): no sheet or
    /// tab change happens under it.
    private func openAddDrinkIfPending() {
        guard pendingAddDrink, !showsOnboarding else { return }
        pendingAddDrink = false
        showAddDrink = true
    }

    private func openInsightsIfPending() {
        guard pendingOpenInsights, !showsOnboarding else { return }
        pendingOpenInsights = false
        selectedTab = .insights
    }

    /// UI-test only: once the app returns from background, hands one weekly-summary tap to the
    /// UI-test notification center, which routes it like the system center would.
    private func deliverArmedWarmTapIfNeeded() {
        guard warmTapArmed, hasEnteredBackground else { return }
        warmTapArmed = false
        let center = UITestNotificationCenter()
        Task { await center.deliverTap(identifier: WeeklySummaryService.weeklySummaryIdentifier) }
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
