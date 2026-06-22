import SwiftUI
import SwiftData

struct DashboardView: View {
    @State private var vm = DashboardViewModel()
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \ConsumptionEvent.timestamp, order: .reverse)
    private var allEvents: [ConsumptionEvent]
    @Query private var profiles: [UserProfile]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                DashboardHeroCard(vm: vm)
                DashboardChipRow(vm: vm)
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
        .navigationTitle(String(localized: "tab.home"))
        .navigationBarTitleDisplayMode(.inline)
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
            RiskBadge(level: vm.effectiveRiskLevel)
        }
    }

    private var headerSubtitle: String {
        let dateStr = vm.now.formatted(.dateTime.month(.abbreviated).day())
        return "\(dateStr) · \(vm.guidelineDisplayName)"
    }

    // MARK: - Streak row

    private var streakRow: some View {
        HStack(spacing: 12) {
            StreakCard(
                value: vm.currentStreakDays,
                label: String(localized: "dashboard.streak.current"),
                iconName: "flame.fill",
                accent: .dpAmber,
                zeroStateCopy: String(localized: "dashboard.streak.zeroState")
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
        case .exceeded: return "exclamationmark.triangle.fill"
        }
    }

    private var color: Color { level.color }
}
