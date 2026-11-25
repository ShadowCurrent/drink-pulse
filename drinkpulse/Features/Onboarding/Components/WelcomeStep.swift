import SwiftUI

struct WelcomeStep: View {
    let onGetStarted: () -> Void

    var body: some View {
        OnboardingStepLayout(
            buttonTitle: String(localized: "onboarding.welcome.cta"),
            buttonHint: String(localized: "onboarding.welcome.cta.hint"),
            action: onGetStarted
        ) {
            Spacer(minLength: 16)

            VStack(spacing: 24) {
                // A decorative image, not a Text: the audit's text checks cannot pass for a
                // multicolour emoji glyph (plan 11-21, group A11Y-AUDIT-G07; same technique as 11-18).
                DecorativeEmoji(emoji: "🫀", baseSize: 72)

                VStack(spacing: 8) {
                    Text(String(localized: "onboarding.welcome.title"))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(String(localized: "onboarding.welcome.body"))
                        .font(.body)
                        .foregroundStyle(Color.dpSecondaryText)
                        .multilineTextAlignment(.center)
                }

                Label(String(localized: "onboarding.welcome.privacy"), systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.dpSecondaryText)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 16)
        }
    }
}

#Preview("Light") {
    WelcomeStep(onGetStarted: {})
        .background { BrandBackdrop().ignoresSafeArea() }
}

#Preview("Dark") {
    WelcomeStep(onGetStarted: {})
        .background { BrandBackdrop().ignoresSafeArea() }
        .preferredColorScheme(.dark)
}

#Preview("Accessibility 5") {
    WelcomeStep(onGetStarted: {})
        .background { BrandBackdrop().ignoresSafeArea() }
        .dynamicTypeSize(.accessibility5)
}
