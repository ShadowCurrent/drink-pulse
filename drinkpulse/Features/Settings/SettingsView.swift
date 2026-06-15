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

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsSection("settings.section.appearance") {
                    AppearanceRows()
                }

                SettingsSection("settings.section.profile") {
                    SettingsRow(String(localized: "settings.sex")) {
                        Picker(String(localized: "settings.sex"), selection: $profile.biologicalSex) {
                            Text(String(localized: "settings.sex.male")).tag(BiologicalSex.male)
                            Text(String(localized: "settings.sex.female")).tag(BiologicalSex.female)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    Divider()
                    SettingsRow(String(localized: "settings.dateOfBirth")) {
                        DatePicker(
                            String(localized: "settings.dateOfBirth"),
                            selection: dobBinding,
                            in: dobRange,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                    }
                }

                SettingsSection("settings.section.guideline") {
                    guidelineRow
                }

                SettingsSection("settings.section.preferences") {
                    SettingsRow(String(localized: "settings.volumeUnit")) {
                        Picker(String(localized: "settings.volumeUnit"), selection: $profile.unitSystem) {
                            Text(String(localized: "settings.volumeUnit.ml")).tag(UnitSystem.metric)
                            Text(String(localized: "settings.volumeUnit.usOz")).tag(UnitSystem.usCustomary)
                            Text(String(localized: "settings.volumeUnit.imperialOz")).tag(UnitSystem.imperial)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    Divider()
                    SettingsRow(String(localized: "settings.alcoholUnit")) {
                        Picker(String(localized: "settings.alcoholUnit"), selection: $profile.alcoholUnit) {
                            ForEach(AlcoholUnit.allCases, id: \.self) { Text($0.displayName).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    Divider()
                    SettingsRow(String(localized: "settings.abvPrecision")) {
                        Picker(String(localized: "settings.abvPrecision"), selection: $profile.abvPrecisionPermille) {
                            Text(abvPrecisionLabel(permille: 5)).tag(5)
                            Text(abvPrecisionLabel(permille: 1)).tag(1)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }

                SettingsSection("settings.section.privacy") {
                    SettingsActionRow(
                        title: String(localized: "settings.systemLock"),
                        systemImage: "lock.shield",
                        trailingSystemImage: "arrow.up.right.square"
                    ) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                DataSection()
            }
            .padding()
        }
        .sheet(isPresented: $showGuidelinePicker) {
            GuidelinePickerSheet(selection: $profile.guidelineChoice, sex: profile.biologicalSex)
        }
    }

    // MARK: - Guideline row

    private var guidelineRow: some View {
        Button { showGuidelinePicker = true } label: {
            HStack {
                Text(profile.guidelineChoice.displayName)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var dobBinding: Binding<Date> {
        Binding(
            get: { profile.dateOfBirth ?? dobDefaultDate },
            set: { profile.dateOfBirth = $0 }
        )
    }

    private var dobRange: ClosedRange<Date> {
        let cal = Calendar.current
        let oldest = cal.date(byAdding: .year, value: -120, to: .now) ?? .distantPast
        let youngest = cal.date(byAdding: .year, value: -13, to: .now) ?? .now
        return oldest...youngest
    }

    private var dobDefaultDate: Date {
        Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now
    }

    private func abvPrecisionLabel(permille: Int) -> String {
        let pct = (Double(permille) / 1000.0).formatted(.percent.precision(.fractionLength(1)))
        let key = permille == 5 ? "settings.abvPrecision.coarse" : "settings.abvPrecision.fine"
        return String(format: String(localized: String.LocalizationValue(key)), pct)
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

#Preview("Empty (seeding)") {
    NavigationStack { SettingsView() }
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}
