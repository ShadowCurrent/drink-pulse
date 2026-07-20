import Foundation
import Testing
@testable import drinkpulse

struct WeeklySummaryCalculatorTests {

    // MARK: - No prior-week data at all (ENGG-06)

    @Test func content_skips_whenNoPriorWeekDataAtAll() {
        let result = WeeklySummaryCalculator.content(
            currentWeekGrams: 42,
            priorWeekGrams: 999,
            hasAnyPriorWeekData: false
        )
        #expect(result == .skip)
    }

    // MARK: - Prior week is zero, but real week data exists (ENGG-05)

    @Test func content_directionOnlyUp_whenPriorWeekZero_currentWeekPositive() {
        let result = WeeklySummaryCalculator.content(
            currentWeekGrams: 20,
            priorWeekGrams: 0,
            hasAnyPriorWeekData: true
        )
        #expect(result == .directionOnly(.up))
    }

    @Test func content_directionOnlySame_whenBothWeeksZero() {
        let result = WeeklySummaryCalculator.content(
            currentWeekGrams: 0,
            priorWeekGrams: 0,
            hasAnyPriorWeekData: true
        )
        #expect(result == .directionOnly(.same))
    }

    // MARK: - Percentage band (ENGG-04)

    @Test func content_percentageUp_wellAboveBand() {
        let result = WeeklySummaryCalculator.content(
            currentWeekGrams: 120,
            priorWeekGrams: 100,
            hasAnyPriorWeekData: true
        )
        #expect(result == .percentage(fraction: 0.2, direction: .up))
    }

    @Test func content_percentageDown_wellBelowBand() {
        let result = WeeklySummaryCalculator.content(
            currentWeekGrams: 80,
            priorWeekGrams: 100,
            hasAnyPriorWeekData: true
        )
        #expect(result == .percentage(fraction: -0.2, direction: .down))
    }

    @Test func content_percentageSame_atExactlyPositiveFivePercentBoundary() {
        let result = WeeklySummaryCalculator.content(
            currentWeekGrams: 105,
            priorWeekGrams: 100,
            hasAnyPriorWeekData: true
        )
        #expect(result == .percentage(fraction: 0.05, direction: .same))
    }

    @Test func content_percentageSame_atExactlyNegativeFivePercentBoundary() {
        let result = WeeklySummaryCalculator.content(
            currentWeekGrams: 95,
            priorWeekGrams: 100,
            hasAnyPriorWeekData: true
        )
        #expect(result == .percentage(fraction: -0.05, direction: .same))
    }

    // MARK: - Current week zero, prior week positive (still a percentage, not directionOnly)

    @Test func content_percentageDown_whenCurrentWeekIsZero_priorWeekPositive() {
        let result = WeeklySummaryCalculator.content(
            currentWeekGrams: 0,
            priorWeekGrams: 50,
            hasAnyPriorWeekData: true
        )
        #expect(result == .percentage(fraction: -1.0, direction: .down))
    }

    // MARK: - Large delta safety

    @Test func content_percentageUp_handlesLargeDelta_withoutOverflowOrCrash() {
        let result = WeeklySummaryCalculator.content(
            currentWeekGrams: 600,
            priorWeekGrams: 1,
            hasAnyPriorWeekData: true
        )
        #expect(result == .percentage(fraction: 599.0, direction: .up))
    }
}
