import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct HistoryDayTotalTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func event(volumeMl: Double = 500, abv: Double = 0.05, quantity: Int = 1,
                       in context: ModelContext) -> ConsumptionEvent {
        let e = ConsumptionEvent(volumeMl: volumeMl, abv: abv, quantity: quantity,
                                 category: .beer, icon: "🍺")
        context.insert(e)
        return e
    }

    @Test func test_dayTotal_countsPortions_notLogs() throws {
        let context = try makeContext()
        let events = [event(quantity: 2, in: context), event(quantity: 1, in: context)]
        let total = HistoryDayTotal(events: events, density: AlcoholUnit.physicalDensityGramsPerMl)
        #expect(total.drinkCount == 3)
    }

    @Test func test_dayTotal_usesGivenDensity() throws {
        let context = try makeContext()
        let events = [event(in: context)]
        let units = HistoryDayTotal(events: events, density: 0.8)
        let grams = HistoryDayTotal(events: events, density: 0.789)
        #expect(abs(units.massGrams - 20.0) < 1e-9)
        #expect(abs(grams.massGrams - 19.725) < 1e-9)
    }

    @Test func test_dayTotal_isZero_forNoEvents() {
        let total = HistoryDayTotal(events: [], density: 0.789)
        #expect(total == HistoryDayTotal(drinkCount: 0, massGrams: 0))
    }
}
