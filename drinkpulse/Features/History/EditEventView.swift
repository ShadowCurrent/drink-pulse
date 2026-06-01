import SwiftUI
import SwiftData

struct EditEventView: View {
    let event: ConsumptionEvent

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var showDeleteConfirmation = false

    @State private var category: DrinkCategory
    @State private var name: String
    @State private var icon: String
    @State private var volumeIndex: Int
    @State private var abvIndex: Int
    @State private var count: Int
    @State private var date: Date
    @State private var priceText: String
    @State private var customName: String
    @State private var notesText: String

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
        _customName = State(initialValue: event.customName ?? "")
        _notesText  = State(initialValue: event.notes ?? "")
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

    private var safeVolumeIndex: Int { min(volumeIndex, max(preset.volumes.count - 1, 0)) }
    private var safeAbvIndex: Int { min(abvIndex, max(displayedAbvValues.count - 1, 0)) }
    private var selectedVolumeMl: Double { preset.volumes[safeVolumeIndex].volumeMl }
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
                    NavigationLink {
                        EditDrinkTypeSelectionView(current: category) { preset in
                            category = preset.category
                        }
                    } label: {
                        LabeledContent(String(localized: "editDrink.type")) {
                            Text("\(preset.icon) \(preset.name)")
                        }
                    }

                    LabeledContent(String(localized: "editDrink.name")) {
                        TextField(String(localized: "editDrink.name"), text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(String(localized: "addDrink.serving")) {
                    HStack(spacing: 0) {
                        Picker(String(localized: "addDrink.volume"),
                               selection: Binding(get: { safeVolumeIndex }, set: { volumeIndex = $0 })) {
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

                EditCustomNameSection(
                    customName: $customName,
                    categoryDefaultName: preset.name
                )

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
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)
                    .accessibilityLabel(String(localized: "action.delete"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.save")) { save() }
                }
            }
            .confirmationDialog(
                String(localized: "editDrink.deleteConfirm.title"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "action.delete"), role: .destructive) { deleteEvent() }
                Button(String(localized: "action.cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "editDrink.deleteConfirm.message"))
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
        event.category   = category
        event.name       = name
        event.icon       = icon
        event.volumeMl   = selectedVolumeMl * Double(count)
        event.abv        = selectedABV
        event.timestamp  = date
        event.price      = parsedPrice
        let trimmedName  = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        event.customName = trimmedName.isEmpty ? nil : trimmedName
        let trimmedNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        event.notes      = trimmedNotes.isEmpty ? nil : trimmedNotes
        dismiss()
    }

    private func deleteEvent() {
        modelContext.delete(event)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(UserProfile.preview)
    return EditEventView(event: ConsumptionEvent.previewBeer)
        .modelContainer(container)
}
