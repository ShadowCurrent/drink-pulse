import SwiftUI
import SwiftData

struct OnboardingView: View {
    /// False for the Debug-only rehearsal (plan 0052, D0052-1): Done saves no profile.
    var persistsProfile = true
    let onFinish: () -> Void

    @State private var vm = OnboardingViewModel()
    /// Direction of the last step change; picks the side the push transition comes from.
    @State private var movesForward = true
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(step: vm.step, total: vm.totalSteps) {
                move(forward: false) { vm.goBack() }
            }
            .padding(.top, 20)
            .padding(.bottom, 4)

            // Steps change only through the buttons; there is no swipe between pages. A paged
            // TabView reloaded its pages whenever the page count changed, which made About You
            // flicker when a sex was chosen, and its UIKit-hosted pages failed the Dynamic Type
            // audit at accessibility sizes (plan 11-16). The current step is shown directly and
            // pushed in from the side matching the direction of travel.
            step(vm.step)
                .id(vm.step)
                .transition(.push(from: movesForward ? .trailing : .leading))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // There is no NavigationStack here, so `brandBackground()`'s navigation container
        // background has nothing to fill; the same Frost backdrop goes behind the flow directly.
        .background { BrandBackdrop().ignoresSafeArea() }
        .groupBoxStyle(BrandCardStyle())
    }

    @ViewBuilder private func step(_ index: Int) -> some View {
        switch index {
        case 0:
            WelcomeStep(onGetStarted: { move(forward: true) { vm.advance() } })
        case 1:
            ProfileStep(
                sex: $vm.sex,
                dateOfBirth: $vm.dateOfBirth,
                onContinue: { move(forward: true) { vm.advance() } }
            )
        case 2:
            GuidelineStep(
                selection: vm.guideline,
                // Unreachable without a sex (Continue on About You is disabled until then); the
                // fallback only feeds the thresholds text in previews.
                sex: vm.sex ?? .female,
                onSelect: { vm.setGuideline($0) },
                onDone: { move(forward: true) { vm.advance() } }
            )
        default:
            HealthStep(isRehearsal: !persistsProfile, onDone: { finish() })
        }
    }

    /// A removed view keeps the transition from its last render, so when the direction flips the
    /// outgoing step is first re-rendered with the new side, and the step changes one update later.
    private func move(forward: Bool, _ action: @escaping () -> Void) {
        guard forward != movesForward else {
            animatedStep(action)
            return
        }
        movesForward = forward
        Task { @MainActor in animatedStep(action) }
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
