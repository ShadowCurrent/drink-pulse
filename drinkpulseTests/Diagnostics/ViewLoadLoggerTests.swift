import Testing
@testable import drinkpulse

/// Covers the one piece of non-trivial pure logic in `ViewLoadLogger`: the
/// whole-millisecond truncation of a `Duration`. The `os.Logger`/`OSSignposter`
/// call sites themselves are not unit-tested (CLAUDE.md: don't force tests onto
/// pure logging call sites).
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
