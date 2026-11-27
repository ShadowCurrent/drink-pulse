import SwiftUI
import SwiftData

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
        EventActions.logAgain(
            event, in: context, healthService: healthService,
            reduceMotion: reduceMotion, drinkLogged: drinkLogged
        )
    }

    private func delete() {
        EventActions.delete(event, in: context, healthService: healthService, reduceMotion: reduceMotion)
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
