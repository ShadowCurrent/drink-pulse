import SwiftUI
import SwiftData

struct EventRowButton: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.healthService) private var healthService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .body) private var dividerInset: Double = 48

    let event: ConsumptionEvent
    let unitContext: RowUnitContext
    let isLast: Bool
    let onEdit: (ConsumptionEvent) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button {
                onEdit(event)
            } label: {
                EventRow(event: event, unitContext: unitContext)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(String(localized: "history.row.editHint"))
            .eventContextMenu(for: event, in: modelContext,
                              healthService: healthService, reduceMotion: reduceMotion)

            if !isLast {
                Divider().padding(.leading, dividerInset)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    let beer = ConsumptionEvent.previewBeer
    let wine = ConsumptionEvent.previewWine
    container.mainContext.insert(beer)
    container.mainContext.insert(wine)
    return VStack(spacing: 0) {
        EventRowButton(event: beer, unitContext: RowUnitContext(nil),
                       isLast: false, onEdit: { _ in })
        EventRowButton(event: wine, unitContext: RowUnitContext(nil),
                       isLast: true, onEdit: { _ in })
    }
    .padding(.horizontal, 16)
    .modelContainer(container)
}
