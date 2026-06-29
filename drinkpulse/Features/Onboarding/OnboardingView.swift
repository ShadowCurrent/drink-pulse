import SwiftUI
import SwiftData

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var vm = OnboardingViewModel()
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 20)
                .padding(.bottom, 4)

            TabView(selection: $vm.step) {
                WelcomeStep(
                    onGetStarted: { animatedStep { vm.advance() } }
                )
                .tag(0)

                ProfileStep(
                    sex: $vm.sex,
                    dateOfBirth: $vm.dateOfBirth,
                    onContinue: { animatedStep { vm.advance() } }
                )
                .tag(1)

                GuidelineStep(
                    selection: vm.guideline,
                    sex: vm.sex ?? .male,
                    onSelect: { vm.setGuideline($0) },
                    onDone: { animatedStep { vm.advance() } }
                )
                .tag(2)

                HealthStep(
                    onDone: { finish() }
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private var header: some View {
        ZStack {
            stepDots

            if vm.step > 0 {
                HStack {
                    Button {
                        animatedStep { vm.goBack() }
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.body.weight(.semibold))
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "onboarding.back"))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .transition(.opacity)
            }
        }
        // Pin a constant height so the taller Back button appearing on step > 0
        // does not grow the header and steal height from (or jolt) the page below.
        .frame(height: 44)
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

    private func finish() {
        vm.complete(into: context)
        onFinish()
    }
}

#Preview {
    OnboardingView(onFinish: {})
        .modelContainer(for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
                        inMemory: true)
}
