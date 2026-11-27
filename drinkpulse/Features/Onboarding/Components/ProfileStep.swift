import SwiftUI

/// About You asks only for biological sex. Sex is required (D0048-4): nothing is selected until
/// a tap and Continue stays disabled until then. Date of birth was removed on 2026-11-27
/// (quick 261127-l7y): nothing read it, so it was not worth storing.
struct ProfileStep: View {
    @Binding var sex: BiologicalSex?
    let onContinue: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Domain `BiologicalSex` is not `CaseIterable`; the order matches Settings.
    private static let sexOptions: [BiologicalSex] = [.male, .female]

    var body: some View {
        OnboardingStepLayout(
            buttonTitle: String(localized: "onboarding.step.continue"),
            isEnabled: sex != nil,
            action: onContinue
        ) {
            Spacer(minLength: 16)

            VStack(alignment: .leading, spacing: 28) {
                OnboardingHeading(
                    title: String(localized: "onboarding.profile.title"),
                    message: String(localized: "onboarding.profile.body")
                )

                VStack(alignment: .leading, spacing: 8) {
                    Label(String(localized: "onboarding.profile.sex"), systemImage: "person.fill")
                        .font(.headline)
                    sexChoice
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 16)
        }
    }

    /// A segmented control's labels do not grow with Dynamic Type, so at accessibility sizes the
    /// same choice is a card of rows with a checkmark (round 21, D0048-7).
    @ViewBuilder private var sexChoice: some View {
        if dynamicTypeSize.isAccessibilitySize {
            OnboardingCard {
                ForEach(Self.sexOptions, id: \.self) { option in
                    if option != Self.sexOptions.first {
                        Divider().padding(.leading, CardMetrics.padding)
                    }
                    OnboardingChoiceRow(
                        title: Self.title(for: option),
                        isSelected: sex == option,
                        identifier: "sexChoiceRow.\(option.rawValue)"
                    ) {
                        sex = option
                    }
                }
            }
        } else {
            // `Optional` tags, so a nil selection shows no segment selected.
            Picker(String(localized: "onboarding.profile.sex"), selection: $sex) {
                ForEach(Self.sexOptions, id: \.self) { option in
                    Text(Self.title(for: option)).tag(Optional(option))
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private static func title(for sex: BiologicalSex) -> String {
        switch sex {
        case .male: String(localized: "settings.sex.male")
        case .female: String(localized: "settings.sex.female")
        }
    }
}

private func profilePreview(sex: BiologicalSex? = nil) -> some View {
    ProfileStepPreview(sex: sex)
        .background { BrandBackdrop().ignoresSafeArea() }
}

private struct ProfileStepPreview: View {
    @State var sex: BiologicalSex?
    var body: some View { ProfileStep(sex: $sex, onContinue: {}) }
}

#Preview("Nothing chosen") { profilePreview() }

#Preview("Chosen") { profilePreview(sex: .female) }

#Preview("Dark") { profilePreview().preferredColorScheme(.dark) }

#Preview("AX5") { profilePreview().dynamicTypeSize(.accessibility5) }

#Preview("AX5 · chosen") { profilePreview(sex: .male).dynamicTypeSize(.accessibility5) }
