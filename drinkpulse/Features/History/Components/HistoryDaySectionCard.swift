import SwiftUI
import SwiftData

/// A day's worth of History rows rendered as a titled `dpGlassCard`, mirroring
/// `SettingsSection`/`SettingsRow` (plan-0027) and the divider pattern already
/// used unmodified in `HistoryCalendarDayDetail`. Replaces `List`'s
/// `Section(title) { ForEach }` — see plan-0038.
struct HistoryDaySectionCard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.healthService) private var healthService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let events: [ConsumptionEvent]
    let profile: UserProfile?
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
                ForEach(Array(events.enumerated()), id: \.element.uuid) { index, event in
                    VStack(spacing: 0) {
                        Button {
                            onEditEvent(event)
                        } label: {
                            EventRow(event: event, profile: profile)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        // Matches SettingsRow's row padding (plan-0027) — the pattern this
                        // card mirrors. List used to supply this via its own default row
                        // insets; ScrollView+LazyVStack rows need it applied explicitly or
                        // they collapse to font-metrics-only height (plan-0038 regression).
                        .padding(.vertical, 10)
                        .eventContextMenu(for: event, in: modelContext, healthService: healthService, reduceMotion: reduceMotion)
                        if index < events.count - 1 {
                            Divider().padding(.leading, 48)
                        }
                    }
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
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    let beer = ConsumptionEvent.previewBeer
    let wine = ConsumptionEvent.previewWine
    container.mainContext.insert(beer)
    container.mainContext.insert(wine)
    container.mainContext.insert(UserProfile.preview)
    return ScrollView {
        HistoryDaySectionCard(
            title: "TODAY",
            events: [beer, wine],
            profile: .preview,
            onEditEvent: { _ in }
        )
        .padding()
    }
    .modelContainer(container)
}
