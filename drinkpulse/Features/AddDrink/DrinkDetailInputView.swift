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
            Section(String(localized: "Serving")) {
                HStack(spacing: 0) {
                    Picker(String(localized: "Volume"), selection: $volumeIndex) {
                        ForEach(preset.volumes.indices, id: \.self) { i in
                            Text(preset.volumes[i].label).tag(i)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .labelsHidden()

                    Picker(String(localized: "Strength"), selection: $abvIndex) {
                        ForEach(preset.abvValues.indices, id: \.self) { i in
                            Text(String(format: "%.1f%%", preset.abvValues[i] * 100)).tag(i)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .labelsHidden()

                    Picker(String(localized: "Amount"), selection: $count) {
                        ForEach(1...10, id: \.self) { n in
                            Text("\(n)×").tag(n)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .labelsHidden()
                }
                .frame(height: 160)
                .listRowInsets(EdgeInsets())
            }

            Section {
                DatePicker(
                    String(localized: "Date"),
                    selection: $date,
                    displayedComponents: .date
                )
            }

            Section {
                HStack {
                    TextField(String(localized: "Price (optional)"), text: $priceText)
                        .keyboardType(.decimalPad)
                    Text("USD")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack {
                    Text(String(localized: "Alcohol units"))
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
                Button(String(localized: "Cancel")) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "Save")) { save() }
            }
        }
    }

    private func save() {
        let event = ConsumptionEvent(
            timestamp: date,
            volumeMl: selectedVolumeMl * Double(count),
            abv: selectedABV,
            name: preset.name,
            category: preset.category,
            icon: preset.icon,
            price: Double(priceText)
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
