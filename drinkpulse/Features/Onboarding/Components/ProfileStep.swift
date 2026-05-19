import SwiftUI

struct ProfileStep: View {
    @Binding var sex: BiologicalSex?
    @Binding var dateOfBirth: Date?
    let onContinue: () -> Void
    let onSkip: () -> Void

    private var dobBinding: Binding<Date> {
        Binding(
            get: { dateOfBirth ?? dobDefault },
            set: { dateOfBirth = $0 }
        )
    }

    private var dobDefault: Date {
        Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now
    }

    private var dobRange: ClosedRange<Date> {
        let cal = Calendar.current
        let oldest = cal.date(byAdding: .year, value: -120, to: .now) ?? .distantPast
        let youngest = cal.date(byAdding: .year, value: -13, to: .now) ?? .now
        return oldest...youngest
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "onboarding.profile.title"))
                        .font(.largeTitle.bold())

                    Text(String(localized: "onboarding.profile.body"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(String(localized: "onboarding.profile.sex"), systemImage: "person.fill")
                            .font(.headline)

                        Picker(String(localized: "onboarding.profile.sex"), selection: Binding(
                            get: { sex ?? .male },
                            set: { sex = $0 }
                        )) {
                            Text(String(localized: "settings.sex.male")).tag(BiologicalSex.male)
                            Text(String(localized: "settings.sex.female")).tag(BiologicalSex.female)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel(String(localized: "onboarding.profile.sex"))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label(String(localized: "onboarding.profile.dateOfBirth"), systemImage: "calendar")
                            .font(.headline)

                        DatePicker(
                            String(localized: "onboarding.profile.dateOfBirth"),
                            selection: dobBinding,
                            in: dobRange,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(String(localized: "onboarding.profile.privacy"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onContinue) {
                    Text(String(localized: "onboarding.step.continue"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)

                Button(action: onSkip) {
                    Text(String(localized: "onboarding.step.skip"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    @Previewable @State var sex: BiologicalSex? = nil
    @Previewable @State var dob: Date? = nil
    ProfileStep(sex: $sex, dateOfBirth: $dob, onContinue: {}, onSkip: {})
}
