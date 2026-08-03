import SwiftUI
import SwiftData

struct HistoryCalendarDayDetail: View {
    let day: Date
    let events: [ConsumptionEvent]
    let unitContext: RowUnitContext
    let onEditEvent: (ConsumptionEvent) -> Void

    private var alcoholUnit: AlcoholUnit { unitContext.alcoholUnit }
    private var guideline: GuidelineChoice { unitContext.guideline }

    private var totalGrams: Double {
        events.reduce(0) { $0 + $1.alcoholGrams(density: unitContext.density) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if events.isEmpty {
                emptyState
            } else {
                eventList
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var header: some View {
        HStack {
            Text(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.subheadline.weight(.semibold))
            Spacer()
            if totalGrams > 0 {
                Text("\(alcoholUnit.formattedValue(totalGrams, guideline: guideline)) \(alcoholUnit.unitLabel(for: guideline))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Text("🌙")
                .accessibilityHidden(true)
            Text(String(localized: "history.calendar.soberDayPlaceholder"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private var eventList: some View {
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
    }
}

/// Rows need three display-unit values, not the observable profile model (A6-1),
/// so neither preview builds a profile.
private let previewUnits = RowUnitContext(alcoholUnit: .standardDrinks,
                                          guideline: .who,
                                          unitSystem: .metric)

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
    return HistoryCalendarDayDetail(
        day: .now,
        events: [beer, wine],
        unitContext: previewUnits,
        onEditEvent: { _ in }
    )
    .modelContainer(container)
}

#Preview("Empty day") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self,
        configurations: config
    )
    return HistoryCalendarDayDetail(
        day: .now,
        events: [],
        unitContext: previewUnits,
        onEditEvent: { _ in }
    )
    .modelContainer(container)
}
