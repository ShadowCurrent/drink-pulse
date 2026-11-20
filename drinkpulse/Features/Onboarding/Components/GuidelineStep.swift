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
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "onboarding.guideline.title"))
                    .font(.largeTitle.bold())
                    .padding(.top, 16)

                Text(String(localized: "onboarding.guideline.body"))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
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
        GroupBox {
            ForEach(GuidelineChoice.selectable, id: \.self) { choice in
                VStack(spacing: 0) {
                    if choice != GuidelineChoice.selectable.first {
                        Divider()
                    }
                    GuidelineChoiceRow(
                        choice: choice,
                        sex: sex,
                        isSelected: selection == choice
                    ) {
                        onSelect(choice)
                    }
                }
            }
        }
        .groupBoxStyle(BrandCardStyle())
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
}

#Preview {
    GuidelineStep(
        selection: .who,
        sex: .male,
        onSelect: { _ in },
        onDone: {}
    )
}

#Preview("Accessibility 5") {
    GuidelineStep(
        selection: .who,
        sex: .male,
        onSelect: { _ in },
        onDone: {}
    )
    .dynamicTypeSize(.accessibility5)
}
