import Testing
@testable import drinkpulse

@MainActor
@Suite struct WithMotionTests {

    @Test func test_withMotion_runsChangeOnce_whenMotionAllowed() {
        var count = 0
        withMotion(reduceMotion: false) { count += 1 }
        #expect(count == 1)
    }

    @Test func test_withMotion_runsChangeOnce_whenReduceMotion() {
        var count = 0
        withMotion(reduceMotion: true) { count += 1 }
        #expect(count == 1)
    }
}
