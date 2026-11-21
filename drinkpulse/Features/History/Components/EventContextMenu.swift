import SwiftUI
import SwiftData
import OSLog

private struct EventContextMenuModifier: ViewModifier {
    let event: ConsumptionEvent
    let context: ModelContext
    let healthService: HealthService?
    let reduceMotion: Bool
    let drinkLogged: DrinkLoggedAction

    @State private var isPresentingDeleteConfirmation = false

    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "EventContextMenu")

    func body(content: Content) -> some View {
        content
            .contextMenu {
                #if DEBUG
                let _ = Logger(subsystem: "com.drinkpulse.app", category: "performance").notice("History row long-press: contextMenu content build start")
                #endif
                Button {
                    performDuplicate()
                } label: {
                    Label(String(localized: "action.duplicate"), systemImage: "plus.square.on.square")
                }

                Button(role: .destructive) {
                    isPresentingDeleteConfirmation = true
                } label: {
                    Label(String(localized: "action.delete"), systemImage: "trash")
                }
            }
            .accessibilityActions {
                Button(String(localized: "action.duplicate")) {
                    performDuplicate()
                }
                Button(String(localized: "action.delete")) {
                    isPresentingDeleteConfirmation = true
                }
            }
            .confirmationDialog(
                String(localized: "history.row.deleteConfirm.title"),
                isPresented: $isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "action.delete"), role: .destructive) {
                    performDelete()
                }
                .accessibilityIdentifier("confirmContextDeleteButton")

                Button(String(localized: "action.cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "history.row.deleteConfirm.message"))
            }
    }

    private func performDuplicate() {
        let copy = event.duplicated()
        withMotion(reduceMotion: reduceMotion) {
            context.insert(copy)
            RecordDeduplicator.ensureUniqueIdentity(copy, in: context)
            do {
                try context.save()
            } catch {
                logger.error("Duplicate context save failed: \(error.localizedDescription)")
            }
        }
        drinkLogged(copy)
    }

    private func performDelete() {
        withMotion(reduceMotion: reduceMotion) {
            HealthWriteHooks.remove(event, using: healthService)
            context.delete(event)
            do {
                try context.save()
            } catch {
                logger.error("Delete context save failed: \(error.localizedDescription)")
            }
        }
    }
}

extension View {
    func eventContextMenu(
        for event: ConsumptionEvent,
        in context: ModelContext,
        healthService: HealthService?,
        reduceMotion: Bool,
        drinkLogged: DrinkLoggedAction
    ) -> some View {
        modifier(
            EventContextMenuModifier(
                event: event,
                context: context,
                healthService: healthService,
                reduceMotion: reduceMotion,
                drinkLogged: drinkLogged
            )
        )
    }
}
