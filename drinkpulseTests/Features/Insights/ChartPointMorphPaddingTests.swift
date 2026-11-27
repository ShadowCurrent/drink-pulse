import Testing
import Foundation
@testable import drinkpulse

@MainActor
struct ChartPointMorphPaddingTests {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return c
    }

    private func points(_ count: Int, from start: Date, unit: Calendar.Component = .day) -> [ChartPoint] {
        (0..<count).compactMap { i in
            cal.date(byAdding: unit, value: i, to: start).map { ChartPoint(slot: i, date: $0, grams: Double(i)) }
        }
    }

    private var sept1: Date { cal.date(from: DateComponents(year: 2026, month: 9, day: 1)) ?? .distantPast }

    // MARK: - morphSlotCount

    @Test func morphSlotCount_isConstantPerNavigablePeriod() {
        #expect(ChartPoint.morphSlotCount(for: .week) == 7)
        #expect(ChartPoint.morphSlotCount(for: .month) == 31)
        #expect(ChartPoint.morphSlotCount(for: .year) == 12)
    }

    @Test func morphSlotCount_nilForAllTime() {
        #expect(ChartPoint.morphSlotCount(for: .allTime) == nil)
    }

    // MARK: - paddedForMorph

    @Test func paddedForMorph_padsThirtyDayMonthToThirtyOne() {
        let padded = ChartPoint.paddedForMorph(points(30, from: sept1), to: 31, unit: .day, calendar: cal)
        #expect(padded.count == 31)
        #expect(padded.map(\.slot) == Array(0..<31))
    }

    @Test func paddedForMorph_paddingContinuesPastLastPointAtItsValue() throws {
        let real = points(28, from: sept1)
        let padded = ChartPoint.paddedForMorph(real, to: 31, unit: .day, calendar: cal)
        let last = try #require(real.last)
        let padding = padded.dropFirst(real.count)
        #expect(padding.allSatisfy { $0.grams == last.grams && $0.date > last.date })
        // Distinct dates: copies at the last date made `.monotone` draw a stray diagonal line.
        #expect(Set(padded.map(\.date)).count == padded.count)
    }

    @Test func paddedForMorph_unchangedWhenAlreadyFull() {
        let full = points(31, from: sept1)
        #expect(ChartPoint.paddedForMorph(full, to: 31, unit: .day, calendar: cal).count == 31)
    }

    @Test func paddedForMorph_unchangedWhenEmpty() {
        #expect(ChartPoint.paddedForMorph([], to: 31, unit: .day, calendar: cal).isEmpty)
    }

    @Test func paddedForMorph_unchangedWhenNoSlotCount() {
        #expect(ChartPoint.paddedForMorph(points(5, from: sept1), to: nil, unit: .day, calendar: cal).count == 5)
    }

    @Test func paddedForMorph_padsPartialYearByMonths() throws {
        let real = points(11, from: cal.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? .distantPast,
                          unit: .month)
        let padded = ChartPoint.paddedForMorph(real, to: 12, unit: .month, calendar: cal)
        let extra = try #require(padded.last)
        #expect(cal.component(.month, from: extra.date) == 12)
    }

    // MARK: - visibleDomain

    @Test func visibleDomain_spansFirstToLastBinMiddle() throws {
        let real = points(30, from: sept1)
        let domain = try #require(ChartPoint.visibleDomain(of: real, unit: .day, calendar: cal))
        #expect(domain.lowerBound == sept1.addingTimeInterval(12 * 3600))
        let lastDay = try #require(real.last?.date)
        #expect(domain.upperBound == lastDay.addingTimeInterval(12 * 3600))
    }

    @Test func visibleDomain_excludesPadding() throws {
        let real = points(30, from: sept1)
        let padded = ChartPoint.paddedForMorph(real, to: 31, unit: .day, calendar: cal)
        let domain = try #require(ChartPoint.visibleDomain(of: real, unit: .day, calendar: cal))
        let firstPad = try #require(padded.last)
        #expect(!domain.contains(firstPad.date))
    }

    @Test func visibleDomain_nilWhenEmpty() {
        #expect(ChartPoint.visibleDomain(of: [], unit: .day, calendar: cal) == nil)
    }

    @Test func visibleDomain_nilForSinglePoint() {
        // Regression: a zero-width domain logged "Invalid frame dimension" (UI tests, 2026-11-26).
        #expect(ChartPoint.visibleDomain(of: points(1, from: sept1), unit: .day, calendar: cal) == nil)
    }

    @Test func binMiddle_isHalfwayThroughTheMonth() throws {
        let middle = try #require(ChartPoint.binMiddle(of: sept1, unit: .month, calendar: cal))
        #expect(middle == sept1.addingTimeInterval(15 * 24 * 3600))
    }
}
