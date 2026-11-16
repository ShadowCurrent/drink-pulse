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
        .navigationTitle(String(localized: "tab.settings"))
        .navigationBarTitleDisplayMode(.inline)
        .dp_logViewLoad("Settings")
    }
}

private struct SettingsForm: View {
    @Bindable var profile: UserProfile
    @State private var showGuidelinePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsSection("settings.section.profile") {
                    SettingsRow(String(localized: "settings.sex")) {
                        Picker(String(localized: "settings.sex"), selection: touching(\.biologicalSex)) {
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
                    AppearanceModeRow()
                    Divider()
                    SettingsRow(String(localized: "settings.volumeUnit")) {
                        SettingsMenuPicker(
                            title: String(localized: "settings.volumeUnit"),
                            selectionLabel: volumeUnitLabel,
                            selection: touching(\.unitSystem)
                        ) {
                            Text(String(localized: "settings.volumeUnit.ml")).tag(UnitSystem.metric)
                            Text(String(localized: "settings.volumeUnit.usOz")).tag(UnitSystem.usCustomary)
                            Text(String(localized: "settings.volumeUnit.imperialOz")).tag(UnitSystem.imperial)
                        }
                    }
                    Divider()
                    SettingsRow(String(localized: "settings.alcoholUnit")) {
                        SettingsMenuPicker(
                            title: String(localized: "settings.alcoholUnit"),
                            selectionLabel: profile.alcoholUnit.displayName,
                            selection: touching(\.alcoholUnit)
                        ) {
                            ForEach(AlcoholUnit.allCases, id: \.self) { Text($0.displayName).tag($0) }
                        }
                    }
                    Divider()
                    SettingsRow(String(localized: "settings.abvPrecision")) {
                        SettingsMenuPicker(
                            title: String(localized: "settings.abvPrecision"),
                            selectionLabel: abvPrecisionLabel(permille: profile.abvPrecisionPermille),
                            selection: touching(\.abvPrecisionPermille)
                        ) {
                            Text(abvPrecisionLabel(permille: 5)).tag(5)
                            Text(abvPrecisionLabel(permille: 1)).tag(1)
                        }
                    }
                    Divider()
                    SettingsRow(String(localized: "settings.currency")) {
                        SettingsMenuPicker(
                            title: String(localized: "settings.currency"),
                            selectionLabel: currencyLabel,
                            selection: touching(\.currency)
                        ) {
                            ForEach(CurrencyCatalog.common) { option in
                                Text("\(option.code) · \(option.symbol)").tag(option.code)
                            }
                        }
                    }
                }

                ReminderSection()

                WeeklySummarySection()

                HealthSection()

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

                AppVersionFooter()
            }
            .padding()
        }
        .sheet(isPresented: $showGuidelinePicker) {
            GuidelinePickerSheet(selection: touching(\.guidelineChoice), sex: profile.biologicalSex)
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

    private func touching<T: Equatable>(_ keyPath: ReferenceWritableKeyPath<UserProfile, T>) -> Binding<T> {
        Binding(
            get: { profile[keyPath: keyPath] },
            set: { newValue in
                guard profile[keyPath: keyPath] != newValue else { return }
                profile[keyPath: keyPath] = newValue
                profile.touch()
            }
        )
    }

    private var dobBinding: Binding<Date> {
        Binding(
            get: { profile.dateOfBirth ?? dobDefaultDate },
            set: {
                guard profile.dateOfBirth != $0 else { return }
                profile.dateOfBirth = $0
                profile.touch()
            }
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

    private var volumeUnitLabel: String {
        switch profile.unitSystem {
        case .metric: String(localized: "settings.volumeUnit.ml")
        case .usCustomary: String(localized: "settings.volumeUnit.usOz")
        case .imperial: String(localized: "settings.volumeUnit.imperialOz")
        }
    }

    private var currencyLabel: String {
        guard let option = CurrencyCatalog.common.first(where: { $0.code == profile.currency }) else {
            return profile.currency
        }
        return "\(option.code) · \(option.symbol)"
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
