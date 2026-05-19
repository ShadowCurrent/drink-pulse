import SwiftUI
import SwiftData

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var vm = OnboardingViewModel()
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            stepDots
                .padding(.top, 20)
                .padding(.bottom, 4)

            TabView(selection: $vm.step) {
                WelcomeStep(
                    onGetStarted: { animatedStep { vm.advance() } },
                    onSkipAll: { finish(saving: false) }
                )
                .tag(0)

                ProfileStep(
                    sex: $vm.sex,
                    dateOfBirth: $vm.dateOfBirth,
                    onContinue: { animatedStep { vm.advance() } },
                    onSkip: { animatedStep { vm.skipStep() } }
                )
                .tag(1)

                GuidelineStep(
                    selection: vm.guideline,
                    sex: vm.sex ?? .male,
                    onSelect: { vm.setGuideline($0) },
                    onDone: { finish(saving: true) },
                    onSkip: { finish(saving: true) }
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<vm.totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i == vm.step ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: i == vm.step ? 24 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: vm.step)
            }
        }
        .accessibilityLabel(Text("Step \(vm.step + 1) of \(vm.totalSteps)"))
    }

    private func animatedStep(_ action: () -> Void) {
        if reduceMotion {
            action()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { action() }
        }
    }

    private func finish(saving: Bool) {
        if saving { vm.complete(into: context) }
        onFinish()
    }
}

#Preview {
    OnboardingView(onFinish: {})
        .modelContainer(for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
                        inMemory: true)
}
