import SwiftUI
import SwiftData

struct DrinkDetailInputView: View {
    let preset: DrinkTypePreset

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissSheet) private var dismissSheet

    @Query private var profiles: [UserProfile]

    @State private var volumeIndex: Int
    @State private var abvValue: Double
    @State private var count = 1
    @State private var date = Date.now
    @State private var customNameText = ""
    @State private var priceText = ""
    @State private var notesText = ""

    init(preset: DrinkTypePreset) {
        self.preset = preset
        _volumeIndex = State(initialValue: preset.defaultVolumeIndex)
        _abvValue = State(initialValue: preset.abvValues[preset.defaultABVIndex])
    }

    private var abvStepPermille: Int { profiles.first?.abvPrecisionPermille ?? 5 }

    private var displayedAbvValues: [Double] {
        DrinkTypePreset.abvRange(
            from: Int(preset.abvMin * 1000),
            through: Int(preset.abvMax * 1000),
            step: abvStepPermille
        )
    }

    private var selectedVolumeMl: Double { preset.volumes[volumeIndex].volumeMl }
    private var selectedABV: Double { abvValue }

    private var alcoholUnit: AlcoholUnit { profiles.first?.alcoholUnit ?? .units }
    private var guideline: GuidelineChoice { profiles.first?.guidelineChoice ?? .who }

    // Live preview mass in the user's display unit (density depends on the chosen
    // unit — see AlcoholUnit.densityGramsPerMl). Hand-verify before changing.
    private var previewMassGrams: Double {
        selectedVolumeMl * Double(count) * selectedABV * alcoholUnit.densityGramsPerMl
    }

    var body: some View {
        Form {
            Section(String(localized: "editDrink.customName")) {
                TextField(String(localized: "editDrink.customNamePlaceholder"), text: $customNameText)
                    .autocorrectionDisabled()
                    .accessibilityLabel(String(localized: "editDrink.customName"))
            }

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

                    Picker(String(localized: "addDrink.strength"), selection: $abvValue) {
                        ForEach(displayedAbvValues, id: \.self) { value in
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
                    Text(alcoholUnit.formattedValue(previewMassGrams, guideline: guideline))
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
        let trimmedNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCustomName = customNameText.trimmingCharacters(in: .whitespacesAndNewlines)
        let event = ConsumptionEvent(
            timestamp: date,
            volumeMl: selectedVolumeMl,
            abv: selectedABV,
            quantity: count,
            name: preset.name,
            category: preset.category,
            icon: preset.icon,
            customName: trimmedCustomName.isEmpty ? nil : trimmedCustomName,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
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
        for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
        inMemory: true
    )
}
