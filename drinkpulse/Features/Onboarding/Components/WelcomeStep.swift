import SwiftUI

struct WelcomeStep: View {
    let onGetStarted: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var emojiSize: CGFloat = 72

    var body: some View {
        OnboardingStepLayout(
            buttonTitle: String(localized: "onboarding.welcome.cta"),
            buttonHint: String(localized: "onboarding.welcome.cta.hint"),
            action: onGetStarted
        ) {
            Spacer(minLength: 16)

            VStack(spacing: 24) {
                Text("🫀")
                    .font(.system(size: emojiSize))
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text(String(localized: "onboarding.welcome.title"))
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text(String(localized: "onboarding.welcome.body"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 16)
        }
    }
}

#Preview {
    WelcomeStep(onGetStarted: {})
}

#Preview("Accessibility 5") {
    WelcomeStep(onGetStarted: {})
        .dynamicTypeSize(.accessibility5)
}
