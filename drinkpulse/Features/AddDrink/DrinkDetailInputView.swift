import SwiftUI
import SwiftData

/// Add Drink step 2: serving, name, time, notes and price for one preset, optionally pre-filled
/// from a Recent drink (plan 0047, D0047-4).
struct DrinkDetailInputView: View {
    let preset: DrinkTypePreset
    let prefill: DrinkPrefill?
    let dismissSheet: DismissAction

    @Environment(\.modelContext) var modelContext
    @Environment(\.healthService) var healthService
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.drinkLogged) var drinkLogged

    @Query private var profiles: [UserProfile]

    @State var volumeMl: Double
    @State var abvValue: Double
    @State var abvValues: [Double]
    @State var count = 1
    @State var date = Date.now
    @State var customNameText: String
    @State var priceText = ""
    /// The currency the user picked on this form; until then the profile currency applies.
    /// Derived rather than seeded in `onAppear`, so the first render already shows the
    /// profile currency (seeding raced the price row's first render).
    @State var chosenCurrency: String?
    @State var notesText = ""
    /// `onAppear` runs again when a pushed `.navigationLink` picker pops back (accessibility
    /// sizes); the defaults are applied only on the first appearance so they never overwrite a
    /// choice or a prefill.
    @State private var didAppear = false

    init(preset: DrinkTypePreset, prefill: DrinkPrefill? = nil, dismissSheet: DismissAction) {
        self.preset = preset
        self.prefill = prefill
        self.dismissSheet = dismissSheet
        let defaultABV = preset.abvValues[preset.defaultABVIndex]
        _volumeMl = State(initialValue: prefill?.volumeMl ?? preset.defaultVolumeMl)
        _abvValue = State(initialValue: prefill.map {
            DrinkServingOptions.nearest($0.abv, in: preset.abvValues)
        } ?? defaultABV)
        _abvValues = State(initialValue: preset.abvValues)
        _customNameText = State(initialValue: prefill?.customName ?? "")
    }

    var abvStepPermille: Int { profiles.first?.abvPrecisionPermille ?? 5 }
    var unitSystem: UnitSystem { profiles.first?.unitSystem ?? .metric }

    var volumeOptions: [DrinkTypePreset.VolumeOption] {
        DrinkServingOptions.volumeOptions(for: preset, in: unitSystem, keeping: prefill?.volumeMl)
    }

    var selectedVolumeMl: Double { volumeMl }
    var selectedABV: Double { abvValue }

    var priceCurrency: String {
        chosenCurrency ?? profiles.first?.currency ?? CurrencyCatalog.defaultCode
    }

    private var currencyBinding: Binding<String> {
        Binding(get: { priceCurrency }, set: { chosenCurrency = $0 })
    }

    var alcoholUnit: AlcoholUnit { profiles.first?.alcoholUnit ?? .standardDrinks }
    var guideline: GuidelineChoice { profiles.first?.guidelineChoice ?? .who }

    var body: some View {
        Form {
            Group {
                CustomNameSuggestionSection(customName: $customNameText)

                DrinkServingSection(
                    volumeMl: $volumeMl,
                    abv: $abvValue,
                    count: $count,
                    volumeOptions: volumeOptions,
                    abvValues: abvValues,
                    unitSystem: unitSystem
                )

                Section {
                    DatePicker(
                        String(localized: "addDrink.date"),
                        selection: $date,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                EditNotesSection(notes: $notesText)

                PriceCurrencySection(priceText: $priceText, currencyCode: currencyBinding)

                Section {
                    PureAlcoholRow(grams: previewMassGrams, alcoholUnit: alcoholUnit, guideline: guideline)
                }
            }
            .brandRowBackground()
        }
        .brandListBackground()
        .navigationTitle(preset.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didAppear else { return }
            didAppear = true
            // Snap from the Recent drink's stored ABV (or the preset default), not from the
            // value `init` already rounded to the 0.5 % grid (final review, Important 1).
            abvValues = DrinkServingOptions.abvValues(for: preset, stepPermille: abvStepPermille)
            abvValue = DrinkServingOptions.strength(
                prefill?.abv ?? preset.abvValues[preset.defaultABVIndex],
                for: preset, stepPermille: abvStepPermille)
            if prefill == nil {
                volumeMl = preset.defaultVolumeMl(for: unitSystem)
            }
        }
        .onChange(of: abvStepPermille) { _, _ in syncAbvValues() }
        .onChange(of: unitSystem) { _, _ in resolveVolumeForUnit() }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) { save() }
                    .accessibilityIdentifier("drinkForm.confirm")
            }
        }
    }
}

#Preview("Light") {
    DetailPreviewHost()
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}

#Preview("Recent prefill · AX5") {
    DetailPreviewHost(prefill: DrinkPrefill(volumeMl: 345, abv: 0.0537, customName: "House Red"))
        .dynamicTypeSize(.accessibility5)
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}

private struct DetailPreviewHost: View {
    @Environment(\.dismiss) private var dismiss
    var prefill: DrinkPrefill?

    var body: some View {
        NavigationStack {
            DrinkDetailInputView(preset: .wine, prefill: prefill, dismissSheet: dismiss)
        }
    }
}
