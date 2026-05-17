import SwiftUI
import SwiftData

struct DrinkDetailInputView: View {
    let preset: DrinkTypePreset

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissSheet) private var dismissSheet

    @Query private var profiles: [UserProfile]

    @State private var volumeIndex: Int
    @State private var abvIndex: Int
    @State private var count = 1
    @State private var date = Date.now
    @State private var priceText = ""

    init(preset: DrinkTypePreset) {
        self.preset = preset
        _volumeIndex = State(initialValue: preset.defaultVolumeIndex)
        _abvIndex = State(initialValue: preset.defaultABVIndex)
    }

    private var abvStepPermille: Int { profiles.first?.abvPrecisionPermille ?? 5 }

    private var displayedAbvValues: [Double] {
        DrinkTypePreset.abvRange(
            from: Int(preset.abvMin * 1000),
            through: Int(preset.abvMax * 1000),
            step: abvStepPermille
        )
    }

    private var safeAbvIndex: Int { min(abvIndex, displayedAbvValues.count - 1) }

    private var selectedVolumeMl: Double { preset.volumes[volumeIndex].volumeMl }
    private var selectedABV: Double {
        let values = displayedAbvValues
        guard !values.isEmpty else { return 0 }
        return values[safeAbvIndex]
    }

    private var alcoholUnit: AlcoholUnit { profiles.first?.alcoholUnit ?? .units }
    private var guideline: GuidelineChoice { profiles.first?.guidelineChoice ?? .who }

    // pureAlcoholGrams = volumeMl × abv × 0.8 — canonical formula, hand-verify before changing.
    private var pureAlcoholGrams: Double { selectedVolumeMl * Double(count) * selectedABV * 0.8 }

    var body: some View {
        Form {
            Section(String(localized: "addDrink.serving")) {
                HStack(spacing: 0) {
                    Picker(String(localized: "addDrink.volume"), selection: $volumeIndex) {
                        ForEach(Array(preset.volumes.enumerated()), id: \.offset) { offset, item in
                            Text(item.label).font(.callout).tag(offset)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .labelsHidden()

                    Picker(String(localized: "addDrink.strength"), selection: $abvIndex) {
                        ForEach(Array(displayedAbvValues.enumerated()), id: \.offset) { offset, value in
                            Text(String(format: "%.1f%%", value * 100)).font(.callout).tag(offset)
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
                    displayedComponents: .date
                )
            }

            Section {
                HStack {
                    TextField(String(localized: "addDrink.pricePlaceholder"), text: $priceText)
                        .keyboardType(.decimalPad)
                    Text("USD")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack {
                    Text(alcoholUnit.displayName)
                    Spacer()
                    Text(alcoholUnit.formattedValue(pureAlcoholGrams, guideline: guideline))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(preset.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "action.cancel")) { dismissSheet?() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "action.save")) { save() }
            }
        }
    }

    private var parsedPrice: Double? {
        let normalized = priceText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private func save() {
        let event = ConsumptionEvent(
            timestamp: date,
            volumeMl: selectedVolumeMl * Double(count),
            abv: selectedABV,
            name: preset.name,
            category: preset.category,
            icon: preset.icon,
            price: parsedPrice
        )
        modelContext.insert(event)
        dismissSheet?()
    }
}

#Preview {
    NavigationStack {
        DrinkDetailInputView(preset: .beer)
    }
    .modelContainer(
        for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self, GuidelineProfile.self],
        inMemory: true
    )
}
