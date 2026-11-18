import SwiftUI
import SwiftData

struct DrinkDetailInputView: View {
    let preset: DrinkTypePreset
    let dismissSheet: DismissAction

    @Environment(\.modelContext) var modelContext
    @Environment(\.healthService) var healthService
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .callout) private var wheelHeight: Double = 160
    @ScaledMetric(relativeTo: .callout) private var strengthWheelWidth: Double = 88
    @ScaledMetric(relativeTo: .callout) private var amountWheelWidth: Double = 60

    @Query private var profiles: [UserProfile]

    @State var volumeMl: Double
    @State var abvValue: Double
    @State var abvValues: [Double]
    @State var count = 1
    @State var date = Date.now
    @State var customNameText = ""
    @State var priceText = ""
    @State var priceCurrency = CurrencyCatalog.defaultCode
    @State var notesText = ""

    init(preset: DrinkTypePreset, dismissSheet: DismissAction) {
        self.preset = preset
        self.dismissSheet = dismissSheet
        _volumeMl = State(initialValue: preset.defaultVolumeMl)
        _abvValue = State(initialValue: preset.abvValues[preset.defaultABVIndex])
        _abvValues = State(initialValue: preset.abvValues)
    }

    var abvStepPermille: Int { profiles.first?.abvPrecisionPermille ?? 5 }
    var unitSystem: UnitSystem { profiles.first?.unitSystem ?? .metric }

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
            CustomNameSuggestionSection(customName: $customNameText)

            Section(String(localized: "addDrink.serving")) {
                if dynamicTypeSize.isAccessibilitySize {
                    servingMenuPickers
                } else {
                    servingWheelPickers
                }
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
        .sheetActions(cancel: nil, save: { save() })
    }
}

extension DrinkDetailInputView {
    /// Three wheels side by side; they scale with the text size but cannot hold the values at
    /// accessibility sizes, which use `servingMenuPickers` instead.
    fileprivate var servingWheelPickers: some View {
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
            .frame(width: strengthWheelWidth)
            .labelsHidden()

            Picker(String(localized: "addDrink.amount"), selection: $count) {
                ForEach(1...10, id: \.self) { n in
                    Text("\(n)×").font(.callout).tag(n)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: amountWheelWidth)
            .labelsHidden()
        }
        .frame(height: wheelHeight)
        .listRowInsets(EdgeInsets())
    }

    /// Stacked navigation-link rows with visible labels, so values and names wrap instead of overlapping.
    fileprivate var servingMenuPickers: some View {
        Group {
            Picker(String(localized: "addDrink.volume"), selection: $volumeMl) {
                ForEach(volumeOptions, id: \.volumeMl) { item in
                    Text(item.label(in: unitSystem)).tag(item.volumeMl)
                }
            }
            Picker(String(localized: "addDrink.strength"), selection: $abvValue) {
                ForEach(abvValues, id: \.self) { value in
                    Text(String(format: "%.1f%%", value * 100)).tag(value)
                }
            }
            Picker(String(localized: "addDrink.amount"), selection: $count) {
                ForEach(1...10, id: \.self) { n in
                    Text("\(n)×").tag(n)
                }
            }
        }
        .pickerStyle(.navigationLink)
    }
}

#Preview {
    AddDrinkView()
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}

#Preview("Step 2 Accessibility 5") {
    DetailPreviewHost()
        .dynamicTypeSize(.accessibility5)
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}

private struct DetailPreviewHost: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if let wine = DrinkTypePreset.all.first(where: { $0.category == .wine }) {
                DrinkDetailInputView(preset: wine, dismissSheet: dismiss)
            }
        }
    }
}
