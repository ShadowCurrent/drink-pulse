import SwiftUI

/// About You. Sex is required (D0048-4): nothing is selected until a tap and Continue stays
/// disabled until then. Date of birth is optional and starts behind an "Add" button (D0048-8),
/// so no default date is shown that would never be saved.
struct ProfileStep: View {
    @Binding var sex: BiologicalSex?
    @Binding var dateOfBirth: Date?
    let onContinue: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Domain `BiologicalSex` is not `CaseIterable`; the order matches Settings.
    private static let sexOptions: [BiologicalSex] = [.male, .female]

    private var dobBinding: Binding<Date> {
        Binding(get: { dateOfBirth ?? Self.dobDefault }, set: { dateOfBirth = $0 })
    }

    private static var dobDefault: Date {
        Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now
    }

    private var dobRange: ClosedRange<Date> {
        let cal = Calendar.current
        let oldest = cal.date(byAdding: .year, value: -120, to: .now) ?? .distantPast
        let youngest = cal.date(byAdding: .year, value: -13, to: .now) ?? .now
        return oldest...youngest
    }

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

                VStack(alignment: .leading, spacing: 8) {
                    Label(String(localized: "onboarding.profile.dateOfBirth"), systemImage: "calendar")
                        .font(.headline)
                    dateOfBirthControl
                    Text(String(localized: "onboarding.profile.privacy"))
                        .font(.footnote)
                        .foregroundStyle(Color.dpSecondaryText)
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

    @ViewBuilder private var dateOfBirthControl: some View {
        if dateOfBirth == nil {
            Button(String(localized: "onboarding.profile.addDateOfBirth")) {
                dateOfBirth = Self.dobDefault
            }
            .buttonStyle(.bordered)
        } else {
            DatePicker(
                String(localized: "onboarding.profile.dateOfBirth"),
                selection: dobBinding,
                in: dobRange,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
    }

    private static func title(for sex: BiologicalSex) -> String {
        switch sex {
        case .male: String(localized: "settings.sex.male")
        case .female: String(localized: "settings.sex.female")
        }
    }
}

private func profilePreview(sex: BiologicalSex? = nil, dob: Date? = nil) -> some View {
    ProfileStepPreview(sex: sex, dob: dob)
        .background { BrandBackdrop().ignoresSafeArea() }
}

private struct ProfileStepPreview: View {
    @State var sex: BiologicalSex?
    @State var dob: Date?
    var body: some View { ProfileStep(sex: $sex, dateOfBirth: $dob, onContinue: {}) }
}

#Preview("Nothing chosen") { profilePreview() }

#Preview("Chosen + date") {
    profilePreview(sex: .female, dob: Calendar.current.date(byAdding: .year, value: -34, to: .now))
}

#Preview("Dark") { profilePreview().preferredColorScheme(.dark) }

#Preview("AX5") { profilePreview().dynamicTypeSize(.accessibility5) }

#Preview("AX5 · chosen") { profilePreview(sex: .male).dynamicTypeSize(.accessibility5) }
