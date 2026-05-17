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
    @State private var showGuidelinePicker = false

    private func abvPrecisionLabel(permille: Int) -> String {
        let pct = (Double(permille) / 1000.0).formatted(.percent.precision(.fractionLength(1)))
        let key = permille == 5 ? "settings.abvPrecision.coarse" : "settings.abvPrecision.fine"
        return String(format: String(localized: String.LocalizationValue(key)), pct)
    }

    var body: some View {
        Form {
            Section(String(localized: "settings.section.profile")) {
                Picker(String(localized: "settings.sex"), selection: $profile.biologicalSex) {
                    Text(String(localized: "settings.sex.male")).tag(BiologicalSex.male)
                    Text(String(localized: "settings.sex.female")).tag(BiologicalSex.female)
                }

                LabeledContent(String(localized: "settings.age")) {
                    TextField("", value: $profile.ageYears, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .onChange(of: profile.ageYears) { _, new in
                            if new < 13  { profile.ageYears = 13 }
                            if new > 120 { profile.ageYears = 120 }
                        }
                }
            }

            Section(String(localized: "settings.section.guideline")) {
                HStack {
                    Text(String(localized: "settings.section.guideline"))
                    Spacer()
                    Text(profile.guidelineChoice.displayName)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture { showGuidelinePicker = true }
                .sheet(isPresented: $showGuidelinePicker) {
                    GuidelinePickerSheet(selection: $profile.guidelineChoice)
                }
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
                    Text(abvPrecisionLabel(permille: 5)).tag(5)
                    Text(abvPrecisionLabel(permille: 1)).tag(1)
                }
            }
        }
    }
}

private struct GuidelinePickerSheet: View {
    @Binding var selection: GuidelineChoice
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(GuidelineChoice.allCases.filter { $0 != .custom }, id: \.self) { choice in
                    Button {
                        selection = choice
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(choice.displayName)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Text(choice.thresholdSummary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selection == choice {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(String(localized: "settings.section.guideline"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
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
