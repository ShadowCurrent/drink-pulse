import SwiftUI
import SwiftData

struct OnboardingView: View {
    /// False for the Debug-only rehearsal (plan 0052, D0052-1): Done saves no profile.
    var persistsProfile = true
    let onFinish: () -> Void

    @State private var vm = OnboardingViewModel()
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(step: vm.step, total: vm.totalSteps) {
                animatedStep { vm.goBack() }
            }
            .padding(.top, 20)
            .padding(.bottom, 4)

            // The paged TabView hosts its pages in UIKit, where the Dynamic Type audit reports every
            // text as "font sizes partially unsupported" at accessibility sizes (plan 11-16). At those
            // sizes the current step is shown directly; the buttons drive the same step changes, so
            // only the swipe between pages is not offered there.
            if dynamicTypeSize.isAccessibilitySize {
                step(vm.step)
                    .id(vm.step)
                    .transition(.opacity)
            } else {
                // Only the pages the person may reach are in the TabView, so a swipe cannot pass
                // About You before a sex is chosen (D0048-5). No gesture blocking.
                TabView(selection: $vm.step) {
                    ForEach(0..<vm.reachableSteps, id: \.self) { index in
                        step(index).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        // There is no NavigationStack here, so `brandBackground()`'s navigation container
        // background has nothing to fill; the same Frost backdrop goes behind the flow directly.
        .background { BrandBackdrop().ignoresSafeArea() }
        .groupBoxStyle(BrandCardStyle())
    }

    @ViewBuilder private func step(_ index: Int) -> some View {
        switch index {
        case 0:
            WelcomeStep(onGetStarted: { animatedStep { vm.advance() } })
        case 1:
            ProfileStep(
                sex: $vm.sex,
                dateOfBirth: $vm.dateOfBirth,
                onContinue: { animatedStep { vm.advance() } }
            )
        case 2:
            GuidelineStep(
                selection: vm.guideline,
                // Unreachable without a sex (`reachableSteps`); the fallback only feeds the
                // thresholds text if the page is ever built early, e.g. in previews.
                sex: vm.sex ?? .female,
                onSelect: { vm.setGuideline($0) },
                onDone: { animatedStep { vm.advance() } }
            )
        default:
            HealthStep(onDone: { finish() })
        }
    }

    private func animatedStep(_ action: () -> Void) {
        if reduceMotion {
            action()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { action() }
        }
    }

    private func finish() {
        if persistsProfile {
            vm.complete(into: context)
        }
        onFinish()
    }
}

#Preview("Light") {
    OnboardingView(onFinish: {})
        .modelContainer(for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
                        inMemory: true)
}

#Preview("Dark") {
    OnboardingView(onFinish: {})
        .modelContainer(for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
                        inMemory: true)
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    OnboardingView(onFinish: {})
        .modelContainer(for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
                        inMemory: true)
        .dynamicTypeSize(.accessibility5)
}
