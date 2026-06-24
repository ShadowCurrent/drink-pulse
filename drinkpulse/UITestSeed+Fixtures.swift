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
                let timestamp = cal.date(bySettingHour: 12, minute: 0, second: 0, of: day)
            else { continue }
            let event = ConsumptionEvent(
                timestamp: timestamp,
                volumeMl: spec.volumeMl,
                abv: spec.abv,
                quantity: spec.quantity,
                name: spec.name,
                category: spec.category,
                icon: spec.icon
            )
            context.insert(event)
        }
    }
}
