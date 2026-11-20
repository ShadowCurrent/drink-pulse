import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                SettingsForm(profile: profile)
            } else {
                ProgressView()
            }
        }
        .animation(nil, value: profiles.isEmpty)
        .brandNavigationTitle("tab.settings")
        .dp_logViewLoad("Settings")
    }
}

/// Settings as a system `Form` on the Frost tint (plan 0043). Each section is its own view in
/// `Components/`; feature state stays in those views.
private struct SettingsForm: View {
    @Bindable var profile: UserProfile
    @State private var showGuidelinePicker = false

    var body: some View {
        Form {
            Group {
                ProfileSection(profile: profile)

                Section {
                    guidelineRow
                } header: {
                    Text(String(localized: "settings.section.guideline"))
                }

                PreferencesSection(profile: profile)

                ReminderSection()

                WeeklySummarySection()

                HealthSection()

                PrivacySection()

                DataSection()

                AppVersionFooter()
            }
            .brandRowBackground()
        }
        .brandListBackground()
        .sheet(isPresented: $showGuidelinePicker) {
            GuidelinePickerSheet(
                selection: profile.touchingBinding(\.guidelineChoice),
                sex: profile.biologicalSex
            )
        }
    }

    private var guidelineRow: some View {
        Button { showGuidelinePicker = true } label: {
            HStack {
                Text(profile.guidelineChoice.displayName)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("With profile") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(UserProfile.preview)
    return NavigationStack { SettingsView() }
        .modelContainer(container)
}

#Preview("With profile, Dark") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(UserProfile.preview)
    return NavigationStack { SettingsView() }
        .modelContainer(container)
        .preferredColorScheme(.dark)
}

#Preview("With profile, Accessibility 5") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(UserProfile.preview)
    return NavigationStack { SettingsView() }
        .modelContainer(container)
        .dynamicTypeSize(.accessibility5)
}

#Preview("Empty (seeding)") {
    NavigationStack { SettingsView() }
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}
