import SwiftUI
import SwiftData

struct HistoryEventCardRow: View {
    let event: ConsumptionEvent
    let position: HistoryRowGroupPosition
    let unitContext: RowUnitContext
    let onEdit: (ConsumptionEvent) -> Void

    var body: some View {
        EventRowButton(
            event: event,
            unitContext: unitContext,
            isLast: position.isLastInDay,
            onEdit: onEdit
        )
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(cornerRadii: position.cardCornerRadii, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private extension HistoryRowGroupPosition {
    var cardCornerRadii: RectangleCornerRadii {
        let r = DPGlassSize.card.cornerRadius
        return switch self {
        case .only:
            RectangleCornerRadii(topLeading: r, bottomLeading: r, bottomTrailing: r, topTrailing: r)
        case .first:
            RectangleCornerRadii(topLeading: r, bottomLeading: 0, bottomTrailing: 0, topTrailing: r)
        case .middle:
            RectangleCornerRadii(topLeading: 0, bottomLeading: 0, bottomTrailing: 0, topTrailing: 0)
        case .last:
            RectangleCornerRadii(topLeading: 0, bottomLeading: r, bottomTrailing: r, topTrailing: 0)
        }
    }
}

#Preview("Day run: first / middle / last") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self,
        configurations: config
    )
    let beer = ConsumptionEvent.previewBeer
    let wine = ConsumptionEvent.previewWine
    let spirits = ConsumptionEvent.previewSpirits
    container.mainContext.insert(beer)
    container.mainContext.insert(wine)
    container.mainContext.insert(spirits)
    let unitContext = RowUnitContext(alcoholUnit: .standardDrinks, guideline: .who, unitSystem: .metric)
    return ScrollView {
        VStack(spacing: 0) {
            HistoryEventCardRow(event: beer, position: .first, unitContext: unitContext, onEdit: { _ in })
            HistoryEventCardRow(event: wine, position: .middle, unitContext: unitContext, onEdit: { _ in })
            HistoryEventCardRow(event: spirits, position: .last, unitContext: unitContext, onEdit: { _ in })
        }
        .padding()
    }
    .modelContainer(container)
}

#Preview("Single-event day") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self,
        configurations: config
    )
    let beer = ConsumptionEvent.previewBeer
    container.mainContext.insert(beer)
    let unitContext = RowUnitContext(alcoholUnit: .standardDrinks, guideline: .who, unitSystem: .metric)
    return ScrollView {
        HistoryEventCardRow(event: beer, position: .only, unitContext: unitContext, onEdit: { _ in })
            .padding()
    }
    .modelContainer(container)
}
