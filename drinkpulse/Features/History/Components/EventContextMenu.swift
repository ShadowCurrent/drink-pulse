import SwiftUI
import SwiftData

extension View {
    /// Long-press context menu for a consumption event: Duplicate (instant re-log,
    /// copies all fields with `timestamp = .now`) and Delete. Mutations go straight
    /// through the injected `ModelContext`, matching the no-repository architecture.
    func eventContextMenu(for event: ConsumptionEvent, in context: ModelContext) -> some View {
        contextMenu {
            Button {
                context.insert(event.duplicated())
            } label: {
                Label(String(localized: "action.duplicate"), systemImage: "plus.square.on.square")
            }

            Button(role: .destructive) {
                context.delete(event)
            } label: {
                Label(String(localized: "action.delete"), systemImage: "trash")
            }
        }
    }
}
