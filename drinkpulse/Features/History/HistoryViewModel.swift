import SwiftUI

struct DayCell: Identifiable {
    let position: Int
    let date: Date?      // nil = leading/trailing padding cell
    let grams: Double
    let isFuture: Bool
    let isToday: Bool
    var id: Int { position }
}

@Observable @MainActor final class HistoryViewModel {

    func groupedByDay(
        _ events: [ConsumptionEvent],
        calendar: Calendar = .current
    ) -> [(day: Date, events: [ConsumptionEvent])] {
        let dict = Dictionary(grouping: events) {
            calendar.startOfDay(for: $0.timestamp)
        }
        return dict
            .sorted { $0.key > $1.key }
            .map { (day: $0.key, events: $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }

    func gramsByDay(
        _ events: [ConsumptionEvent],
        calendar: Calendar = .current
    ) -> [Date: Double] {
        events.reduce(into: [Date: Double]()) { acc, e in
            acc[calendar.startOfDay(for: e.timestamp), default: 0] += e.pureAlcoholGrams
        }
    }

    func monthCells(
        year: Int,
        month: Int,
        events: [ConsumptionEvent],
        calendar: Calendar = .current,
        today: Date = .now
    ) -> [DayCell] {
        guard
            let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
            let range = calendar.range(of: .day, in: .month, for: firstDay)
        else { return [] }

        let gramsMap = gramsByDay(events, calendar: calendar)
        let todayStart = calendar.startOfDay(for: today)

        let firstWeekday = calendar.firstWeekday
        let firstDayWeekday = calendar.component(.weekday, from: firstDay)
        let leadingCount = (firstDayWeekday - firstWeekday + 7) % 7
        let daysCount = range.count
        let totalCells = Int(ceil(Double(leadingCount + daysCount) / 7.0)) * 7

        var cells: [DayCell] = []
        cells.reserveCapacity(totalCells)

        for i in 0..<leadingCount {
            cells.append(DayCell(position: i, date: nil, grams: 0, isFuture: false, isToday: false))
        }

        for dayNum in range {
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: dayNum)) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let position = leadingCount + dayNum - 1
            cells.append(DayCell(
                position: position,
                date: dayStart,
                grams: gramsMap[dayStart] ?? 0,
                isFuture: dayStart > todayStart,
                isToday: calendar.isDate(dayStart, inSameDayAs: todayStart)
            ))
        }

        let trailingStart = leadingCount + daysCount
        for i in 0..<(totalCells - trailingStart) {
            cells.append(DayCell(position: trailingStart + i, date: nil, grams: 0, isFuture: false, isToday: false))
        }

        return cells
    }

    func riskColor(forGrams grams: Double, dailyLimit: Double) -> Color? {
        guard grams > 0, dailyLimit > 0 else { return nil }
        let pct = grams / dailyLimit
        if pct < 0.5 { return .dpGreen }
        if pct < 1.0 { return .dpAmber }
        return .dpRed
    }
}
