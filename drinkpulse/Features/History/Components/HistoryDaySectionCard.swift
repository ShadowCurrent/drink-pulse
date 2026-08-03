import SwiftUI
import SwiftData

/// A day's worth of History rows rendered as a titled `dpGlassCard`, mirroring
/// `SettingsSection`/`SettingsRow` (plan-0027) and the divider pattern already
/// used unmodified in `HistoryCalendarDayDetail`. Replaces `List`'s
/// `Section(title) { ForEach }` — see plan-0038.
struct HistoryDaySectionCard: View {
    let title: String
    let events: [ConsumptionEvent]
    let unitContext: RowUnitContext
    let onEditEvent: (ConsumptionEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Identity is the model's own stable `uuid` (plan-0023), NOT the synthesized
                // persistent identifier: a freshly-inserted object's identifier is temporary
                // until the context saves, and SwiftUI reads that flip as remove-plus-insert
                // rather than update (.planning/debug/resolved/sheet-closes-reopens-loses-state.md).
                //
                // Iterating the collection directly rather than pairing it with its indices
                // also drops the eager array copy that ran on every body evaluation, and
                // removes the row index as an identity source entirely (finding A1-3).
                ForEach(events, id: \.uuid) { event in
                    EventRowButton(
                        event: event,
                        unitContext: unitContext,
                        // An equality test on the model's own field, not an identity
                        // keypath — correct regardless of what keys the ForEach.
                        isLast: event.uuid == events.last?.uuid,
                        onEdit: onEditEvent
                    )
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dpGlassCard()
        }
        .transition(.asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale(scale: 0.95))))
    }
}

#Preview("With events") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self,
        configurations: config
    )
    let beer = ConsumptionEvent.previewBeer
    let wine = ConsumptionEvent.previewWine
    container.mainContext.insert(beer)
    container.mainContext.insert(wine)
    // No profile is built: the whole point of RowUnitContext is that a row needs
    // three display-unit values, not the observable profile model (A6-1).
    return ScrollView {
        HistoryDaySectionCard(
            title: "TODAY",
            events: [beer, wine],
            unitContext: RowUnitContext(alcoholUnit: .standardDrinks,
                                        guideline: .who,
                                        unitSystem: .metric),
            onEditEvent: { _ in }
        )
        .padding()
    }
    .modelContainer(container)
}
