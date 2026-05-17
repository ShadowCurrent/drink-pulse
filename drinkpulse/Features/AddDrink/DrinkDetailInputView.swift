import SwiftUI
import SwiftData

struct DrinkDetailInputView: View {
    let preset: DrinkTypePreset

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissSheet) private var dismissSheet

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

    private var selectedVolumeMl: Double { preset.volumes[volumeIndex].volumeMl }
    private var selectedABV: Double { preset.abvValues[abvIndex] }

    // units = ml × abv_fraction / 10  (≡ ml × abv% / 1000 — standard UK formula)
    // Hand-verify before changing.
    private var alcoholUnits: Double { selectedVolumeMl * Double(count) * selectedABV / 10 }

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
                        ForEach(Array(preset.abvValues.enumerated()), id: \.offset) { offset, value in
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
                    Text(String(localized: "addDrink.alcoholUnits"))
                    Spacer()
                    Text(String(format: "%.1f", alcoholUnits))
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
