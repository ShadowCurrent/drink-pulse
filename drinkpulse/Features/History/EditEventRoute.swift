import Foundation

/// What a History row pushes: the event's stable `uuid`, not the model (SwiftUI "Understanding
/// the navigation stack": avoid model types as elements of a navigation path). Not the
/// `persistentModelID` either: a just-logged event has a temporary one that changes on the next
/// save (SwiftData `PersistentIdentifier.isTemporary`), which emptied the pushed screen.
struct EditEventRoute: Hashable {
    let uuid: UUID
}
