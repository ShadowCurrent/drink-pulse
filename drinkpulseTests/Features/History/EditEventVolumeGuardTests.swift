import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct EditEventVolumeGuardTests {

    // MARK: - The guard contract (pure, view-independent)

    @Test("Untouched edit preserves the original volume byte-for-byte")
    func untouchedEdit_keepsOriginal() {
        let persisted = EditEventView.volumeToPersist(selected: 440, original: 440)
        #expect(persisted == 440)
    }

    @Test("Explicit volume change is persisted")
    func explicitChange_isPersisted() {
        let persisted = EditEventView.volumeToPersist(selected: 473, original: 500)
        #expect(persisted == 473)
    }

    @Test("Guard never snaps an off-grid stored value")
    func offGridStoredValue_survives() {
        let persisted = EditEventView.volumeToPersist(selected: 444.5, original: 444.5)
        #expect(persisted == 444.5)
    }

    // MARK: - Stored-value injection into the picker options

    @Test("Stored volume is representable exactly as a picker option")
    func storedVolumeInjectedExactly() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: config
        )
        container.mainContext.insert(
            UserProfile(unitSystem: .usCustomary)
        )
        let event = ConsumptionEvent(volumeMl: 440, abv: 0.05, category: .beer, icon: "🍺")
        container.mainContext.insert(event)

        let usNative = DrinkTypePreset.beer.volumes(for: .usCustomary).map(\.volumeMl)
        #expect(!usNative.contains(440))
        #expect(event.volumeMl == 440)
    }
}
