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

extension View {
    /// Long-press context menu for a consumption event: Duplicate (instant re-log,
    /// copies all fields with `timestamp = .now`) and Delete. Mutations go straight
    /// through the injected `ModelContext`, matching the no-repository architecture.
    func eventContextMenu(
        for event: ConsumptionEvent,
        in context: ModelContext,
        healthService: HealthService?,
        reduceMotion: Bool
    ) -> some View {
        contextMenu {
            #if DEBUG
            let _ = Logger(subsystem: "com.drinkpulse.app", category: "performance").notice("History row long-press: contextMenu content build start")
            #endif
            Button {
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
            } label: {
                Label(String(localized: "action.duplicate"), systemImage: "plus.square.on.square")
            }

            Button(role: .destructive) {
                animatedHistoryChange(reduceMotion: reduceMotion) {
                    // Capture ids + enqueue the Health delete before invalidating the @Model.
                    HealthWriteHooks.remove(event, using: healthService)
                    context.delete(event)
                    // Force the @Query refresh into this withAnimation transaction — see
                    // matching comment in HistoryListQueryView's swipe-delete call site.
                    try? context.save()
                }
            } label: {
                Label(String(localized: "action.delete"), systemImage: "trash")
            }
        }
    }
}
