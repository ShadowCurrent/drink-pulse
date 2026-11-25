import SwiftUI
import SwiftData

/// Edit Drink, pushed inside History (plan 0047, D0047-8): system Back, one confirm action,
/// Log Again and Delete Drink at the bottom of the form.
struct EditEventView: View {
    let event: ConsumptionEvent

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Environment(\.healthService) var healthService
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.drinkLogged) var drinkLogged
    @Query private var profiles: [UserProfile]

    @State var showDeleteConfirmation = false
    @State private var showTypeList = false

    @State var category: DrinkCategory
    @State var icon: String
    @State var volumeMl: Double
    @State var originalVolumeMl: Double
    @State var abvValue: Double
    @State var abvValues: [Double]
    @State var count: Int
    @State var date: Date
    @State var customNameText: String
    @State var priceText: String
    /// The stored currency, or the one picked on this form; nil falls back to the profile
    /// currency. Derived, so returning from a pushed list never resets a pick (final review,
    /// Important 2).
    @State var chosenCurrency: String?
    @State var notesText: String

    init(event: ConsumptionEvent) {
        self.event = event

        let preset = DrinkTypePreset.preset(for: event.category)

        _category       = State(initialValue: event.category)
        _icon           = State(initialValue: event.icon)
        _volumeMl       = State(initialValue: event.volumeMl)
        _originalVolumeMl = State(initialValue: event.volumeMl)
        _abvValues      = State(initialValue: preset.abvValues)
        _abvValue       = State(initialValue: DrinkServingOptions.nearest(event.abv, in: preset.abvValues))
        _count          = State(initialValue: max(event.quantity, 1))
        _date           = State(initialValue: event.consumptionDate)
        _customNameText = State(initialValue: event.customName ?? "")
        _priceText      = State(initialValue: event.price.map {
            String(format: "%g", $0)
        } ?? "")
        _chosenCurrency = State(initialValue: event.priceCurrency)
        _notesText      = State(initialValue: event.notes ?? "")
    }

    // MARK: - Derived state

    var preset: DrinkTypePreset { DrinkTypePreset.preset(for: category) }
    private var abvStepPermille: Int { profiles.first?.abvPrecisionPermille ?? 5 }
    private var alcoholUnit: AlcoholUnit { profiles.first?.alcoholUnit ?? .standardDrinks }
    private var guideline: GuidelineChoice { profiles.first?.guidelineChoice ?? .who }
    var unitSystem: UnitSystem { profiles.first?.unitSystem ?? .metric }

    var priceCurrency: String {
        chosenCurrency ?? profiles.first?.currency ?? CurrencyCatalog.defaultCode
    }

    private var currencyBinding: Binding<String> {
        Binding(get: { priceCurrency }, set: { chosenCurrency = $0 })
    }

    private var volumeOptions: [DrinkTypePreset.VolumeOption] {
        DrinkServingOptions.volumeOptions(for: preset, in: unitSystem, keeping: originalVolumeMl)
    }

    private func syncAbvValues() {
        let values = DrinkServingOptions.abvValues(for: preset, stepPermille: abvStepPermille)
        guard values != abvValues else { return }
        abvValues = values
        abvValue = DrinkServingOptions.nearest(event.abv, in: values)
    }

    private var previewMassGrams: Double {
        DrinkMassCalculator.massGrams(
            volumeMl: volumeMl, count: count, abv: abvValue,
            density: alcoholUnit.density(for: guideline)
        )
    }

    // MARK: - Body

    var body: some View {
        Form {
            Group {
                Section {
                    Button {
                        showTypeList = true
                    } label: {
                        LabeledContent(String(localized: "editDrink.type")) {
                            HStack {
                                Text("\(preset.icon) \(preset.name)")
                                Image(systemName: "chevron.forward")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .foregroundStyle(Color.primary)
                    }
                    .accessibilityIdentifier("editDrink.typeRow")
                } header: {
                    Text(String(localized: "editDrink.category")).foregroundStyle(Color.dpSecondaryText)
                }

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

                EditEventActionSections(
                    onLogAgain: logAgain,
                    onDelete: { showDeleteConfirmation = true }
                )
            }
            .brandRowBackground()
        }
        .brandListBackground()
        // Bound presentation, closed through the binding: a link whose destination called
        // `dismiss()` popped all the way back to History on iOS 27.2 (UI test).
        .navigationDestination(isPresented: $showTypeList) {
            DrinkTypeSelectionView(current: category) { tapped in
                if let newCategory = tapped { category = newCategory }
                showTypeList = false
            }
        }
        .navigationTitle(String(localized: "editDrink.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) { save() }
                    .accessibilityIdentifier("drinkForm.confirm")
            }
        }
        .confirmationDialog(
            String(localized: "editDrink.deleteConfirm.title"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "editDrink.delete"), role: .destructive) { deleteEvent() }
                .accessibilityIdentifier("confirmDeleteButton")
        } message: {
            Text(String(localized: "editDrink.deleteConfirm.message"))
        }
        .onAppear { syncAbvValues() }
        .onChange(of: category) { _, newCategory in
            let newPreset = DrinkTypePreset.preset(for: newCategory)
            let newDefault = newPreset.defaultVolumeMl(for: unitSystem)
            volumeMl         = newDefault
            originalVolumeMl = newDefault
            // The new type's grid and default strength, so a return from the type list does
            // not snap back to the old event's ABV (final review, Important 3).
            abvValues        = DrinkServingOptions.abvValues(for: newPreset, stepPermille: abvStepPermille)
            abvValue         = DrinkServingOptions.strength(
                newPreset.abvValues[newPreset.defaultABVIndex], for: newPreset, stepPermille: abvStepPermille)
            icon             = newPreset.icon
        }
    }
}

/// Log Again (with its footer) and Delete Drink at the bottom of Edit Drink. Context-menu
/// actions also live in the main interface (HIG Context menus).
private struct EditEventActionSections: View {
    let onLogAgain: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Section {
            Button(String(localized: "action.duplicate"), action: onLogAgain)
                .accessibilityIdentifier("editDrink.logAgain")
        } footer: {
            Text(String(localized: "editDrink.logAgain.footer")).foregroundStyle(Color.dpSecondaryText)
        }

        Section {
            Button(String(localized: "editDrink.delete"), role: .destructive, action: onDelete)
                .accessibilityIdentifier("editDrink.delete")
        }
    }
}

#Preview("Light") {
    EditPreviewHost()
}

#Preview("Dark") {
    EditPreviewHost().preferredColorScheme(.dark)
}

#Preview("AX5") {
    EditPreviewHost().dynamicTypeSize(.accessibility5)
}

private struct EditPreviewHost: View {
    let container: ModelContainer
    let event: ConsumptionEvent

    init() {
        container = try! ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        container.mainContext.insert(UserProfile.preview)
        event = ConsumptionEvent(volumeMl: 330, abv: 0.06, category: .beer, icon: "🍺", customName: "Craft IPA")
        container.mainContext.insert(event)
    }

    var body: some View {
        NavigationStack { EditEventView(event: event) }
            .modelContainer(container)
    }
}
