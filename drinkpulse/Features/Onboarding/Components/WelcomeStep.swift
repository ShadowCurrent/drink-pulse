import SwiftUI

struct WelcomeStep: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("🫀")
                    .font(.system(size: 72))
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

            Spacer()

            Button(action: onGetStarted) {
                Text(String(localized: "onboarding.welcome.cta"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(String(localized: "onboarding.welcome.cta.hint"))
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    WelcomeStep(onGetStarted: {})
}
