import Testing
import Foundation
@testable import drinkpulse

@MainActor
struct CalendarDaysTests {

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Warsaw")!
        return c
    }

    private func date(_ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    // MARK: - days(in:)

    @Test func days_sameDay_returnsOneStartOfDay() {
        let days = cal.days(in: date(7, 18, 9)...date(7, 18, 21))
        #expect(days == [cal.startOfDay(for: date(7, 18))])
    }

    @Test func days_spanningMonthEnd_isInclusive() {
        let days = cal.days(in: date(7, 30, 15)...date(8, 2, 9))
        #expect(days.count == 4)
        #expect(days.first == cal.startOfDay(for: date(7, 30)))
        #expect(days.last == cal.startOfDay(for: date(8, 2)))
    }

    @Test func days_acrossSpringForward_keepsOneEntryPerDay() {
        let days = cal.days(in: date(3, 28)...date(3, 30))
        #expect(days.count == 3)
        #expect(days.allSatisfy { cal.startOfDay(for: $0) == $0 })
    }
}
