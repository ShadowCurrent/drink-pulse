import Testing
@testable import drinkpulse

@Suite struct CardMetricsTests {

    /// 24 pt matches the iOS 27 inset-grouped List section corner (owner choice, prototype
    /// FINDINGS round 11, measured in renders). It is not a system-provided value: re-check it
    /// after each major iOS release. 16 pt is the GroupBox content padding.
    @Test func test_cardMetrics_matchListSectionCorner() {
        #expect(CardMetrics.cornerRadius == 24)
        #expect(CardMetrics.padding == 16)
    }
}
