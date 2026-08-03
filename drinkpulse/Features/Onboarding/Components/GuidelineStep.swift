import SwiftUI

struct GuidelineStep: View {
    let selection: GuidelineChoice
    let sex: BiologicalSex
    let onSelect: (GuidelineChoice) -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
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

            ScrollView {
                // Titleless section: this step already carries its own large title
                // above, so a repeated uppercase header would add nothing.
                SettingsSection {
                    ForEach(GuidelineChoice.selectable, id: \.self) { choice in
                        // One subview per element, separator keyed off the value rather
                        // than an enumerated index — same shape as the Settings picker.
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
                // Same 24pt gutter the title block and Continue button already use.
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }

            Button(action: onDone) {
                Text(String(localized: "onboarding.step.continue"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
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
