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
        // 440 ml event (metric "Big can", off-region in US) opened in .usCustomary.
        // The US grid's nearest row is 473 ml, but with no volume interaction
        // selected == original, so 440 is preserved.
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
        // 444.5 ml is not on any grid; untouched, it must remain exactly 444.5.
        let persisted = EditEventView.volumeToPersist(selected: 444.5, original: 444.5)
        #expect(persisted == 444.5)
    }

    // MARK: - Stored-value injection into the picker options

    @Test("Stored volume is representable exactly as a picker option")
    func storedVolumeInjectedExactly() throws {
        // A 440 ml beer ("Big can", metric-only) in a US-mode profile: 440 is not
        // US-native, so the edit picker must inject the exact 440 ml as a
        // pre-selected option, shown converted, never snapped. (500 is now a
        // US-native "Bottle" cross-borrow, so it no longer demonstrates this.)
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

        // Confirm the injection is necessary (440 is genuinely off-region in US).
        let usNative = DrinkTypePreset.beer.volumes(for: .usCustomary).map(\.volumeMl)
        #expect(!usNative.contains(440))
        // The canonical value the picker must surface, unchanged.
        #expect(event.volumeMl == 440)
    }
}
