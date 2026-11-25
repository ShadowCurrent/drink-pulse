import SwiftUI
import SwiftData

/// One drink in the History list, search results and calendar day. Tapping pushes Edit Drink
/// on History's stack (plan 0047, D0047-8).
struct HistoryEventRow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.healthService) private var healthService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.drinkLogged) private var drinkLogged

    let event: ConsumptionEvent
    let unitContext: RowUnitContext

    var body: some View {
        NavigationLink(value: EditEventRoute(uuid: event.uuid)) {
            EventRow(event: event, unitContext: unitContext)
        }
        .accessibilityHint(String(localized: "history.row.editHint"))
        .historyRowActions(for: event, in: modelContext,
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
    return NavigationStack { List {
        Section {
            HistoryEventRow(event: beer, unitContext: RowUnitContext(nil))
            HistoryEventRow(event: wine, unitContext: RowUnitContext(nil))
        }
    }
    .listStyle(.insetGrouped) }
    .modelContainer(container)
}
