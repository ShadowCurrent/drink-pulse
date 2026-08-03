import SwiftUI
import SwiftData
#if DEBUG
import OSLog
#endif

/// Wraps a History row insert or delete in the shared entrance/exit animation,
/// honoring `accessibilityReduceMotion` (CLAUDE.md accessibility rule). Shared
/// by every mutating call site (swipe delete, context-menu delete, context-menu
/// duplicate) so the row/section animation stays consistent rather than each
/// site picking its own curve.
func animatedHistoryChange(reduceMotion: Bool, _ action: () -> Void) {
    if reduceMotion {
        action()
    } else {
        withAnimation(.default, action)
    }
}

/// Long-press context menu for a consumption event, plus the confirmation that
/// gates its destructive action.
///
/// Delete permanently destroys a logged health record and its HealthKit sample
/// with no undo, so it may not fire straight from the menu: the menu item only
/// arms `isPresentingDeleteConfirmation`, and the removal runs from the dialog's
/// confirm button. This mirrors the Edit sheet's already-shipped confirmation
/// (`EditEventView` + `DeleteConfirmationPopover`), so both delete paths carry
/// the same safety posture. Duplicate is non-destructive and stays one tap.
///
/// This is a `ViewModifier` rather than a bare `contextMenu` call because the
/// pending-confirmation flag needs `@State` storage, which a `View` extension
/// method has nowhere to put.
private struct EventContextMenuModifier: ViewModifier {
    let event: ConsumptionEvent
    let context: ModelContext
    let healthService: HealthService?
    let reduceMotion: Bool

    @State private var isPresentingDeleteConfirmation = false

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
            // A context menu is reachable only by long-press, which VoiceOver users
            // cannot perform on a row that is itself a single combined element, so
            // Duplicate and Delete were effectively unreachable without sight
            // (finding C14-2). These live here rather than on `EventRowButton` so they
            // share this modifier's confirmation state and its action methods: the
            // Delete action arms exactly the same flag the menu's destructive button
            // arms, so the accessibility path is confirmation-gated identically and
            // the two paths cannot drift apart (threat register T-07-10).
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

    /// Instant re-log. Non-destructive, so it is NOT confirmation-gated — but it is
    /// a method rather than an inline closure so the menu item and the accessibility
    /// action invoke the same code (mirrors `performDelete()`).
    private func performDuplicate() {
        animatedHistoryChange(reduceMotion: reduceMotion) {
            let copy = event.duplicated()
            context.insert(copy)
            RecordDeduplicator.ensureUniqueIdentity(copy, in: context)
            // Persist immediately: a freshly `insert()`-ed SwiftData object
            // carries a TEMPORARY `PersistentIdentifier` that only becomes
            // permanent once the context saves. If the user opens this
            // duplicate's Edit sheet before that save happens, SwiftData's
            // own autosave can flip the identifier out from under
            // `HistoryView`'s `.sheet(item:)` mid-edit, which SwiftUI reads
            // as "a different item," tearing down and reconstructing the
            // sheet — silently discarding every unsaved field (see debug
            // session sheet-closes-reopens-loses-state). Saving here closes
            // that window before the row is ever tappable. Wrapping the
            // whole thing in the shared animation also gives the new row
            // an entrance transition instead of popping in unanimated.
            try? context.save()
        }
    }

    /// The actual removal, reachable only from the confirmation's destructive button.
    private func performDelete() {
        animatedHistoryChange(reduceMotion: reduceMotion) {
            // Capture ids + enqueue the Health delete before invalidating the @Model.
            HealthWriteHooks.remove(event, using: healthService)
            context.delete(event)
            // Force the @Query refresh into this withAnimation transaction — see
            // matching comment in HistoryListQueryView's swipe-delete call site.
            try? context.save()
        }
    }
}

extension View {
    /// Long-press context menu for a consumption event: Duplicate (instant re-log,
    /// copies all fields with `timestamp = .now`) and Delete (gated by a
    /// confirmation dialog). Mutations go straight through the injected
    /// `ModelContext`, matching the no-repository architecture.
    func eventContextMenu(
        for event: ConsumptionEvent,
        in context: ModelContext,
        healthService: HealthService?,
        reduceMotion: Bool
    ) -> some View {
        modifier(
            EventContextMenuModifier(
                event: event,
                context: context,
                healthService: healthService,
                reduceMotion: reduceMotion
            )
        )
    }
}
