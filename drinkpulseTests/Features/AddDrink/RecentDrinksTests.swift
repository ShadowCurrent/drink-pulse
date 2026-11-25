import Foundation
import Testing
@testable import drinkpulse

@MainActor
struct RecentDrinksTests {

    private func event(
        _ category: DrinkCategory,
        _ volumeMl: Double,
        _ abv: Double,
        name: String? = nil,
        quantity: Int = 1,
        minutesAgo: Double
    ) -> ConsumptionEvent {
        ConsumptionEvent(
            consumptionDate: Date(timeIntervalSince1970: 1_000_000 - minutesAgo * 60),
            volumeMl: volumeMl, abv: abv, quantity: quantity,
            category: category, icon: DrinkTypePreset.preset(for: category).icon,
            customName: name
        )
    }

    @Test func test_make_returnsNewestDistinct_upToLimit() {
        let events = [
            event(.beer, 500, 0.05, minutesAgo: 1),
            event(.wine, 150, 0.125, minutesAgo: 2),
            event(.beer, 500, 0.05, minutesAgo: 3),
            event(.vodka, 40, 0.40, minutesAgo: 4),
            event(.wine, 150, 0.125, minutesAgo: 5),
            event(.cider, 500, 0.045, minutesAgo: 6),
        ]
        let recent = RecentDrinks.make(from: events)
        #expect(recent.map(\.category) == [.beer, .wine, .vodka])
    }

    @Test func test_make_distinguishesCustomName_caseInsensitive() {
        let events = [
            event(.beer, 500, 0.05, name: "IPA", minutesAgo: 1),
            event(.beer, 500, 0.05, name: "ipa ", minutesAgo: 2),
            event(.beer, 500, 0.05, name: "Stout", minutesAgo: 3),
        ]
        let recent = RecentDrinks.make(from: events)
        #expect(recent.map(\.customName) == ["IPA", "Stout"])
    }

    @Test func test_make_blankCustomName_isNil() {
        let recent = RecentDrinks.make(from: [event(.beer, 500, 0.05, name: "  ", minutesAgo: 1)])
        #expect(recent.first?.customName == nil)
    }

    @Test func test_make_ignoresQuantity() {
        let events = [
            event(.beer, 500, 0.05, quantity: 1, minutesAgo: 1),
            event(.beer, 500, 0.05, quantity: 3, minutesAgo: 2),
        ]
        #expect(RecentDrinks.make(from: events).count == 1)
    }

    @Test func test_make_distinguishesVolumeAndABV() {
        let events = [
            event(.beer, 500, 0.05, minutesAgo: 1),
            event(.beer, 330, 0.05, minutesAgo: 2),
            event(.beer, 500, 0.06, minutesAgo: 3),
        ]
        #expect(RecentDrinks.make(from: events).count == 3)
    }

    @Test func test_make_emptyEvents_isEmpty() {
        #expect(RecentDrinks.make(from: []).isEmpty)
    }

    @Test func test_make_keepsStoredVolumeAndABV() {
        let stored = event(.wine, 187, 0.137, minutesAgo: 1)
        let recent = RecentDrinks.make(from: [stored])
        #expect(recent.first?.volumeMl == 187)
        #expect(recent.first?.abv == 0.137)
        #expect(recent.first?.icon == "🍷")
    }

    @Test func test_make_ids_areDistinct() {
        let events = [
            event(.beer, 500, 0.05, name: "IPA", minutesAgo: 1),
            event(.beer, 500, 0.05, minutesAgo: 2),
        ]
        let ids = RecentDrinks.make(from: events).map(\.id)
        #expect(Set(ids).count == 2)
    }
}
