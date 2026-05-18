import SwiftUI
import SwiftData

struct DashboardView: View {
    @State private var showAddDrink = false
    @State private var vm = DashboardViewModel()
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \ConsumptionEvent.timestamp, order: .reverse)
    private var allEvents: [ConsumptionEvent]
    @Query private var profiles: [UserProfile]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                sectionLabel(String(localized: "dashboard.section.today"))
                metricsGrid
                ConsumptionOverviewCard(vm: vm)
                ThisWeekCard(vm: vm)
                streakRow
                if vm.riskLevel == .exceeded {
                    GuidelineAlertCard(weeklyPct: vm.weeklyPct,
                                       guidelineName: vm.guidelineDisplayName)
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddDrink = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text(String(localized: "addDrink.title"))
                    }
                }
                .accessibilityLabel(String(localized: "addDrink.title"))
            }
        }
        .sheet(isPresented: $showAddDrink) {
            AddDrinkView()
        }
        .onChange(of: allEvents, initial: true) {
            vm.events = allEvents
        }
        .onChange(of: profiles, initial: true) {
            vm.profile = profiles.first
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active { vm.now = .now }
        }
    }

    // MARK: - Section label

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.bottom, -8)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.greetingText)
                    .font(.title2.bold())
                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            RiskBadge(level: vm.riskLevel)
        }
    }

    private var headerSubtitle: String {
        let dateStr = vm.now.formatted(.dateTime.month(.abbreviated).day())
        return "\(dateStr) · \(vm.guidelineDisplayName)"
    }

    // MARK: - Metrics grid

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: String(localized: "dashboard.metric.alcohol"),
                value: vm.formattedAlcohol(vm.todayGrams),
                iconName: "drop.fill",
                accent: .dpTeal
            )
            MetricCard(
                title: String(localized: "dashboard.metric.calories"),
                value: "\(vm.todayCaloriesKcal) kcal",
                iconName: "flame.fill",
                accent: .dpAmber
            )
            MetricCard(
                title: String(localized: "dashboard.metric.drinks"),
                value: "\(vm.todayDrinkCount)",
                iconName: "bolt.fill",
                accent: .dpPurple
            )
            if let spend = vm.todaySpend {
                MetricCard(
                    title: String(localized: "dashboard.metric.spend"),
                    value: vm.formattedSpend(spend),
                    iconName: "chart.line.uptrend.xyaxis",
                    accent: .dpGreen
                )
            }
        }
    }

    // MARK: - Streak row

    private var streakRow: some View {
        HStack(spacing: 12) {
            StreakCard(
                value: vm.currentStreakDays,
                label: String(localized: "dashboard.streak.current"),
                iconName: "flame.fill",
                accent: .dpAmber
            )
            StreakCard(
                value: vm.soberDaysThisMonth,
                label: String(localized: "dashboard.streak.soberThisMonth"),
                iconName: "moon.stars.fill",
                accent: .dpPurple
            )
        }
    }
}

// MARK: - RiskBadge

private struct RiskBadge: View {
    let level: RiskLevel

    var body: some View {
        Label(labelText, systemImage: iconName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .accessibilityLabel(labelText)
    }

    private var labelText: String {
        switch level {
        case .safe:     return String(localized: "dashboard.risk.safe")
        case .caution:  return String(localized: "dashboard.risk.caution")
        case .exceeded: return String(localized: "dashboard.risk.exceeded")
        }
    }

    private var iconName: String {
        switch level {
        case .safe:     return "checkmark.circle.fill"
        case .caution:  return "exclamationmark.circle.fill"
        case .exceeded: return "xmark.circle.fill"
        }
    }

    private var color: Color {
        switch level {
        case .safe:     return .dpGreen
        case .caution:  return .dpAmber
        case .exceeded: return .dpRed
        }
    }
}
