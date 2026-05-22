import Testing
import Foundation
@testable import drinkpulse

struct InsightsDataGeneratorTests {

    private func date(_ str: String) -> Date {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: str)!
    }

    // MARK: - Nil-guard cases

    @Test func returnsNilForToday() {
        #expect(InsightsDataGenerator.gramsForDate(.now) == nil)
    }

    @Test func returnsNilForFutureDate() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        #expect(InsightsDataGenerator.gramsForDate(tomorrow) == nil)
    }

    @Test func returnsNilBeforeStartDate() {
        // Dec 31 2022 is one day before the valid window opens
        #expect(InsightsDataGenerator.gramsForDate(date("2022-12-31")) == nil)
    }

    // MARK: - Valid range

    @Test func returnsNonNilForStartDate() {
        // Jan 1 2023 is the first valid date
        #expect(InsightsDataGenerator.gramsForDate(date("2023-01-01")) != nil)
    }

    @Test func returnsNonNilForKnownPastDate() {
        #expect(InsightsDataGenerator.gramsForDate(date("2024-06-15")) != nil)
    }

    // MARK: - Determinism

    @Test func isDeterministic() {
        let d = date("2024-03-20")
        #expect(InsightsDataGenerator.gramsForDate(d) == InsightsDataGenerator.gramsForDate(d))
    }

    // MARK: - Value constraints

    @Test func valuesAreNonNegative() {
        let cal = Calendar.current
        var current = date("2024-01-01")
        let end = date("2024-01-31")
        while current <= end {
            if let g = InsightsDataGenerator.gramsForDate(current) {
                #expect(g >= 0)
            }
            current = cal.date(byAdding: .day, value: 1, to: current) ?? current
        }
    }

    // MARK: - Day-of-week multiplier

    @Test func saturdayAverageHigherThanTuesdayAverage() {
        // Saturday has 1.8× multiplier; Tuesday (weekday) has 0.7×.
        // Sample the whole of 2024 to get enough data points.
        let cal = Calendar.current
        var satTotal = 0, satDays = 0
        var tueTotal = 0, tueDays = 0
        var d = date("2024-01-01")
        let end = date("2024-12-31")
        while d <= end {
            let wd = cal.component(.weekday, from: d)
            if let g = InsightsDataGenerator.gramsForDate(d) {
                switch wd {
                case 7: satTotal += g; satDays += 1   // Saturday
                case 3: tueTotal += g; tueDays += 1   // Tuesday
                default: break
                }
            }
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
        }
        let satAvg = satDays > 0 ? Double(satTotal) / Double(satDays) : 0
        let tueAvg = tueDays > 0 ? Double(tueTotal) / Double(tueDays) : 0
        #expect(satAvg > tueAvg)
    }

    // MARK: - Long-term trend multiplier

    @Test func year2023AverageHigherThan2025() {
        // 2023 has 1.35× trend; 2025 has 1.08×.
        // Use Apr–Aug to hold seasonal effects constant across both years.
        func avgForYear(_ year: Int) -> Double {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            let start = fmt.date(from: "\(year)-04-01")!
            let end   = fmt.date(from: "\(year)-08-31")!
            let cal = Calendar.current
            var sum = 0, n = 0
            var d = start
            while d <= end {
                if let g = InsightsDataGenerator.gramsForDate(d) { sum += g; n += 1 }
                d = cal.date(byAdding: .day, value: 1, to: d) ?? d
            }
            return n > 0 ? Double(sum) / Double(n) : 0
        }
        #expect(avgForYear(2023) > avgForYear(2025))
    }
}
