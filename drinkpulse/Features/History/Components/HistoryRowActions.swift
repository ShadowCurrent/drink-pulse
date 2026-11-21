import SwiftUI
import SwiftData
import OSLog

/// Row actions of a History event (plan 0045, D0045-4 / D0045-5; prototype round 6):
/// - leading swipe Log Again, no full swipe (an accidental full swipe would log a drink);
/// - trailing swipe Delete, full swipe, no confirmation (Mail / Notes pattern);
/// - context menu Log Again, then Delete in its own section, confirmed (HIG Context menus);
/// - the same two actions for VoiceOver.
private struct HistoryRowActionsModifier: ViewModifier {
    let event: ConsumptionEvent
    let context: ModelContext
    let healthService: HealthService?
    let reduceMotion: Bool
    let drinkLogged: DrinkLoggedAction

    @State private var isPresentingDeleteConfirmation = false

    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "HistoryRowActions")

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button(String(localized: "action.duplicate"), systemImage: "repeat") {
                    logAgain()
                }
                .tint(Brand.accent)
                .accessibilityIdentifier("history.row.logAgain")
            }
            .swipeActions(edge: .trailing) {
                Button(String(localized: "action.delete"), systemImage: "trash", role: .destructive) {
                    delete()
                }
                .accessibilityIdentifier("history.row.delete")
            }
            .contextMenu {
                Button(String(localized: "action.duplicate"), systemImage: "repeat") {
                    logAgain()
                }
                Section {
                    Button(String(localized: "action.delete"), systemImage: "trash", role: .destructive) {
                        isPresentingDeleteConfirmation = true
                    }
                }
            }
            // Kept until a VoiceOver check shows the swipe actions as custom actions (docs are
            // silent; the simulator rotor is not reachable, CHK-00). Device check in plan 0045.
            .accessibilityActions {
                Button(String(localized: "action.duplicate")) {
                    logAgain()
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
                    delete()
                }
                .accessibilityIdentifier("confirmContextDeleteButton")

                Button(String(localized: "action.cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "history.row.deleteConfirm.message"))
            }
    }

    private func logAgain() {
        let copy = event.duplicated()
        withMotion(reduceMotion: reduceMotion) {
            context.insert(copy)
            RecordDeduplicator.ensureUniqueIdentity(copy, in: context)
            do {
                try context.save()
            } catch {
                logger.error("Log Again save failed: \(String(describing: type(of: error)))")
            }
        }
        drinkLogged(copy)
    }

    /// Always removes the Apple Health sample with the event (plan 0036).
    private func delete() {
        withMotion(reduceMotion: reduceMotion) {
            HealthWriteHooks.remove(event, using: healthService)
            context.delete(event)
            do {
                try context.save()
            } catch {
                logger.error("Delete save failed: \(String(describing: type(of: error)))")
            }
        }
    }
}

extension View {
    func historyRowActions(
        for event: ConsumptionEvent,
        in context: ModelContext,
        healthService: HealthService?,
        reduceMotion: Bool,
        drinkLogged: DrinkLoggedAction
    ) -> some View {
        modifier(
            HistoryRowActionsModifier(
                event: event,
                context: context,
                healthService: healthService,
                reduceMotion: reduceMotion,
                drinkLogged: drinkLogged
            )
        )
    }
}
