import SwiftUI
import SwiftData

struct DrinkDetailInputView: View {
    let preset: DrinkTypePreset

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissSheet) var dismissSheet

    @Query private var profiles: [UserProfile]

    @State var volumeMl: Double
    @State var abvValue: Double
    // The ABV wheel can hold 200–996 rows. Cache it in @State so it is built once
    // (on appear / when precision changes) instead of being rebuilt on every body
    // pass — rebuilding it per frame was the main Add-Drink stall.
    @State var abvValues: [Double]
    @State var count = 1
    @State var date = Date.now
    @State var customNameText = ""
    @State var priceText = ""
    @State var priceCurrency = CurrencyCatalog.defaultCode
    @State var notesText = ""

    init(preset: DrinkTypePreset) {
        self.preset = preset
        _volumeMl = State(initialValue: preset.defaultVolumeMl)
        _abvValue = State(initialValue: preset.abvValues[preset.defaultABVIndex])
        _abvValues = State(initialValue: preset.abvValues)
    }

    var abvStepPermille: Int { profiles.first?.abvPrecisionPermille ?? 5 }
    var unitSystem: UnitSystem { profiles.first?.unitSystem ?? .metric }

    /// Region-native serving options for the active unit system. Always non-empty
    /// (coverage invariant).
    var volumeOptions: [DrinkTypePreset.VolumeOption] {
        if preset.category == .custom {
            return DrinkTypePreset.customVolumes(for: unitSystem)
        }
        let options = preset.volumes(for: unitSystem)
        return options.isEmpty ? preset.volumes : options
    }

    var selectedVolumeMl: Double { volumeMl }
    var selectedABV: Double { abvValue }

    var alcoholUnit: AlcoholUnit { profiles.first?.alcoholUnit ?? .standardDrinks }
    var guideline: GuidelineChoice { profiles.first?.guidelineChoice ?? .who }

    var body: some View {
        Form {
            Section(String(localized: "editDrink.customName")) {
                TextField(String(localized: "editDrink.customNamePlaceholder"), text: $customNameText)
                    .autocorrectionDisabled()
                    .accessibilityLabel(String(localized: "editDrink.customName"))
            }

            Section(String(localized: "addDrink.serving")) {
                HStack(spacing: 0) {
                    Picker(String(localized: "addDrink.volume"), selection: $volumeMl) {
                        ForEach(volumeOptions, id: \.volumeMl) { item in
                            Text(item.label(in: unitSystem)).font(.callout).tag(item.volumeMl)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .labelsHidden()

                    Picker(String(localized: "addDrink.strength"), selection: $abvValue) {
                        ForEach(abvValues, id: \.self) { value in
                            Text(String(format: "%.1f%%", value * 100)).font(.callout).tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 88)
                    .labelsHidden()

                    Picker(String(localized: "addDrink.amount"), selection: $count) {
                        ForEach(1...10, id: \.self) { n in
                            Text("\(n)×").font(.callout).tag(n)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 60)
                    .labelsHidden()
                }
                .frame(height: 160)
                .listRowInsets(EdgeInsets())
            }

            Section {
                DatePicker(
                    String(localized: "addDrink.date"),
                    selection: $date,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            EditNotesSection(notes: $notesText)

            PriceCurrencySection(priceText: $priceText, currencyCode: $priceCurrency)

            Section {
                HStack {
                    Text(alcoholUnit.unitLabel(for: guideline))
                    Spacer()
                    Text(alcoholUnit.formattedValue(previewMassGrams, guideline: guideline))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(preset.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncAbvValues()
            volumeMl = preset.defaultVolumeMl(for: unitSystem)
            priceCurrency = profiles.first?.currency ?? CurrencyCatalog.defaultCode
        }
        .onChange(of: abvStepPermille) { _, _ in syncAbvValues() }
        .onChange(of: unitSystem) { _, _ in resolveVolumeForUnit() }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "action.cancel")) { dismissSheet?() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "action.save")) { save() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DrinkDetailInputView(preset: .beer)
    }
    .modelContainer(
        for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
        inMemory: true
    )
}
