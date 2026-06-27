import SwiftUI
import SwiftData

struct HistoryCalendarDayDetail: View {
    @Environment(\.modelContext) private var modelContext

    let day: Date
    let events: [ConsumptionEvent]
    let profile: UserProfile?
    let onEditEvent: (ConsumptionEvent) -> Void

    private var alcoholUnit: AlcoholUnit { profile?.alcoholUnit ?? .standardDrinks }
    private var guideline: GuidelineChoice { profile?.guidelineChoice ?? .who }

    private var totalGrams: Double {
        let density = alcoholUnit.density(for: guideline)
        return events.reduce(0) { $0 + $1.alcoholGrams(density: density) }
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
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                VStack(spacing: 0) {
                    Button { onEditEvent(event) } label: {
                        EventRow(event: event, profile: profile)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .eventContextMenu(for: event, in: modelContext)
                    if index < events.count - 1 {
                        Divider().padding(.leading, 48)
                    }
                }
            }
        }
    }
}

#Preview("With events") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    let beer = ConsumptionEvent.previewBeer
    let wine = ConsumptionEvent.previewWine
    container.mainContext.insert(beer)
    container.mainContext.insert(wine)
    container.mainContext.insert(UserProfile.preview)
    return HistoryCalendarDayDetail(
        day: .now,
        events: [beer, wine],
        profile: .preview,
        onEditEvent: { _ in }
    )
    .modelContainer(container)
}

#Preview("Empty day") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    return HistoryCalendarDayDetail(
        day: .now,
        events: [],
        profile: .preview,
        onEditEvent: { _ in }
    )
    .modelContainer(container)
}
