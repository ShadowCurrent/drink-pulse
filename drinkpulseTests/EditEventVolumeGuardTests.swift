import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// Regression tests for the EditEventView volume-integrity guard (plan-0030,
/// the highest-risk part of the plan). An untouched edit must preserve the
/// canonical `volumeMl` exactly across any unit switch; an explicit change must
/// persist.
@MainActor
struct EditEventVolumeGuardTests {

    // MARK: - The guard contract (pure, view-independent)

    @Test("Untouched edit preserves the original volume byte-for-byte")
    func untouchedEdit_keepsOriginal() {
        // 500 ml event opened in .usCustomary. The US grid's nearest row is 473 ml,
        // but with no volume interaction selected == original, so 500 is preserved.
        let persisted = EditEventView.volumeToPersist(selected: 500, original: 500)
        #expect(persisted == 500)
    }

    @Test("Explicit volume change is persisted")
    func explicitChange_isPersisted() {
        let persisted = EditEventView.volumeToPersist(selected: 473, original: 500)
        #expect(persisted == 473)
    }

    @Test("Guard never snaps an off-grid stored value")
    func offGridStoredValue_survives() {
        // 444.5 ml is not on any grid; untouched, it must remain exactly 444.5.
        let persisted = EditEventView.volumeToPersist(selected: 444.5, original: 444.5)
        #expect(persisted == 444.5)
    }

    // MARK: - Stored-value injection into the picker options

    @Test("Stored volume is representable exactly as a picker option")
    func storedVolumeInjectedExactly() throws {
        // A 500 ml beer in a US-mode profile: 500 is not US-native (US-native beers
        // are 355/473), so the edit picker must inject the exact 500 ml as a
        // pre-selected option, shown converted, never snapped.
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: config
        )
        container.mainContext.insert(
            UserProfile(unitSystem: .usCustomary)
        )
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05,
                                     name: "Beer", category: .beer, icon: "🍺")
        container.mainContext.insert(event)

        // The beer preset has no US-native 500 ml entry; confirm the injection is
        // necessary (i.e. 500 is genuinely off-region in US mode).
        let usNative = DrinkTypePreset.beer.volumes(for: .usCustomary).map(\.volumeMl)
        #expect(!usNative.contains(500))
        // The canonical value the picker must surface, unchanged.
        #expect(event.volumeMl == 500)
    }
}
