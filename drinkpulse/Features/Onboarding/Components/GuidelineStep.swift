import SwiftUI

struct GuidelineStep: View {
    let selection: GuidelineChoice
    let sex: BiologicalSex
    let onSelect: (GuidelineChoice) -> Void
    let onDone: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        OnboardingStepLayout(
            buttonTitle: String(localized: "onboarding.step.continue"),
            action: onDone
        ) {
            OnboardingHeading(
                title: String(localized: "onboarding.guideline.title"),
                message: String(localized: "onboarding.guideline.body")
            )
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // At accessibility sizes the whole step scrolls (OnboardingStepLayout), so the list
            // must not nest a second scroll view.
            if dynamicTypeSize.isAccessibilitySize {
                choices
            } else {
                ScrollView { choices }
            }
        }
    }

    private var choices: some View {
        OnboardingCard {
            ForEach(GuidelineChoice.selectable, id: \.self) { choice in
                if choice != GuidelineChoice.selectable.first {
                    Divider().padding(.leading, CardMetrics.padding)
                }
                OnboardingChoiceRow(
                    title: choice.displayName,
                    detail: choice.thresholdSummary(for: sex),
                    isSelected: selection == choice,
                    identifier: "guidelineChoiceRow.\(choice.rawValue)"
                ) {
                    onSelect(choice)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
}

#Preview("Light") {
    GuidelineStep(selection: .who, sex: .female, onSelect: { _ in }, onDone: {})
        .background { BrandBackdrop().ignoresSafeArea() }
}

#Preview("Dark") {
    GuidelineStep(selection: .who, sex: .female, onSelect: { _ in }, onDone: {})
        .background { BrandBackdrop().ignoresSafeArea() }
        .preferredColorScheme(.dark)
}

#Preview("Accessibility 5") {
    GuidelineStep(selection: .who, sex: .male, onSelect: { _ in }, onDone: {})
        .background { BrandBackdrop().ignoresSafeArea() }
        .dynamicTypeSize(.accessibility5)
}
