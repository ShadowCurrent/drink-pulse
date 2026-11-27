import Testing
@testable import drinkpulse

/// Limit gauge fraction (plan 0046, D0046-5; Review focus 2): a profile without a daily limit
/// must not divide by zero.
@Suite struct LimitGaugeRowTests {

    @Test func test_fraction_isZero_whenLimitIsZero() {
        #expect(LimitGaugeRow.fraction(consumed: 20, limit: 0) == 0)
    }

    @Test func test_fraction_exceedsOne_whenOverLimit() {
        #expect(LimitGaugeRow.fraction(consumed: 30, limit: 20) == 1.5)
    }

    @Test func test_fraction_isRatio_underLimit() {
        #expect(LimitGaugeRow.fraction(consumed: 10, limit: 20) == 0.5)
    }
}
