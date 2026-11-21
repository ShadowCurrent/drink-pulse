import SwiftUI
import SwiftData

/// Insights (plan 0046): card screen on the Frost tint. Period switch + navigator, hero chart,
/// Health Impact grid, weekday averages, guideline comparison. "Today" (jump to the current
/// period) is a toolbar button, as in Calendar. No events at all → one empty state.
struct InsightsView: View {
    @State private var vm = InsightsViewModel()
    @State private var countsDown = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \ConsumptionEvent.consumptionDate, order: .reverse)
    private var allEvents: [ConsumptionEvent]
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if allEvents.isEmpty {
                NoDrinksYetView(title: String(localized: "insights.empty.title"),
                                message: String(localized: "insights.empty.description"),
                                systemImage: "chart.bar")
            } else {
                content
            }
        }
        .brandBackground()
        .brandNavigationTitle("tab.insights")
        .toolbar {
            if !vm.isAllTime, !vm.isCurrentPeriod {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "insights.nav.today")) { step(-vm.activeOffset) }
                        .accessibilityIdentifier("insights.nav.todayButton")
                }
            }
            AddDrinkToolbarItem()
        }
        .onChange(of: allEvents, initial: true) { vm.events = allEvents }
        .onChange(of: profiles, initial: true) { vm.profile = profiles.first }
        .onChange(of: scenePhase) { if scenePhase == .active { vm.now = .now } }
        .dp_logViewLoad("Insights")
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                InsightsPeriodPicker(period: periodBinding)
                if !vm.isAllTime {
                    InsightsPeriodNavigator(vm: vm, step: step)
                }
                InsightsHeroCard(vm: vm)
                HealthMetricsCard(vm: vm)
                WeekdayBarChart(bars: vm.weekdayAverages,
                                unitDivisor: vm.displayUnitDivisor,
                                unitLabel: vm.displayUnitLabel)
                GuidelineComparisonCard(vm: vm)
            }
            .padding()
            .environment(\.numbersCountDown, countsDown)
        }
        // HIG Charts: "Help people notice important changes in a chart … highlight the changes
        // in other ways, too" — the morph is visual only, so VoiceOver hears the new period and
        // total (D0046-14). Posting while VoiceOver is off does nothing.
        .onChange(of: PeriodKey(period: vm.period, offset: vm.activeOffset)) {
            AccessibilityNotification.Announcement(vm.periodAnnouncement).post()
        }
    }

    /// Period changes go through `withMotion`, so the whole page moves in one transaction.
    private var periodBinding: Binding<InsightsPeriod> {
        Binding(get: { vm.period }, set: { newValue in
            countsDown = false
            withMotion(reduceMotion: reduceMotion) { vm.period = newValue }
        })
    }

    /// Moves `delta` periods; digits roll down when going back in time, up when going forward.
    private func step(_ delta: Int) {
        guard delta != 0 else { return }
        countsDown = delta < 0
        withMotion(reduceMotion: reduceMotion) {
            if delta == 1 {
                vm.navigateNext()
            } else if delta == -1 {
                vm.navigatePrev()
            } else {
                vm.jumpToNow()
            }
        }
    }
}

private struct PeriodKey: Equatable {
    let period: InsightsPeriod
    let offset: Int
}
