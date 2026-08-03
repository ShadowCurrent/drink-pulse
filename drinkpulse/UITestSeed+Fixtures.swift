import Foundation
import SwiftData

/// Multi-day synthetic fixture for the Insights UI tests (plan-0032, step 5).
///
/// Gated entirely behind `-dp_uitest_dataset multiday` (see `seedMultiDayFixture`),
/// so it is inert in production. Data is 100% synthetic — no PII, no real health
/// values. It exists only to give the Insights screen (period picker, area chart,
/// weekday bar chart, hero total, health metrics, guideline comparison) something
/// deterministic to render.
extension UITestSeed {

    /// One synthetic log: how many days ago, what to drink, and how much.
    private struct SeedSpec {
        let daysAgo: Int
        let volumeMl: Double
        let abv: Double
        let quantity: Int
        let name: String
        let category: DrinkCategory
        let icon: String
    }

    /// Deterministic spread across the last 14 days. Anchored to `noon` of each
    /// day so every event lands squarely inside its start-of-day bucket regardless
    /// of timezone, and stays inside the period ranges the view model computes.
    ///
    /// Shape (relative to launch day `D`):
    /// - Current week (offsets 0–6, drives the default Week view + weekday chart):
    ///   - D−0: Beer 500 ml 5%
    ///   - D−1: Wine 150 ml 12.5%
    ///   - D−2: Beer 330 ml 5%
    ///   - D−4: Wine 250 ml 12.5%
    ///   - D−6: Beer 500 ml 5% ×2
    /// - Prior days (offsets 7–13, give Month/All-Time + previous-week trend data):
    ///   - D−7:  Beer 500 ml 5%
    ///   - D−9:  Wine 150 ml 12.5%
    ///   - D−11: Beer 330 ml 5%
    ///   - D−13: Wine 200 ml 12.5%
    ///
    /// 9 events total, two categories (beer + wine), 6 distinct day-of-week
    /// columns covered, multiple drink-free days in between (for streak/free-day
    /// metrics). Today always has data so the current Week view is never empty.
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

    /// Inserts the multi-day spread into `context`. Call only when
    /// `seedMultiDayFixture` is `true`; the profile is inserted by the caller.
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

    /// Events-per-day within the initial `listPageDays` (7-day) window, one
    /// entry per day-offset 0...6. Deliberately varied (not a uniform count)
    /// so the seeded shape matches production: multiple `HistoryDaySectionCard`
    /// instances with different header text and row counts, not one giant
    /// homogeneous section. A uniform single-section fixture lets LazyVStack's
    /// per-row-average size estimate stay accurate (all rows identical), which
    /// does NOT reproduce the estimate drift the real bug depended on.
    private static let paginationStressCountsPerDay = [3, 3, 3, 3, 3, 3, 3]

    /// Inserts `paginationStressCountsPerDay` events across the last 7 days
    /// (22 rows across 7 differently-shaped section cards — stays strictly
    /// inside the initial `listPageDays` window) plus one marker event well
    /// outside it (20 days ago, a unique 999 ml volume). Gated behind
    /// `-dp_uitest_dataset paginationstress` (see `seedPaginationStressFixture`).
    ///
    /// Exists so `HistoryInteractionUITests+Pagination` has a fixture whose
    /// initial-window content (a) overflows one screen height, so the trailing
    /// "load more" sentinel is not visible on first layout, and (b) is spread
    /// across multiple variable-sized day-section cards — matching the actual
    /// History screen shape that produced the original scroll-to-bottom
    /// pagination regression (see `.planning/debug/resolved/history-scrollview-bugs.md`).
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
            let markerDay = cal.date(byAdding: .day, value: -20, to: startOfToday),
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
}
