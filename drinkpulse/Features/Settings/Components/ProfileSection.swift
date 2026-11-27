import SwiftUI
import SwiftData

/// Profile: biological sex. Writes go through the touching binding, so a same-value selection
/// never bumps `modifiedDate` (LWW contract).
struct ProfileSection: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Section {
            Picker(String(localized: "settings.sex"), selection: profile.touchingBinding(\.biologicalSex)) {
                Text(String(localized: "settings.sex.male")).tag(BiologicalSex.male)
                Text(String(localized: "settings.sex.female")).tag(BiologicalSex.female)
            }
        } header: {
            Text(String(localized: "settings.section.profile"))
                .foregroundStyle(Color.dpSecondaryText)
        }
    }
}

#Preview {
    Form { ProfileSection(profile: .preview) }
        .modelContainer(for: UserProfile.self, inMemory: true)
}
