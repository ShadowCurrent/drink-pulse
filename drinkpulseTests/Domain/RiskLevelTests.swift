import Testing
@testable import drinkpulse

struct RiskLevelTests {

    // MARK: - .safe region (pct < 0.5)

    @Test func from_pct_zero_isSafe() {
        #expect(RiskLevel.from(pct: 0.0) == .safe)
    }

    @Test func from_pct_negative_isSafe() {
        #expect(RiskLevel.from(pct: -1.0) == .safe)
    }

    @Test func from_pct_belowBoundary_isSafe() {
        // 0.499... is strictly below 0.5 → safe
        #expect(RiskLevel.from(pct: 0.499) == .safe)
    }

    // MARK: - .caution region (0.5 ≤ pct ≤ 1.0)

    @Test func from_pct_exactlyLowerBoundary_isCaution() {
        // pct == 0.5 is the lower inclusive boundary
        #expect(RiskLevel.from(pct: 0.5) == .caution)
    }

    @Test func from_pct_midRange_isCaution() {
        #expect(RiskLevel.from(pct: 0.75) == .caution)
    }

    @Test func from_pct_exactlyUpperBoundary_isCaution() {
        // pct == 1.0 is the upper inclusive boundary
        #expect(RiskLevel.from(pct: 1.0) == .caution)
    }

    // MARK: - .exceeded region (pct > 1.0)

    @Test func from_pct_justAboveUpperBoundary_isExceeded() {
        // 1.001 is just above the 1.0 upper boundary
        #expect(RiskLevel.from(pct: 1.001) == .exceeded)
    }

    @Test func from_pct_largeValue_isExceeded() {
        #expect(RiskLevel.from(pct: 5.0) == .exceeded)
    }
}
