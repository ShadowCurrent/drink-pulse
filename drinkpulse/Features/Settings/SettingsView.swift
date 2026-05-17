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
        .navigationTitle(String(localized: "tab.settings"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsForm: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Form {
            Section(String(localized: "settings.section.profile")) {
                Picker(String(localized: "settings.sex"), selection: $profile.biologicalSex) {
                    Text(String(localized: "settings.sex.male")).tag(BiologicalSex.male)
                    Text(String(localized: "settings.sex.female")).tag(BiologicalSex.female)
                }

                LabeledContent(String(localized: "settings.age")) {
                    Stepper("\(profile.ageYears)", value: $profile.ageYears, in: 13...120)
                }
            }

            Section(String(localized: "settings.section.guideline")) {
                Picker(String(localized: "settings.section.guideline"), selection: $profile.guidelineChoice) {
                    ForEach(GuidelineChoice.allCases.filter { $0 != .custom }, id: \.self) { choice in
                        VStack(alignment: .leading) {
                            Text(choice.displayName)
                            Text(choice.thresholdSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(choice)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section(String(localized: "settings.section.preferences")) {
                Picker(String(localized: "settings.volumeUnit"), selection: $profile.unitSystem) {
                    Text(String(localized: "settings.volumeUnit.ml")).tag(UnitSystem.metric)
                    Text(String(localized: "settings.volumeUnit.usOz")).tag(UnitSystem.usCustomary)
                    Text(String(localized: "settings.volumeUnit.imperialOz")).tag(UnitSystem.imperial)
                }

                Picker(String(localized: "settings.alcoholUnit"), selection: $profile.alcoholUnit) {
                    ForEach(AlcoholUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }

                Picker(String(localized: "settings.abvPrecision"), selection: $profile.abvPrecisionPermille) {
                    Text(String(localized: "settings.abvPrecision.coarse")).tag(5)
                    Text(String(localized: "settings.abvPrecision.fine")).tag(1)
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

private extension GuidelineChoice {
    var displayName: String {
        switch self {
        case .who:    return String(localized: "settings.guideline.who")
        case .de:     return String(localized: "settings.guideline.de")
        case .uk:     return String(localized: "settings.guideline.uk")
        case .us:     return String(localized: "settings.guideline.us")
        case .custom: return String(localized: "settings.guideline.custom")
        }
    }

    var thresholdSummary: String {
        switch self {
        case .who:    return "20 g/day · 100 g/week"
        case .de:     return "24 g/day · 168 g/week"
        case .uk:     return "112 g/week (no daily limit)"
        case .us:     return "28 g/day · 196 g/week"
        case .custom: return ""
        }
    }
}

#Preview("With profile") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self, GuidelineProfile.self,
        configurations: config
    )
    container.mainContext.insert(UserProfile.preview)
    return NavigationStack { SettingsView() }
        .modelContainer(container)
}

#Preview("Empty (seeding)") {
    NavigationStack { SettingsView() }
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self, GuidelineProfile.self],
            inMemory: true
        )
}
