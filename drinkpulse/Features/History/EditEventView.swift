import SwiftUI
import SwiftData

struct EditEventView: View {
    let event: ConsumptionEvent

    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var category: DrinkCategory
    @State private var name: String
    @State private var icon: String
    @State private var volumeIndex: Int
    @State private var abvIndex: Int
    @State private var count: Int
    @State private var date: Date
    @State private var priceText: String

    init(event: ConsumptionEvent) {
        self.event = event

        let preset = DrinkTypePreset.preset(for: event.category)

        // Find the (count, volumeIndex) pair whose product is closest to event.volumeMl.
        var bestCount = 1
        var bestVolumeIndex = preset.defaultVolumeIndex
        var bestDiff = Double.infinity
        for c in 1 ... 10 {
            for (idx, vol) in preset.volumes.enumerated() {
                let diff = abs(vol.volumeMl * Double(c) - event.volumeMl)
                if diff < bestDiff {
                    bestDiff = diff
                    bestCount = c
                    bestVolumeIndex = idx
                }
            }
        }

        // Nearest ABV index using 0.5 % steps (default precision).
        // safeAbvIndex will clamp if the user's precision setting differs.
        let abvValues = DrinkTypePreset.abvRange(
            from: Int(preset.abvMin * 1000),
            through: Int(preset.abvMax * 1000),
            step: 5
        )
        let nearestAbv = abvValues.indices.min(by: {
            abs(abvValues[$0] - event.abv) < abs(abvValues[$1] - event.abv)
        }) ?? preset.defaultABVIndex

        _category   = State(initialValue: event.category)
        _name       = State(initialValue: event.name)
        _icon       = State(initialValue: event.icon)
        _volumeIndex = State(initialValue: bestVolumeIndex)
        _abvIndex   = State(initialValue: nearestAbv)
        _count      = State(initialValue: bestCount)
        _date       = State(initialValue: event.timestamp)
        _priceText  = State(initialValue: event.price.map {
            String(format: "%g", $0)
        } ?? "")
    }

    // MARK: - Derived state

    private var preset: DrinkTypePreset { DrinkTypePreset.preset(for: category) }
    private var abvStepPermille: Int { profiles.first?.abvPrecisionPermille ?? 5 }
    private var alcoholUnit: AlcoholUnit { profiles.first?.alcoholUnit ?? .units }
    private var guideline: GuidelineChoice { profiles.first?.guidelineChoice ?? .who }

    private var displayedAbvValues: [Double] {
        DrinkTypePreset.abvRange(
            from: Int(preset.abvMin * 1000),
            through: Int(preset.abvMax * 1000),
            step: abvStepPermille
        )
    }

    private var safeAbvIndex: Int { min(abvIndex, max(displayedAbvValues.count - 1, 0)) }
    private var selectedVolumeMl: Double { preset.volumes[volumeIndex].volumeMl }
    private var selectedABV: Double {
        displayedAbvValues.isEmpty ? 0 : displayedAbvValues[safeAbvIndex]
    }

    private var pureAlcoholGrams: Double {
        selectedVolumeMl * Double(count) * selectedABV * 0.8
    }

    private var parsedPrice: Double? {
        let normalized = priceText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "editDrink.category")) {
                    Picker(String(localized: "editDrink.category"), selection: $category) {
                        ForEach(DrinkCategory.allCases, id: \.self) { cat in
                            Text(DrinkTypePreset.preset(for: cat).icon + " " +
                                 DrinkTypePreset.preset(for: cat).name)
                                .tag(cat)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.inline)

                    LabeledContent(String(localized: "editDrink.name")) {
                        TextField(String(localized: "editDrink.name"), text: $name)
                            .multilineTextAlignment(.trailing)
                    }
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

                        Picker(String(localized: "addDrink.strength"), selection: $abvIndex) {
                            ForEach(Array(displayedAbvValues.enumerated()), id: \.offset) { offset, value in
                                Text(String(format: "%.1f%%", value * 100)).font(.callout).tag(offset)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 88)
                        .labelsHidden()

                        Picker(String(localized: "addDrink.amount"), selection: $count) {
                            ForEach(1 ... 10, id: \.self) { n in
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
            .navigationTitle(String(localized: "editDrink.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.save")) { save() }
                }
            }
            .onChange(of: category) { _, newCategory in
                let newPreset = DrinkTypePreset.preset(for: newCategory)
                volumeIndex = newPreset.defaultVolumeIndex
                abvIndex    = newPreset.defaultABVIndex
                icon        = newPreset.icon
                name        = newPreset.name
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Actions

    private func save() {
        event.category  = category
        event.name      = name
        event.icon      = icon
        event.volumeMl  = selectedVolumeMl * Double(count)
        event.abv       = selectedABV
        event.timestamp = date
        event.price     = parsedPrice
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self, GuidelineProfile.self,
        configurations: config
    )
    container.mainContext.insert(UserProfile.preview)
    return EditEventView(event: ConsumptionEvent.previewBeer)
        .modelContainer(container)
}
