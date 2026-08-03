import SwiftUI
import SwiftData

/// The single definition of a History event row: tap target, context menu and
/// trailing separator around one `EventRow`.
///
/// This hierarchy was previously written out verbatim in both
/// `HistoryDaySectionCard` and `HistoryCalendarDayDetail`, and had already
/// diverged — only the list copy carried the 10pt vertical padding that was the
/// recorded fix for BUG 1 in `.planning/debug/resolved/history-scrollview-bugs.md`,
/// so calendar day-detail rows were still in the pre-fix collapsed state. One
/// definition means a row fix cannot land on one screen and miss the other.
/// Finding A7-1.
struct EventRowButton: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.healthService) private var healthService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Tracks the scaled icon column in `EventRow` (same 36pt base plus the 12pt
    /// leading gap) so the separator stays aligned with the text instead of
    /// drifting away from it at large Dynamic Type sizes. Second half of C14-3.
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
                    // Order is the whole C14-1 fix. This padding used to be applied
                    // to the Button, OUTSIDE a contentShape that had already pinned
                    // the interactive shape to the unpadded EventRow frame — so 20pt
                    // of every row's height was visible but inert, and tapping the
                    // top or bottom band of a row did nothing. Padding the label
                    // first makes the padded band part of the hit-tested shape.
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
