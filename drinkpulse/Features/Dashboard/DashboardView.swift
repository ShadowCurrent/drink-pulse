import SwiftUI
import SwiftData
import Charts

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
                metricsGrid
                WeeklyGoalCard(vm: vm)
                streakRow
                if vm.riskLevel == .exceeded {
                    GuidelineAlertCard(weeklyPct: vm.weeklyPct,
                                       guidelineName: vm.guidelineDisplayName)
                }
            }
            .padding()
        }
        .navigationTitle(String(localized: "tab.home"))
        .navigationBarTitleDisplayMode(.large)
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

// MARK: - MetricCard

private struct MetricCard: View {
    let title: String
    let value: String
    let iconName: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(accent)
                .font(.system(size: 20, weight: .medium))
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - WeeklyGoalCard

private struct WeeklyGoalCard: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "dashboard.weeklyGoal"))
                    .font(.headline)
                Spacer()
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            HStack(spacing: 16) {
                weeklyRing
                barChart
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(weeklyGoalAccessibilityLabel)
    }

    private var subtitleText: String {
        if vm.weeklyLimitGrams > 0 {
            return String(format: "%.0f / %.0f g", vm.weeklyGrams, vm.weeklyLimitGrams)
        }
        return String(format: "%.0f g", vm.weeklyGrams)
    }

    private var weeklyGoalAccessibilityLabel: String {
        String(format: "Weekly goal. %.0f of %.0f grams. %.0f percent.",
               vm.weeklyGrams, vm.weeklyLimitGrams, vm.weeklyPct * 100)
    }

    private var weeklyRing: some View {
        let pct = vm.weeklyPct
        return ZStack {
            Circle()
                .stroke(Color(.systemFill), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(pct, 1.0))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: pct)
            if pct > 1 {
                Circle()
                    .trim(from: 0, to: min(pct - 1.0, 1.0))
                    .stroke(Color.dpRed.opacity(0.5), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: pct)
            }
            Text(String(format: "%.0f%%", min(pct * 100, 999)))
                .font(.system(.callout, design: .rounded).bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(4)
        }
        .frame(width: 80, height: 80)
    }

    private var ringColor: Color {
        switch vm.riskLevel {
        case .safe:     return .dpGreen
        case .caution:  return .dpAmber
        case .exceeded: return .dpRed
        }
    }

    private var barChart: some View {
        Chart(vm.weekBarData) { entry in
            BarMark(
                x: .value("Day", entry.label),
                y: .value("g", entry.grams)
            )
            .foregroundStyle(barColor(for: entry))
        }
        .chartXScale(domain: vm.weekBarData.map(\.label))
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 9))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 80)
        .accessibilityHidden(true)
    }

    private func barColor(for entry: WeekBarEntry) -> Color {
        if entry.isToday { return .dpTeal }
        if entry.isFuture { return Color(.quaternarySystemFill) }
        if entry.grams > vm.dailyLimitGrams && vm.dailyLimitGrams > 0 { return .dpAmber }
        return Color(.tertiarySystemFill)
    }
}

// MARK: - StreakCard

private struct StreakCard: View {
    let value: Int
    let label: String
    let iconName: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(accent)
                .font(.system(size: 22))
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.title2.bold())
                    .monospacedDigit()
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - GuidelineAlertCard

private struct GuidelineAlertCard: View {
    let weeklyPct: Double
    let guidelineName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.dpRed)
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "dashboard.alert.title"))
                    .font(.subheadline.bold())
                Text(String(format: "%.0f%% of %@ weekly limit", weeklyPct * 100, guidelineName))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.dpRed.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(
            format: "%@. %.0f%% of %@ guideline.",
            String(localized: "dashboard.alert.title"), weeklyPct * 100, guidelineName
        ))
    }
}

// MARK: - Previews

#Preview("With data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    let ctx = container.mainContext
    let cal = Calendar.current
    let now = Date.now

    // Today
    ctx.insert(ConsumptionEvent(timestamp: now, volumeMl: 568, abv: 0.05,
                                name: "Beer", category: .beer, icon: "🍺"))
    ctx.insert(ConsumptionEvent(timestamp: now.addingTimeInterval(-3600), volumeMl: 175, abv: 0.135,
                                name: "Wine", category: .wine, icon: "🍷", price: 8.50))

    // Earlier this week
    let minus2 = cal.date(byAdding: .day, value: -2, to: now)!
    ctx.insert(ConsumptionEvent(timestamp: minus2, volumeMl: 330, abv: 0.05,
                                name: "Beer", category: .beer, icon: "🍺", price: 4.00))
    let minus4 = cal.date(byAdding: .day, value: -4, to: now)!
    ctx.insert(ConsumptionEvent(timestamp: minus4, volumeMl: 250, abv: 0.12,
                                name: "Wine", category: .wine, icon: "🍷"))

    ctx.insert(UserProfile.preview)
    return NavigationStack { DashboardView() }
        .modelContainer(container)
}

#Preview("Empty") {
    NavigationStack { DashboardView() }
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}

#Preview("Over limit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    let ctx = container.mainContext
    // WHO male limit = 100 g. Insert 125 g today.
    ctx.insert(ConsumptionEvent(timestamp: .now, volumeMl: 1562, abv: 0.10,
                                name: "Spirits", category: .spirits, icon: "🥃"))
    ctx.insert(UserProfile.preview)
    return NavigationStack { DashboardView() }
        .modelContainer(container)
}
