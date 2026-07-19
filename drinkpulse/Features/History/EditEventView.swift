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
    /// The event's exact stored volume at open time. Used to (a) inject it as a
    /// pre-selected, never-snapped picker option and (b) guard save() so an
    /// untouched edit never rewrites the canonical volume (plan-0030, the load-
    /// bearing data-integrity fix). Reset whenever the category changes.
    @State private var originalVolumeMl: Double
    @State private var abvValue: Double
    // Cached so the (up to 996-row) ABV wheel is built once, not rebuilt every body
    // pass, and so we never linear-scan it on every binding read while scrolling.
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
        // Selection is ml-based and starts at the EXACT stored volume — never snapped
        // to a grid row. The stored volume is injected into the picker options below.
        _volumeMl       = State(initialValue: event.volumeMl)
        _originalVolumeMl = State(initialValue: event.volumeMl)
        // Snap the saved ABV to an exact wheel member (default 0.5 % grid) up front so
        // the wheel matches on first render; refined for finer precision in onAppear.
        _abvValues      = State(initialValue: preset.abvValues)
        _abvValue       = State(initialValue:
            preset.abvValues.min(by: { abs($0 - event.abv) < abs($1 - event.abv) }) ?? event.abv)
        _count          = State(initialValue: max(event.quantity, 1))
        _date           = State(initialValue: event.consumptionDate)
        _customNameText = State(initialValue: event.customName ?? "")
        _priceText      = State(initialValue: event.price.map {
            String(format: "%g", $0)
        } ?? "")
        // Seed from the event's own currency; nil (legacy/no price) falls back to
        // the profile currency in onAppear.
        _priceCurrency  = State(initialValue: event.priceCurrency ?? CurrencyCatalog.defaultCode)
        _notesText      = State(initialValue: event.notes ?? "")
    }

    // MARK: - Derived state

    private var preset: DrinkTypePreset { DrinkTypePreset.preset(for: category) }
    private var abvStepPermille: Int { profiles.first?.abvPrecisionPermille ?? 5 }
    private var alcoholUnit: AlcoholUnit { profiles.first?.alcoholUnit ?? .standardDrinks }
    private var guideline: GuidelineChoice { profiles.first?.guidelineChoice ?? .who }
    private var unitSystem: UnitSystem { profiles.first?.unitSystem ?? .metric }

    /// Region-native options for the active unit system, PLUS the event's exact
    /// stored volume injected as a pre-selected option (shown converted, never
    /// snapped) when it is not already a native row. Guarantees the picker can
    /// represent the stored volume exactly.
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

    // Rebuild the cached ABV list for the user's precision and snap to the saved value
    // (the original event.abv, so finer precision recovers e.g. 2.9 % exactly). Runs
    // once on appear — precision can't change while this sheet is open.
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

    // Live preview mass in the user's display unit (density depends on the chosen mode
    // and guideline — see AlcoholUnit.density(for:)). Hand-verify before changing.
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
                // Category change is a deliberate edit: adopt the new category's
                // default serving (resolved to the active unit) and drop the
                // injected original-volume option for the old category.
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

    /// Data-integrity guard (plan-0030). Returns the volume to persist: the
    /// `selected` value only when the user actually changed it, otherwise the
    /// `original` byte-for-byte. This prevents a unit-dependent grid from silently
    /// re-snapping an untouched volume (e.g. 500 → 473 ml). Pure + static so it can
    /// be regression-tested without a view.
    static func volumeToPersist(selected: Double, original: Double) -> Double {
        selected != original ? selected : original
    }

    private func save() {
        event.category  = category
        event.icon      = icon
        // See volumeToPersist: an untouched edit keeps volumeMl exactly, even when
        // opened under a different unit system.
        event.volumeMl  = Self.volumeToPersist(selected: selectedVolumeMl, original: originalVolumeMl)
        event.quantity  = count
        event.abv       = selectedABV
        event.consumptionDate = date
        event.price     = parsedPrice
        // Currency is meaningful only with an amount; drop it when price clears.
        event.priceCurrency = parsedPrice == nil ? nil : priceCurrency
        let trimmedCustomName = customNameText.trimmingCharacters(in: .whitespacesAndNewlines)
        event.customName = trimmedCustomName.isEmpty ? nil : trimmedCustomName
        let trimmedNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        event.notes     = trimmedNotes.isEmpty ? nil : trimmedNotes
        // `enteredUnit` is permanent provenance (plan-0031 / ADR-0007): never
        // rewritten on edit, even when the volume itself changes.
        event.touch()
        // Rewrite the Health sample for the edited event (fire-and-forget, gated).
        HealthWriteHooks.update(event, in: modelContext, using: healthService)
        dismiss()
    }

    private func deleteEvent() {
        // Capture ids + enqueue the Health delete BEFORE invalidating the @Model.
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
