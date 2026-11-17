import SwiftUI
import SwiftData

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var vm = OnboardingViewModel()
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            header
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
                TabView(selection: $vm.step) {
                    ForEach(0..<vm.totalSteps, id: \.self) { index in
                        step(index).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
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
                sex: vm.sex ?? .male,
                onSelect: { vm.setGuideline($0) },
                onDone: { animatedStep { vm.advance() } }
            )
        default:
            HealthStep(onDone: { finish() })
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
        .frame(minHeight: 44)
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
        // The 8 pt dots are decoration; the progress is one element with a 44 pt tall frame, so the
        // audit finds no undersized hit region, and VoiceOver reads a label plus a localized value.
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "onboarding.progress.label"))
        .accessibilityValue(progressValue)
    }

    private var progressValue: String {
        String(format: String(localized: "onboarding.progress.value"), vm.step + 1, vm.totalSteps)
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
