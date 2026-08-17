import SwiftUI
import SwiftData

/// One event's List row content in History's flat, one-row-per-event
/// architecture: `EventRowButton` (tap target + context menu, shared with
/// `HistoryCalendarDayDetail`) wrapped in its OWN plain row background,
/// corner-rounded per `HistoryRowGroupPosition` so several adjacent rows in
/// the same day still read as one seamless card. This per-row background
/// (replacing the retired `HistoryDaySectionCard`'s single background
/// shared by every event in a day) is what removes the shared-List-row
/// condition responsible for both the transient whole-day highlight flash
/// and the wrong-row Duplicate/Delete targeting bug — see
/// `.planning/debug/contextmenu-zoom-glitch.md`.
///
/// Plain system-material fill, not Liquid Glass: HIG reserves glass for the
/// navigation layer that floats above content, not scrollable list rows
/// (Apple DTS/community guidance, confirmed 2026-08-09) — a glass surface
/// repeated on every row is the "overuses Liquid Glass" anti-pattern.
///
/// Horizontal padding (16pt, content-to-card-edge) plus this List row's own
/// 16pt row inset (card-edge-to-screen-edge, set in `HistoryListQueryView`)
/// reproduces the exact ~338pt content width already confirmed clean
/// against the OS's default `.contextMenu` lift/preview (Evidence
/// 2026-08-03T18:00:00Z) — deliberately unchanged from the retired
/// shared-day-card's geometry, not a new value.
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
    /// `DPGlassSize.card`'s own 24pt radius (matching the retired shared
    /// day-card's look) applied only to the corners at the OUTER edge of
    /// this day's contiguous run of rows.
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
