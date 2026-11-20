import SwiftUI
import SwiftData

/// Guideline as a system picker that pushes its option list (plan 0043 D0043-3). The pushed list
/// gives the checkmark, the selected trait and the pop on selection (SwiftUI docs,
/// `NavigationLinkPickerStyle`). Each option shows its thresholds for the profile's sex.
struct GuidelineSection: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Section {
            Picker(
                String(localized: "settings.section.guideline"),
                selection: profile.touchingBinding(\.guidelineChoice)
            ) {
                ForEach(GuidelineChoice.selectable, id: \.self) { choice in
                    VStack(alignment: .leading) {
                        Text(choice.displayName)
                        Text(choice.thresholdSummary(for: profile.biologicalSex))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .tag(choice)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text(String(localized: "settings.section.guideline"))
        }
    }
}

#Preview {
    NavigationStack { Form { GuidelineSection(profile: .preview) } }
        .modelContainer(for: UserProfile.self, inMemory: true)
}
