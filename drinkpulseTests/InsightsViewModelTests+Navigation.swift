import Testing
import Foundation
@testable import drinkpulse

@MainActor
extension InsightsViewModelTests {

    // MARK: - InsightsPeriod navigation

    @Test func period_navigatePrev_decreasesOffset() {
        let vm = makeVM()
        vm.period = .week
        vm.navigatePrev()
        #expect(vm.weekOffset == -1)
    }

    @Test func period_navigateNext_doesNothingAtCurrentPeriod() {
        let vm = makeVM()
        vm.period = .week
        vm.navigateNext()
        #expect(vm.weekOffset == 0)
    }

    @Test func period_jumpToNow_resetsOffset() {
        let vm = makeVM()
        vm.period = .week
        vm.navigatePrev()
        vm.navigatePrev()
        vm.jumpToNow()
        #expect(vm.weekOffset == 0)
        #expect(vm.isCurrentPeriod)
    }

    @Test func period_independentOffsets_preservedAcrossScopeSwitch() {
        let vm = makeVM()
        vm.period = .week
        vm.navigatePrev()
        vm.navigatePrev()
        vm.period = .month
        vm.navigatePrev()
        vm.period = .week
        #expect(vm.weekOffset == -2)
        #expect(vm.monthOffset == -1)
    }

    @Test func period_cannotNavigateBeyondMinOffset() {
        let vm = makeVM()
        vm.period = .year
        for _ in 0..<10 {
            vm.navigatePrev()
        }
        #expect(vm.yearOffset == InsightsPeriod.year.minOffset)
    }

    @Test func period_navigateNext_increasesOffset_whenNegative() {
        let vm = makeVM()
        vm.period = .week
        vm.navigatePrev()
        vm.navigateNext()
        #expect(vm.weekOffset == 0)
        #expect(vm.isCurrentPeriod)
    }

    // MARK: - friendlyLabel / rangeLabel

    @Test func friendlyLabel_currentAndPrevPeriodDiffer() {
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        let current = vm.friendlyLabel
        vm.navigatePrev()
        let prev = vm.friendlyLabel
        #expect(current != prev)
    }

    @Test func rangeLabel_weekContainsDash() {
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        #expect(vm.rangeLabel.contains("\u{2013}"))
    }

    // MARK: - formattedValue / formattedSpend

    @Test func formattedValue_noProfile_returnsGramsString() {
        let vm = makeVM()
        #expect(vm.formattedValue(42.0) == "42 g")
    }

    @Test func formattedSpend_noProfile_nonEmpty() {
        let vm = makeVM()
        #expect(!vm.formattedSpend(5.0).isEmpty)
    }
}
