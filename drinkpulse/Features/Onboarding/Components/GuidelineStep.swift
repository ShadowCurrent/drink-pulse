import SwiftUI

struct GuidelineStep: View {
    let selection: GuidelineChoice
    let sex: BiologicalSex
    let onSelect: (GuidelineChoice) -> Void
    let onDone: () -> Void

    private let choices: [GuidelineChoice] = [.who, .de, .uk, .us, .au, .ca]

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

            List(choices, id: \.self) { choice in
                Button {
                    onSelect(choice)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(choice.onboardingName)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(choice.thresholdSummary(for: sex))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selection == choice {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == choice ? .isSelected : [])
            }
            .listStyle(.insetGrouped)

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

private extension GuidelineChoice {
    var onboardingName: String {
        switch self {
        case .who:    return String(localized: "settings.guideline.who")
        case .de:     return String(localized: "settings.guideline.de")
        case .uk:     return String(localized: "settings.guideline.uk")
        case .us:     return String(localized: "settings.guideline.us")
        case .au:     return String(localized: "settings.guideline.au")
        case .ca:     return String(localized: "settings.guideline.ca")
        case .custom: return String(localized: "settings.guideline.custom")
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
