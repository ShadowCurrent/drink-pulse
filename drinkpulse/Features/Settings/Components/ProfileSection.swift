import SwiftUI
import SwiftData

/// Profile: biological sex and date of birth. Writes go through the touching bindings, so a
/// same-value selection never bumps `modifiedDate` (LWW contract).
struct ProfileSection: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Section {
            Picker(String(localized: "settings.sex"), selection: profile.touchingBinding(\.biologicalSex)) {
                Text(String(localized: "settings.sex.male")).tag(BiologicalSex.male)
                Text(String(localized: "settings.sex.female")).tag(BiologicalSex.female)
            }
            DatePicker(
                String(localized: "settings.dateOfBirth"),
                selection: profile.dateOfBirthBinding,
                in: Self.dateOfBirthRange,
                displayedComponents: [.date]
            )
        } header: {
            Text(String(localized: "settings.section.profile"))
        }
    }

    private static var dateOfBirthRange: ClosedRange<Date> {
        let cal = Calendar.current
        let oldest = cal.date(byAdding: .year, value: -120, to: .now) ?? .distantPast
        let youngest = cal.date(byAdding: .year, value: -13, to: .now) ?? .now
        return oldest...youngest
    }
}

#Preview {
    Form { ProfileSection(profile: .preview) }
        .modelContainer(for: UserProfile.self, inMemory: true)
}
