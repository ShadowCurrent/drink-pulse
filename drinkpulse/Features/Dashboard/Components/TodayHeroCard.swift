import SwiftUI

/// Today hero (plan 0046, D0046-2; prototype `TodayHeroCard`): the one branded surface. A
/// `MeshGradient` in the content layer carries the brand colour (HIG Branding); text uses the
/// brand ink. The risk status keeps its semantic colour in the glyph and the arc only. Status is
/// today's level; the weekly level stays with the 7-day gauge and the weekly alert card.
struct TodayHeroCard: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let vm: DashboardViewModel

    private var ink: Color { Brand.ink(for: scheme) }
    private var mesh: [Color] { Brand.heroMesh(for: scheme) }

    var body: some View {
        layout
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(ink)
        .background {
            MeshGradient(width: 3, height: 3,
                         points: [[0, 0], [0.5, 0], [1, 0],
                                  [0, 0.5], [0.6, 0.45], [1, 0.5],
                                  [0, 1], [0.5, 1], [1, 1]],
                         colors: mesh)
                // Increase Contrast: flatten to the first stop.
                .overlay(contrast == .increased ? mesh[0] : .clear)
        }
        .clipShape(.rect(cornerRadius: CardMetrics.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: accessibilityText))
        .accessibilityIdentifier("today.hero")
    }

    /// Figures beside the arc; stacked at accessibility sizes. A Dynamic Type branch, not
    /// `ViewThatFits`: the audit flags every text of a `ViewThatFits` (plan 0046 Task 7).
    @ViewBuilder
    private var layout: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                figures
                gauge
            }
        } else {
            HStack(alignment: .center, spacing: 16) {
                figures
                Spacer(minLength: 0)
                gauge
            }
        }
    }

    private var figures: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "dashboard.hero.eyebrow"))
                .font(.subheadline)
            Text(vm.formattedAlcohol(vm.todayGrams))
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
                .monospacedDigit()
                .contentTransition(.numericText(value: vm.todayGrams))
            Text(limitCopy)
                .font(.subheadline)
            HeroStatusLabel(level: vm.todayRiskLevel)
                .font(.subheadline.weight(.semibold))
        }
        // A new drink: the figure counts up and the glyph swaps with Replace, in step with the
        // arc's sweep. Off under Reduce Motion, and not on the initial load (as `DPArcProgress`):
        // the first-run entrance is port step 8.
        .animation(figuresAnimation, value: vm.todayGrams)
        .task { hasSettledOnce = true }
    }

    @State private var hasSettledOnce = false

    private var figuresAnimation: Animation? {
        guard hasSettledOnce else { return nil }
        return DPMotion.animation(.snappy, reduceMotion: reduceMotion)
    }

    private var gauge: some View {
        HeroGauge(fraction: vm.todayPct, tone: vm.todayRiskLevel.tone, ink: ink)
    }

    private var limitCopy: String {
        let formatted = vm.formattedAlcohol(vm.effectiveDailyLimitGrams)
        let format = vm.dailyLimitGrams > 0
            ? String(localized: "dashboard.hero.dailyLimit")
            : String(localized: "dashboard.hero.dailyAvg")
        return String(format: format, formatted)
    }

    private var accessibilityText: String {
        [String(localized: "dashboard.hero.eyebrow"),
         vm.formattedAlcohol(vm.todayGrams),
         vm.todayRiskLevel.statusTitle].joined(separator: ", ")
    }
}

#Preview("Hero") {
    TodayHeroCard(vm: DashboardViewModel())
        .padding()
}

#Preview("Hero · Dark") {
    TodayHeroCard(vm: DashboardViewModel())
        .padding()
        .preferredColorScheme(.dark)
}

#Preview("Hero · AX5") {
    TodayHeroCard(vm: DashboardViewModel())
        .padding()
        .dynamicTypeSize(.accessibility5)
}
