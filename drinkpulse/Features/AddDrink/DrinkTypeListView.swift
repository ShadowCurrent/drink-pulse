import SwiftUI
import SwiftData

/// Add Drink step 1 (plan 0047): Recent drinks, then the types in family sections, with search.
struct DrinkTypeListView: View {
    let dismissSheet: DismissAction

    /// The 50 newest events are enough to find three distinct recent drinks (D0047-4).
    static var recentDescriptor: FetchDescriptor<ConsumptionEvent> {
        var descriptor = FetchDescriptor<ConsumptionEvent>(
            sortBy: [SortDescriptor(\.consumptionDate, order: .reverse)]
        )
        descriptor.fetchLimit = 50
        return descriptor
    }

    @Query(DrinkTypeListView.recentDescriptor) private var recentEvents: [ConsumptionEvent]
    @Query private var profiles: [UserProfile]
    @State var search = ""

    private var unitSystem: UnitSystem { profiles.first?.unitSystem ?? .metric }
    private var isSearching: Bool { !search.trimmingCharacters(in: .whitespaces).isEmpty }
    private var recent: [RecentDrink] { isSearching ? [] : RecentDrinks.make(from: recentEvents) }
    private var hasNoMatch: Bool {
        isSearching && DrinkTypeGroup.allCases.allSatisfy { $0.presets(matching: search).isEmpty }
    }

    var body: some View {
        List {
            Group {
                if !recent.isEmpty {
                    Section {
                        ForEach(recent) { drink in
                            NavigationLink(value: AddDrinkRoute.recent(drink)) {
                                RecentDrinkRow(drink: drink, unitSystem: unitSystem)
                            }
                            .accessibilityIdentifier("addDrink.recentRow")
                        }
                    } header: {
                        Text(String(localized: "addDrink.recent"))
                            .foregroundStyle(Color.dpSecondaryText)
                            .accessibilityIdentifier("addDrink.section.recent")
                    }
                }
                DrinkTypeSections(query: search) { preset in
                    NavigationLink(value: AddDrinkRoute.preset(preset.category)) {
                        DrinkTypeLabel(preset: preset)
                    }
                    .accessibilityIdentifier("addDrink.type.\(preset.category.rawValue)")
                }
            }
            .brandRowBackground()
        }
        .overlay {
            if hasNoMatch {
                ContentUnavailableView.search(text: search)
                    .accessibilityIdentifier("addDrink.searchEmpty")
            }
        }
        .brandListBackground()
        .navigationTitle(String(localized: "addDrink.title"))
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $search,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: String(localized: "addDrink.searchPrompt")
        )
        .navigationDestination(for: AddDrinkRoute.self) { route in
            switch route {
            case .preset(let category):
                DrinkDetailInputView(preset: .preset(for: category), dismissSheet: dismissSheet)
            case .recent(let drink):
                DrinkDetailInputView(
                    preset: .preset(for: drink.category),
                    prefill: DrinkPrefill(drink),
                    dismissSheet: dismissSheet
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) { dismissSheet() }
            }
        }
    }
}

private struct ListPreviewHost: View {
    @Environment(\.dismiss) private var dismiss
    var search = ""

    var body: some View {
        NavigationStack { DrinkTypeListView(dismissSheet: dismiss, search: search) }
    }
}

@MainActor private func previewContainer(withHistory: Bool) -> ModelContainer {
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    if withHistory {
        container.mainContext.insert(ConsumptionEvent(
            volumeMl: 660, abv: 0.055, category: .beer, icon: "🍺", customName: "Hazy IPA"))
        container.mainContext.insert(ConsumptionEvent(
            consumptionDate: .now.addingTimeInterval(-3600),
            volumeMl: 175, abv: 0.13, category: .wine, icon: "🍷"))
    }
    return container
}

#Preview("Light") { ListPreviewHost().modelContainer(previewContainer(withHistory: true)) }
#Preview("Dark") {
    ListPreviewHost().modelContainer(previewContainer(withHistory: true)).preferredColorScheme(.dark)
}
#Preview("AX5") {
    ListPreviewHost().modelContainer(previewContainer(withHistory: true))
        .dynamicTypeSize(.accessibility5)
}
#Preview("Search") {
    ListPreviewHost(search: "w").modelContainer(previewContainer(withHistory: true))
}
#Preview("No Recent") { ListPreviewHost().modelContainer(previewContainer(withHistory: false)) }
