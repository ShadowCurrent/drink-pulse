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
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                sectionHeader("settings.section.profile")
                profileCard

                sectionHeader("settings.section.guideline")
                guidelineCard

                sectionHeader("settings.section.preferences")
                preferencesCard

                sectionHeader("settings.section.privacy")
                privacyCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Section cards

    private var profileCard: some View {
        VStack(spacing: 0) {
            SettingsRow(String(localized: "settings.sex")) {
                Picker(String(localized: "settings.sex"), selection: $profile.biologicalSex) {
                    Text(String(localized: "settings.sex.male")).tag(BiologicalSex.male)
                    Text(String(localized: "settings.sex.female")).tag(BiologicalSex.female)
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            rowDivider
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
        .frame(maxWidth: .infinity)
        .dpGlassCard()
        .padding(.bottom, 16)
    }

    private var guidelineCard: some View {
        Button { showGuidelinePicker = true } label: {
            Group {
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "settings.section.guideline"))
                            .foregroundStyle(.primary)
                        HStack {
                            Text(profile.guidelineChoice.displayName)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack {
                        Text(String(localized: "settings.section.guideline"))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(profile.guidelineChoice.displayName)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption).foregroundStyle(.tertiary)
                    }
                }
            }
            .cardRow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .dpGlassCard()
        .padding(.bottom, 16)
        .sheet(isPresented: $showGuidelinePicker) {
            GuidelinePickerSheet(selection: $profile.guidelineChoice, sex: profile.biologicalSex)
        }
    }

    private var preferencesCard: some View {
        VStack(spacing: 0) {
            SettingsRow(String(localized: "settings.volumeUnit")) {
                Picker(String(localized: "settings.volumeUnit"), selection: $profile.unitSystem) {
                    Text(String(localized: "settings.volumeUnit.ml")).tag(UnitSystem.metric)
                    Text(String(localized: "settings.volumeUnit.usOz")).tag(UnitSystem.usCustomary)
                    Text(String(localized: "settings.volumeUnit.imperialOz")).tag(UnitSystem.imperial)
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            rowDivider
            SettingsRow(String(localized: "settings.alcoholUnit")) {
                Picker(String(localized: "settings.alcoholUnit"), selection: $profile.alcoholUnit) {
                    ForEach(AlcoholUnit.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            rowDivider
            SettingsRow(String(localized: "settings.abvPrecision")) {
                Picker(String(localized: "settings.abvPrecision"), selection: $profile.abvPrecisionPermille) {
                    Text(abvPrecisionLabel(permille: 5)).tag(5)
                    Text(abvPrecisionLabel(permille: 1)).tag(1)
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
        .frame(maxWidth: .infinity)
        .dpGlassCard()
        .padding(.bottom, 16)
    }

    private var privacyCard: some View {
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
            .cardRow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .dpGlassCard()
    }

    // MARK: - Helpers

    private var rowDivider: some View { Divider().padding(.leading, 16) }

    private func sectionHeader(_ key: String) -> some View {
        Text(String(localized: String.LocalizationValue(key)))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 4)
            .padding(.top, 4)
    }

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

// MARK: - Card row layout helpers

/// Label + control row that stacks vertically at accessibility type sizes.
private struct SettingsRow<Content: View>: View {
    let label: String
    let content: Content
    @Environment(\.dynamicTypeSize) private var typeSize

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } else {
            HStack {
                Text(label)
                Spacer()
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

private extension View {
    func cardRow() -> some View {
        self.padding(.horizontal, 16).padding(.vertical, 12)
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
