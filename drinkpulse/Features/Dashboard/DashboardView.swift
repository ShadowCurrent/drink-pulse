import SwiftUI
import SwiftData

/// Today (plan 0046): card screen on the Frost tint built from system components. The type
/// keeps its internal name; only the user-facing name is "Today" (D0046-1).
struct DashboardView: View {
    @State private var vm = DashboardViewModel()
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \ConsumptionEvent.consumptionDate, order: .reverse)
    private var allEvents: [ConsumptionEvent]
    @Query private var profiles: [UserProfile]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // First-run entrance orders (plan 0048, D0048-12); no effect after the first run.
                TodayHeroCard(vm: vm)
                    .firstRunReveal(0)
                TilePair {
                    MetricTile(title: String(localized: "dashboard.chip.calories"),
                               systemImage: "flame.fill", tint: .orange,
                               value: "\(vm.todayCaloriesKcal) kcal")
                } second: {
                    MetricTile(title: String(localized: "dashboard.chip.drinks"),
                               systemImage: "wineglass.fill", tint: .pink,
                               value: "\(vm.todayDrinkCount)")
                }
                .firstRunReveal(1)
                GuidelineLimitsCard(vm: vm)
                    .firstRunReveal(2)
                ThisWeekCard(vm: vm)
                    .firstRunReveal(3)
                streakTiles
                    .firstRunReveal(4)
                if vm.riskLevel == .exceeded {
                    GuidelineAlertCard(weeklyPct: vm.weeklyPct,
                                       guidelineName: vm.guidelineDisplayName)
                        .firstRunReveal(5)
                }
            }
            .padding()
        }
        .brandBackground()
        .brandNavigationTitle("tab.home")
        .navigationSubtitle(subtitle)
        .toolbar { AddDrinkToolbarItem() }
        .onChange(of: allEvents, initial: true) {
            vm.events = allEvents
        }
        .onChange(of: profiles, initial: true) {
            vm.profile = profiles.first
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active { vm.now = .now }
        }
        .dp_logViewLoad("Dashboard")
    }

    private var streakTiles: some View {
        let streak = vm.currentStreakDays
        return TilePair {
            MetricTile(title: String(localized: "dashboard.streak.current"),
                       systemImage: "trophy.fill", tint: .purple,
                       value: "^[\(streak) day](inflect: true)",
                       detail: streak == 0
                           ? String(localized: "dashboard.streak.zeroState") : nil,
                       celebrates: streak > 0)
        } second: {
            MetricTile(title: String(localized: "dashboard.streak.soberThisMonth"),
                       systemImage: "moon.fill", tint: .teal,
                       value: "^[\(vm.soberDaysThisMonth) day](inflect: true)")
        }
    }

    /// `date · guideline` (D0046-1).
    private var subtitle: String {
        let date = vm.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return "\(date) · \(vm.guidelineDisplayName)"
    }
}
