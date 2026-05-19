import SwiftUI
import SwiftData
import UIKit

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

    var body: some View {
        Form {
            Section(String(localized: "settings.section.profile")) {
                Picker(String(localized: "settings.sex"), selection: $profile.biologicalSex) {
                    Text(String(localized: "settings.sex.male")).tag(BiologicalSex.male)
                    Text(String(localized: "settings.sex.female")).tag(BiologicalSex.female)
                }

                DatePicker(
                    String(localized: "settings.dateOfBirth"),
                    selection: Binding(
                        get: { profile.dateOfBirth ?? dobDefaultDate },
                        set: { profile.dateOfBirth = $0 }
                    ),
                    in: dobRange,
                    displayedComponents: [.date]
                )
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
                    GuidelinePickerSheet(selection: $profile.guidelineChoice, sex: profile.biologicalSex)
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

            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Text(String(localized: "settings.systemLock"))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(String(localized: "settings.section.privacy"))
            } footer: {
                Text(String(localized: "settings.systemLock.footer"))
            }
        }
    }
}

private struct GuidelinePickerSheet: View {
    @Binding var selection: GuidelineChoice
    let sex: BiologicalSex
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
                                Text(choice.thresholdSummary(for: sex))
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

    func thresholdSummary(for sex: BiologicalSex) -> String {
        let l = limits(for: sex)
        if l.dailyGrams == 0 {
            return String(format: "%.0f g/week (no daily limit)", l.weeklyGrams)
        }
        return String(format: "%.0f g/day · %.0f g/week", l.dailyGrams, l.weeklyGrams)
    }
}

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
