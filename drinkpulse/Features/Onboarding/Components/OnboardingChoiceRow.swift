import SwiftUI

/// One choice inside an `OnboardingCard`: a title, an optional detail line and a checkmark when
/// selected. A plain button with the `.isSelected` trait, so VoiceOver reads "Selected"; it grows
/// with Dynamic Type. Shared by the guideline list and the About You sex choice at accessibility
/// sizes (D0048-7).
struct OnboardingChoiceRow: View {
    let title: String
    var detail: String?
    let isSelected: Bool
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    if let detail {
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)
                        .accessibilityHidden(true)
                }
            }
            .padding(CardMetrics.padding)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}

#Preview {
    OnboardingCard {
        OnboardingChoiceRow(title: "WHO", detail: "20 g a day", isSelected: true,
                            identifier: "preview.who", action: {})
        Divider().padding(.leading, CardMetrics.padding)
        OnboardingChoiceRow(title: "Germany", detail: nil, isSelected: false,
                            identifier: "preview.de", action: {})
    }
    .padding()
}
