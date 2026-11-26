import Foundation
import SwiftData

extension UITestSeed {

    private struct SeedSpec {
        let daysAgo: Int
        let volumeMl: Double
        let abv: Double
        let quantity: Int
        let name: String
        let category: DrinkCategory
        let icon: String
    }

    private static let multiDaySpecs: [SeedSpec] = [
        SeedSpec(daysAgo: 0,  volumeMl: 500, abv: 0.05,  quantity: 1, name: "Beer", category: .beer, icon: "🍺"),
        SeedSpec(daysAgo: 1,  volumeMl: 150, abv: 0.125, quantity: 1, name: "Wine", category: .wine, icon: "🍷"),
        SeedSpec(daysAgo: 2,  volumeMl: 330, abv: 0.05,  quantity: 1, name: "Beer", category: .beer, icon: "🍺"),
        SeedSpec(daysAgo: 4,  volumeMl: 250, abv: 0.125, quantity: 1, name: "Wine", category: .wine, icon: "🍷"),
        SeedSpec(daysAgo: 6,  volumeMl: 500, abv: 0.05,  quantity: 2, name: "Beer", category: .beer, icon: "🍺"),
        SeedSpec(daysAgo: 7,  volumeMl: 500, abv: 0.05,  quantity: 1, name: "Beer", category: .beer, icon: "🍺"),
        SeedSpec(daysAgo: 9,  volumeMl: 150, abv: 0.125, quantity: 1, name: "Wine", category: .wine, icon: "🍷"),
        SeedSpec(daysAgo: 11, volumeMl: 330, abv: 0.05,  quantity: 1, name: "Beer", category: .beer, icon: "🍺"),
        SeedSpec(daysAgo: 13, volumeMl: 200, abv: 0.125, quantity: 1, name: "Wine", category: .wine, icon: "🍷"),
    ]

