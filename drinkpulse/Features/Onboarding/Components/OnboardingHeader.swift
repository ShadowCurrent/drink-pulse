import SwiftUI

/// Onboarding header: a `.glass` circle Back button over the capsule step dots (D0048-9).
///
/// The Back button is always laid out and only hidden on step 1, so the header has one height on
/// every step. When it appeared on step 1→2 instead, the header grew in the same transaction and
/// the paged `TabView` below jumped instead of sliding (prototype round 19b).
struct OnboardingHeader: View {
    let step: Int
    let total: Int
    let onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            stepDots

            HStack {
                // `hidden()` keeps the button's layout but it is not drawn and cannot be used
                // (SwiftUI docs). `opacity(0)` + `accessibilityHidden(true)` left the disabled
                // glass button in the accessibility tree on step 1.
                if step > 0 {
                    backButton
                } else {
                    backButton.hidden()
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .frame(minHeight: 44)
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.backward")
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(String(localized: "onboarding.back"))
    }

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == step ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: i == step ? 24 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: step)
            }
        }
        // The 8 pt dots are decoration; the progress is one element with a 44 pt tall frame, so the
        // audit finds no undersized hit region, and VoiceOver reads a label plus a localized value.
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "onboarding.progress.label"))
        .accessibilityValue(String(format: String(localized: "onboarding.progress.value"), step + 1, total))
    }
}

#Preview("Step 1") {
    OnboardingHeader(step: 0, total: 4, onBack: {})
}

#Preview("Step 2") {
    OnboardingHeader(step: 1, total: 4, onBack: {})
}

#Preview("Step 2 · Dark") {
    OnboardingHeader(step: 1, total: 4, onBack: {})
        .preferredColorScheme(.dark)
}
