import SwiftUI
import SwiftData

/// Resolves a pushed `EditEventRoute` to its event with a live query on the event's `uuid`, so
/// a deleted drink shows a placeholder instead of a stale form.
struct EditEventDestination: View {
    @Query private var events: [ConsumptionEvent]

    init(route: EditEventRoute) {
        let uuid = route.uuid
        var descriptor = FetchDescriptor<ConsumptionEvent>(
            predicate: #Predicate { $0.uuid == uuid }
        )
        descriptor.fetchLimit = 1
        _events = Query(descriptor)
    }

    var body: some View {
        if let event = events.first {
            EditEventView(event: event)
        } else {
            // The drink was deleted while its editor was on the stack.
            ContentUnavailableView(String(localized: "editDrink.deleted"), systemImage: "trash")
        }
    }
}
