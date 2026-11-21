import Foundation

/// The figures in a History day header: portions logged and the day's mass of pure alcohol
/// at the display-unit density (plan 0045, D0045-2).
struct HistoryDayTotal: Equatable {
    let drinkCount: Int
    let massGrams: Double

    init(drinkCount: Int, massGrams: Double) {
        self.drinkCount = drinkCount
        self.massGrams = massGrams
    }

    /// `drinkCount` sums `quantity` (portions, not logs); `massGrams` uses `density`, the
    /// display unit's density (`RowUnitContext.density`).
    init(events: [ConsumptionEvent], density: Double) {
        drinkCount = events.reduce(0) { $0 + $1.quantity }
        massGrams = events.reduce(0) { $0 + $1.alcoholGrams(density: density) }
    }
}
