import SwiftUI
import SwiftData

struct EditEventView: View {
    let event: ConsumptionEvent

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.healthService) private var healthService
    @Query private var profiles: [UserProfile]

    @State private var showDeleteConfirmation = false

    @State private var category: DrinkCategory
    @State private var icon: String
    @State private var volumeMl: Double
    @State private var originalVolumeMl: Double
    @State private var abvValue: Double
    @State private var abvValues: [Double]
    @State private var count: Int
    @State private var date: Date
    @State private var customNameText: String
    @State private var priceText: String
    @State private var priceCurrency: String
    @State private var notesText: String

    init(event: ConsumptionEvent) {
        self.event = event

        let preset = DrinkTypePreset.preset(for: event.category)

        _category       = State(initialValue: event.category)
        _icon           = State(initialValue: event.icon)
        _volumeMl       = State(initialValue: event.volumeMl)
        _originalVolumeMl = State(initialValue: event.volumeMl)
        _abvValues      = State(initialValue: preset.abvValues)
        _abvValue       = State(initialValue:
            preset.abvValues.min(by: { abs($0 - event.abv) < abs($1 - event.abv) }) ?? event.abv)
        _count          = State(initialValue: max(event.quantity, 1))
        _date           = State(initialValue: event.consumptionDate)
        _customNameText = State(initialValue: event.customName ?? "")
        _priceText      = State(initialValue: event.price.map {
            String(format: "%g", $0)
        } ?? "")
        _priceCurrency  = State(initialValue: event.priceCurrency ?? CurrencyCatalog.defaultCode)
        _notesText      = State(initialValue: event.notes ?? "")
    }

    // MARK: - Derived state

    private var preset: DrinkTypePreset { DrinkTypePreset.preset(for: category) }
    private var abvStepPermille: Int { profiles.first?.abvPrecisionPermille ?? 5 }
    private var alcoholUnit: AlcoholUnit { profiles.first?.alcoholUnit ?? .standardDrinks }
    private var guideline: GuidelineChoice { profiles.first?.guidelineChoice ?? .who }
    private var unitSystem: UnitSystem { profiles.first?.unitSystem ?? .metric }

    private var volumeOptions: [DrinkTypePreset.VolumeOption] {
        var options = preset.category == .custom
            ? DrinkTypePreset.customVolumes(for: unitSystem)
            : preset.volumes(for: unitSystem)
        if options.isEmpty { options = preset.volumes }
        if !options.contains(where: { $0.volumeMl == originalVolumeMl }) {
            options.insert(
                .init(descriptor: String(localized: "editDrink.currentServing"),
                      volumeMl: originalVolumeMl, regions: [unitSystem]),
                at: 0
            )
        }
        return options
    }

    private var selectedVolumeMl: Double { volumeMl }

    private var selectedABV: Double { abvValue }

    private func syncAbvValues() {
        let values = DrinkTypePreset.abvRange(
            from: Int((preset.abvMin * 1000).rounded()),
            through: Int((preset.abvMax * 1000).rounded()),
            step: abvStepPermille
        )
        guard values != abvValues else { return }
        abvValues = values
        if let nearest = values.min(by: { abs($0 - event.abv) < abs($1 - event.abv) }) {
            abvValue = nearest
        }
    }

    private var previewMassGrams: Double {
        selectedVolumeMl * Double(count) * selectedABV * alcoholUnit.density(for: guideline)
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
                }

                CustomNameSuggestionSection(customName: $customNameText)

                Section(String(localized: "addDrink.serving")) {
                    EditServingPickers(
                        volumeMl: $volumeMl,
                        abvValue: $abvValue,
                        count: $count,
                        volumeOptions: volumeOptions,
                        abvValues: abvValues,
                        unitSystem: unitSystem
                    )
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
                    .popover(isPresented: $showDeleteConfirmation) {
                        DeleteConfirmationPopover {
                            showDeleteConfirmation = false
                            deleteEvent()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.save")) { save() }
                }
            }
            .onAppear {
                syncAbvValues()
                if event.priceCurrency == nil {
                    priceCurrency = profiles.first?.currency ?? CurrencyCatalog.defaultCode
                }
            }
            .onChange(of: category) { _, newCategory in
                let newPreset = DrinkTypePreset.preset(for: newCategory)
                let newDefault = newPreset.defaultVolumeMl(for: unitSystem)
                volumeMl         = newDefault
                originalVolumeMl = newDefault
                abvValue         = newPreset.abvValues[newPreset.defaultABVIndex]
                icon             = newPreset.icon
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Actions

    static func volumeToPersist(selected: Double, original: Double) -> Double {
        selected != original ? selected : original
    }

    private func save() {
        event.category  = category
        event.icon      = icon
        event.volumeMl  = Self.volumeToPersist(selected: selectedVolumeMl, original: originalVolumeMl)
        event.quantity  = count
        event.abv       = selectedABV
        event.consumptionDate = date
        event.price     = parsedPrice
        event.priceCurrency = parsedPrice == nil ? nil : priceCurrency
        let trimmedCustomName = customNameText.trimmingCharacters(in: .whitespacesAndNewlines)
        event.customName = trimmedCustomName.isEmpty ? nil : trimmedCustomName
        let trimmedNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        event.notes     = trimmedNotes.isEmpty ? nil : trimmedNotes
        event.touch()
        HealthWriteHooks.update(event, in: modelContext, using: healthService)
        dismiss()
    }

    private func deleteEvent() {
        HealthWriteHooks.remove(event, using: healthService)
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
    container.mainContext.insert(
        ConsumptionEvent(volumeMl: 330, abv: 0.06, category: .beer, icon: "🍺", customName: "Craft IPA")
    )
    return EditEventView(event: ConsumptionEvent.previewBeer)
        .modelContainer(container)
}