    @MainActor
    static func seedMultiDayEvents(into context: ModelContext) {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: .now)
        for spec in multiDaySpecs {
            guard
                let day = cal.date(byAdding: .day, value: -spec.daysAgo, to: startOfToday),
                let consumptionDate = cal.date(bySettingHour: 12, minute: 0, second: 0, of: day)
            else { continue }
            let event = ConsumptionEvent(
                consumptionDate: consumptionDate,
                volumeMl: spec.volumeMl,
                abv: spec.abv,
                quantity: spec.quantity,
                category: spec.category,
                icon: spec.icon
            )
            context.insert(event)
        }
    }

    /// Dataset `overweekly` (plan 0046, Review focus 1): heavy days 1 and 2 days ago, nothing
    /// today, so the rolling 7-day total is over the weekly limit while today is within it.
    private static let overWeeklySpecs: [SeedSpec] = [
        SeedSpec(daysAgo: 1, volumeMl: 500, abv: 0.05, quantity: 4, name: "Beer", category: .beer, icon: "🍺"),
        SeedSpec(daysAgo: 2, volumeMl: 500, abv: 0.05, quantity: 4, name: "Beer", category: .beer, icon: "🍺"),
    ]

    @MainActor
    static func seedOverWeeklyEvents(into context: ModelContext) {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: .now)
        for spec in overWeeklySpecs {
            guard
                let day = cal.date(byAdding: .day, value: -spec.daysAgo, to: startOfToday),
                let consumptionDate = cal.date(bySettingHour: 12, minute: 0, second: 0, of: day)
            else { continue }
            context.insert(ConsumptionEvent(
                consumptionDate: consumptionDate, volumeMl: spec.volumeMl, abv: spec.abv,
                quantity: spec.quantity, category: spec.category, icon: spec.icon
            ))
        }
    }

    /// Dataset `alcoholfreetoday` (plan 0050, D0050-5): one 0 % beer logged now and nothing
    /// else, so no day counts yet for the alcohol-free metrics.
    @MainActor
    static func seedAlcoholFreeTodayEvents(into context: ModelContext) {
        context.insert(ConsumptionEvent(
            consumptionDate: .now, volumeMl: 500, abv: 0, quantity: 1, category: .beer, icon: "🍺"
        ))
    }

    /// Dataset `paginationstress`: 3 events a day for 20 days (60, more than one 50-event
    /// page) plus a 999 ml marker 40 days ago that only a second page loads.
    private static let paginationStressCountsPerDay = Array(repeating: 3, count: 20)

    @MainActor
    static func seedPaginationStressEvents(into context: ModelContext) {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: .now)
        for (daysAgo, count) in paginationStressCountsPerDay.enumerated() {
            guard let day = cal.date(byAdding: .day, value: -daysAgo, to: startOfToday) else { continue }
            for minute in 0..<count {
                guard
                    let consumptionDate = cal.date(bySettingHour: 12, minute: minute, second: 0, of: day)
                else { continue }
                context.insert(ConsumptionEvent(
                    consumptionDate: consumptionDate,
                    volumeMl: 330,
                    abv: 0.05,
                    quantity: 1,
                    category: .beer,
                    icon: "🍺"
                ))
            }
        }
        guard
            let markerDay = cal.date(byAdding: .day, value: -40, to: startOfToday),
            let markerDate = cal.date(bySettingHour: 12, minute: 0, second: 0, of: markerDay)
        else { return }
        context.insert(ConsumptionEvent(
            consumptionDate: markerDate,
            volumeMl: 999,
            abv: 0.05,
            quantity: 1,
            category: .beer,
            icon: "🍺"
        ))
    }

    @MainActor
    static func seedSameDayEvents(into context: ModelContext) {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: .now)
        guard
            let morning = cal.date(bySettingHour: 8, minute: 0, second: 0, of: startOfToday),
            let evening = cal.date(bySettingHour: 20, minute: 0, second: 0, of: startOfToday)
        else { return }
        context.insert(ConsumptionEvent(
            consumptionDate: morning,
            volumeMl: 330,
            abv: 0.05,
            quantity: 1,
            category: .beer,
            icon: "🍺"
        ))
        context.insert(ConsumptionEvent(
            consumptionDate: evening,
            volumeMl: 750,
            abv: 0.125,
            quantity: 1,
            category: .wine,
            icon: "🍷"
        ))
    }

    @MainActor
    static func seedOutsideWindowEvents(into context: ModelContext) {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: .now)
        let days = [
            cal.date(byAdding: .day, value: -10, to: startOfToday),
            cal.date(byAdding: .day, value: -12, to: startOfToday),
            cal.date(byAdding: .day, value: -40, to: startOfToday),
        ]
        for day in days {
            guard
                let day,
                let consumptionDate = cal.date(bySettingHour: 12, minute: 0, second: 0, of: day)
            else { continue }
            context.insert(ConsumptionEvent(
                consumptionDate: consumptionDate,
                volumeMl: 777,
                abv: 0.05,
                quantity: 1,
                category: .beer,
                icon: "🍺"
            ))
        }
    }

    /// Dataset `search` (plan-0039): "Guinness" today, "Tyskie" 200 days ago
    /// (outside the 90-day list window) and an unnamed 330 ml beer today.
    @MainActor
    static func seedSearchEvents(into context: ModelContext) {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: .now)
        let seeds: [(name: String?, daysAgo: Int, volumeMl: Double)] = [
            ("Guinness", 0, 500), ("Tyskie", 200, 500), (nil, 0, 330),
        ]
        for seed in seeds {
            guard
                let day = cal.date(byAdding: .day, value: -seed.daysAgo, to: startOfToday),
                let consumptionDate = cal.date(bySettingHour: 12, minute: 0, second: 0, of: day)
            else { continue }
            context.insert(ConsumptionEvent(
                consumptionDate: consumptionDate,
                volumeMl: seed.volumeMl,
                abv: 0.05,
                quantity: 1,
                category: .beer,
                icon: "🍺",
                customName: seed.name
            ))
        }
    }
}
