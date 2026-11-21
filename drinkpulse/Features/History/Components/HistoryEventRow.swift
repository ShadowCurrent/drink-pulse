import SwiftUI
import SwiftData

/// One drink in the History list, search results and calendar day. Tapping opens the edit
/// sheet (plan 0045, D0045-6: Edit stays a sheet until step 7).
struct HistoryEventRow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.healthService) private var healthService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.drinkLogged) private var drinkLogged

    let event: ConsumptionEvent
    let unitContext: RowUnitContext
    let onEdit: (ConsumptionEvent) -> Void

    var body: some View {
        Button {
            onEdit(event)
        } label: {
            // A Button in a List tints its label with the accent; the row reads as content.
            // `Color.primary`, not `.primary`: the hierarchical style resolves to the tint here
            // (preview, iOS 27.2).
            EventRow(event: event, unitContext: unitContext)
                .foregroundStyle(Color.primary)
        }
        .accessibilityHint(String(localized: "history.row.editHint"))
        .eventContextMenu(for: event, in: modelContext,
                          healthService: healthService, reduceMotion: reduceMotion,
                          drinkLogged: drinkLogged)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let beer = ConsumptionEvent.previewBeer
    let wine = ConsumptionEvent.previewWine
    container.mainContext.insert(beer)
    container.mainContext.insert(wine)
    return List {
        Section {
            HistoryEventRow(event: beer, unitContext: RowUnitContext(nil), onEdit: { _ in })
            HistoryEventRow(event: wine, unitContext: RowUnitContext(nil), onEdit: { _ in })
        }
    }
    .listStyle(.insetGrouped)
    .modelContainer(container)
}
