import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConsumptionEvent.timestamp, order: .reverse)
    private var events: [ConsumptionEvent]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }
    @State private var editingEvent: ConsumptionEvent?

    private var groupedEvents: [(day: Date, events: [ConsumptionEvent])] {
        let calendar = Calendar.current
        let dict = Dictionary(grouping: events) { calendar.startOfDay(for: $0.timestamp) }
        return dict.sorted { $0.key > $1.key }.map { (day: $0.key, events: $0.value) }
    }

    var body: some View {
        Group {
            if events.isEmpty {
                ContentUnavailableView(
                    String(localized: "history.emptyTitle"),
                    systemImage: "wineglass",
                    description: Text(String(localized: "history.emptyDescription"))
                )
            } else {
                List {
                    ForEach(groupedEvents, id: \.day) { section in
                        Section(sectionTitle(for: section.day)) {
                            ForEach(section.events) { event in
                                EventRow(event: event, profile: profile)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingEvent = event }
                            }
                            .onDelete { offsets in
                                delete(from: section.events, at: offsets)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .sheet(item: $editingEvent) { event in
                    EditEventView(event: event)
                }
            }
        }
        .navigationTitle(String(localized: "tab.history"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return String(localized: "history.today") }
        if calendar.isDateInYesterday(day) { return String(localized: "history.yesterday") }
        return day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
    }

    private func delete(from events: [ConsumptionEvent], at offsets: IndexSet) {
        for offset in offsets {
            modelContext.delete(events[offset])
        }
    }
}

private struct EventRow: View {
    let event: ConsumptionEvent
    let profile: UserProfile?

    private var alcoholUnit: AlcoholUnit { profile?.alcoholUnit ?? .units }
    private var guideline: GuidelineChoice { profile?.guidelineChoice ?? .who }

    var body: some View {
        HStack(spacing: 12) {
            Text(event.icon)
                .font(.title2)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.body)
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(alcoholUnit.formattedValue(event.pureAlcoholGrams, guideline: guideline))
                    .monospacedDigit()
                    .font(.body.weight(.medium))
                Text(alcoholUnit.unitLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var subtitleText: String {
        let vol = String(format: "%.0f ml", event.volumeMl)
        let abv = String(format: "%.1f%%", event.abv * 100)
        let time = event.timestamp.formatted(.dateTime.hour().minute())
        return "\(vol) · \(abv) · \(time)"
    }

    private var accessibilityLabel: String {
        let amount = alcoholUnit.formattedValue(event.pureAlcoholGrams, guideline: guideline)
        return String(format: "%@, %.0f millilitres, %.1f percent ABV, %@ %@, logged at %@",
                      event.name,
                      event.volumeMl,
                      event.abv * 100,
                      amount,
                      alcoholUnit.unitLabel,
                      event.timestamp.formatted(.dateTime.hour().minute()))
    }
}

#Preview("With data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(ConsumptionEvent.previewBeer)
    container.mainContext.insert(ConsumptionEvent.previewWine)
    container.mainContext.insert(ConsumptionEvent.previewSpirits)
    container.mainContext.insert(UserProfile.preview)
    return NavigationStack { HistoryView() }
        .modelContainer(container)
}

#Preview("Empty state") {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(
        for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
        inMemory: true
    )
}
