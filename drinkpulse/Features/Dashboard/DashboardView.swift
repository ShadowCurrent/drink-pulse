import SwiftUI
import SwiftData

struct DashboardView: View {
    @State private var showAddDrink = false
    @State private var now = Date.now
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \ConsumptionEvent.timestamp, order: .reverse)
    private var allEvents: [ConsumptionEvent]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    private var alcoholUnit: AlcoholUnit { profile?.alcoholUnit ?? .units }
    private var guideline: GuidelineChoice { profile?.guidelineChoice ?? .who }

    private func consumedLabel(_ grams: Double) -> String {
        "\(alcoholUnit.formattedValue(grams, guideline: guideline)) \(alcoholUnit.unitLabel)"
    }

    private var dailyLimitGrams: Double {
        guard let p = profile else { return 20 }
        switch p.guidelineChoice {
        case .who: return 20
        case .de:  return 24
        case .uk:  return 0
        case .us:  return 28
        case .custom: return p.weeklyGoalGrams / 7
        }
    }

    private var weeklyLimitGrams: Double { profile?.weeklyGoalGrams ?? 100 }

    private var todayGrams: Double {
        let start = Calendar.current.startOfDay(for: now)
        return allEvents.filter { $0.timestamp >= start }.map(\.pureAlcoholGrams).reduce(0, +)
    }

    private var sevenDayGrams: Double {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        return allEvents.filter { $0.timestamp >= start }.map(\.pureAlcoholGrams).reduce(0, +)
    }

    private var thirtyDayGrams: Double {
        let start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        return allEvents.filter { $0.timestamp >= start }.map(\.pureAlcoholGrams).reduce(0, +)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 0) {
                    IntakeRing(
                        label: String(localized: "dashboard.ring.today"),
                        consumed: todayGrams,
                        limit: dailyLimitGrams,
                        consumedLabel: consumedLabel(todayGrams)
                    )
                    .frame(maxWidth: .infinity)

                    IntakeRing(
                        label: String(localized: "dashboard.ring.days7"),
                        consumed: sevenDayGrams,
                        limit: weeklyLimitGrams,
                        consumedLabel: consumedLabel(sevenDayGrams)
                    )
                    .frame(maxWidth: .infinity)

                    IntakeRing(
                        label: String(localized: "dashboard.ring.days30"),
                        consumed: thirtyDayGrams,
                        limit: weeklyLimitGrams * (30.0 / 7.0),
                        consumedLabel: consumedLabel(thirtyDayGrams)
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal)
        }
        .navigationTitle(String(localized: "tab.home"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "addDrink.title"), systemImage: "plus") {
                    showAddDrink = true
                }
                .accessibilityLabel(String(localized: "addDrink.title"))
            }
        }
        .sheet(isPresented: $showAddDrink) {
            AddDrinkView()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { now = .now }
        }
    }
}

private struct IntakeRing: View {
    let label: String
    let consumed: Double
    let limit: Double
    let consumedLabel: String

    // Not capped at 1.0 — values > 1 mean over the limit.
    private var progress: Double {
        guard limit > 0 else { return 0 }
        return consumed / limit
    }

    // Portion of the second lap to draw (0 when ≤ 100%).
    private var overflowProgress: Double {
        max(progress - 1.0, 0)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Track
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 10)

                // Main arc — first lap, capped at one full circle
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: progress)

                // Overflow arc — second lap, thinner, drawn on top
                Circle()
                    .trim(from: 0, to: min(overflowProgress, 1.0))
                    .stroke(Color.red.opacity(0.55), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: overflowProgress)

                VStack(spacing: 1) {
                    if limit > 0 {
                        Text(String(format: "%.0f%%", progress * 100))
                            .font(.system(.callout, design: .rounded).bold())
                            .monospacedDigit()
                        Text(consumedLabel)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    } else {
                        Text("—")
                            .font(.system(.callout, design: .rounded).bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 84, height: 84)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var ringColor: Color {
        if progress < 0.7 { return .green }
        if progress < 1.0 { return .orange }
        return .red
    }

    private var accessibilityLabel: String {
        guard limit > 0 else { return "\(label): no limit set" }
        return String(format: "%@: %.0f of %.0f grams, %.0f percent",
                      label, consumed, limit, progress * 100)
    }
}

#Preview("With data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self, GuidelineProfile.self,
        configurations: config
    )
    container.mainContext.insert(ConsumptionEvent.previewBeer)
    container.mainContext.insert(ConsumptionEvent.previewWine)
    container.mainContext.insert(ConsumptionEvent.previewSpirits)
    container.mainContext.insert(UserProfile.preview)
    return NavigationStack { DashboardView() }
        .modelContainer(container)
}

#Preview("Empty") {
    NavigationStack { DashboardView() }
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self, GuidelineProfile.self],
            inMemory: true
        )
}
