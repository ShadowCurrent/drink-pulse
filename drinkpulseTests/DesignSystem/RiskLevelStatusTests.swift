import Testing
@testable import drinkpulse

/// Risk status copy and glyph (plan 0046, D0046-3 / D0046-15). Thresholds stay in
/// `RiskLevel.from(pct:)`; only the labels and symbols live here.
@Suite struct RiskLevelStatusTests {

    @Test func test_statusTitle_mapsEveryLevel() {
        #expect(RiskLevel.safe.statusTitle == "Within Limit")
        #expect(RiskLevel.caution.statusTitle == "Close to Limit")
        #expect(RiskLevel.exceeded.statusTitle == "Over Limit")
    }

    @Test func test_statusSymbol_mapsEveryLevel() {
        #expect(RiskLevel.safe.statusSymbol == "checkmark.circle.fill")
        #expect(RiskLevel.caution.statusSymbol == "exclamationmark.circle.fill")
        #expect(RiskLevel.exceeded.statusSymbol == "exclamationmark.triangle.fill")
    }
}
