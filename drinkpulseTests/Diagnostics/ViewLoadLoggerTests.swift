import Testing
@testable import drinkpulse

struct ViewLoadLoggerTests {
    @Test
    func milliseconds_wholeSecond_returnsThousand() {
        #expect(ViewLoadLogger.milliseconds(.seconds(1)) == 1000)
    }

    @Test
    func milliseconds_wholeMilliseconds_returnsExactCount() {
        #expect(ViewLoadLogger.milliseconds(.milliseconds(250)) == 250)
    }

    @Test
    func milliseconds_zero_returnsZero() {
        #expect(ViewLoadLogger.milliseconds(.zero) == 0)
    }

    @Test
    func milliseconds_subMillisecond_truncatesDownToZero() {
        #expect(ViewLoadLogger.milliseconds(.microseconds(500)) == 0)
    }
}
