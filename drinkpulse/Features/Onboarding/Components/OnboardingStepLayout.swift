import SwiftUI

/// Shared frame of an onboarding step: content plus one primary button.
///
/// At regular sizes the content keeps its own spacers and the button sits below it, as before. At
/// accessibility sizes the content scrolls (it no longer fits one screen) and the primary button
/// moves into a bottom bar, so it stays reachable without scrolling to the end.
struct OnboardingStepLayout<Content: View>: View {
    let buttonTitle: String
    var buttonHint: String?
    let action: () -> Void
    @ViewBuilder var content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView {
                content
                    .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaBar(edge: .bottom) {
                primaryButton
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
        } else {
            VStack(spacing: 0) {
                content
                primaryButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    private var primaryButton: some View {
        Button(action: action) {
            Text(buttonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityHint(buttonHint ?? "")
    }
}

#Preview("Regular") {
    OnboardingStepLayout(buttonTitle: "Continue", action: {}) {
        Spacer()
        Text(verbatim: "Step content").font(.largeTitle.bold())
        Spacer()
    }
}

#Preview("Accessibility 5") {
    OnboardingStepLayout(buttonTitle: "Continue", action: {}) {
        Text(verbatim: "Step content that is long enough to wrap over several lines")
            .font(.largeTitle.bold())
            .padding(.horizontal, 24)
    }
    .dynamicTypeSize(.accessibility5)
}
