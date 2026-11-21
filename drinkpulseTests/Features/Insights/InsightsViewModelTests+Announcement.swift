import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// VoiceOver announcement on period change (plan 0046, D0046-14): "<friendly label>, <range>,
/// <total spoken>", with the unit written out.
@MainActor
extension InsightsViewModelTests {

    private func beer(in context: ModelContext, at date: Date = .now) -> ConsumptionEvent {
        let e = ConsumptionEvent(consumptionDate: date, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        context.insert(e)
        return e
    }

    @Test func test_periodAnnouncement_grams_spellsOutUnit() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        vm.events = [beer(in: c.mainContext)]
        #expect(vm.periodAnnouncement == "This week, \(vm.rangeLabel), 19.7 grams of pure alcohol")
    }

    @Test func test_periodAnnouncement_ukUnits() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.profile = UserProfile(guidelineChoice: .uk, alcoholUnit: .standardDrinks)
        vm.period = .week
        vm.events = [beer(in: c.mainContext)]
        #expect(vm.periodAnnouncement == "This week, \(vm.rangeLabel), 2.5 units")
    }

    @Test func test_periodAnnouncement_standardDrinks() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.profile = UserProfile(guidelineChoice: .who, alcoholUnit: .standardDrinks)
        vm.period = .week
        vm.events = [beer(in: c.mainContext)]
        #expect(vm.periodAnnouncement == "This week, \(vm.rangeLabel), 2.0 standard drinks")
    }

    @Test func test_formattedNumber_isValueInUserUnit_withoutLabel() {
        let vm = makeVM()
        vm.profile = UserProfile(guidelineChoice: .uk, alcoholUnit: .standardDrinks)
        #expect(vm.formattedNumber(20) == "2.5")
    }

    @Test func test_periodAnnouncement_allTime() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .allTime
        vm.events = [beer(in: c.mainContext)]
        #expect(vm.periodAnnouncement == "All time, \(vm.rangeLabel), 19.7 grams of pure alcohol")
    }
}
