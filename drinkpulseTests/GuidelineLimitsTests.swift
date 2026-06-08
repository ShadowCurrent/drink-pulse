import Testing
@testable import drinkpulse

struct GuidelineLimitsTests {

    // MARK: - WHO

    @Test func whoMaleLimits() {
        let l = GuidelineChoice.who.limits(for: .male)
        #expect(l.dailyGrams == 20)
        #expect(l.weeklyGrams == 100)
    }

    @Test func whoFemaleLimits() {
        let l = GuidelineChoice.who.limits(for: .female)
        #expect(l.dailyGrams == 10)
        #expect(l.weeklyGrams == 70)
    }

    // MARK: - Germany (DHS)

    @Test func deMaleLimits() {
        let l = GuidelineChoice.de.limits(for: .male)
        #expect(l.dailyGrams == 24)
        #expect(l.weeklyGrams == 168)
    }

    @Test func deFemaleLimits() {
        let l = GuidelineChoice.de.limits(for: .female)
        #expect(l.dailyGrams == 12)
        #expect(l.weeklyGrams == 84)
    }

    @Test func deFemaleIsHalfOfMale() {
        let male   = GuidelineChoice.de.limits(for: .male)
        let female = GuidelineChoice.de.limits(for: .female)
        #expect(female.dailyGrams  == male.dailyGrams  / 2)
        #expect(female.weeklyGrams == male.weeklyGrams / 2)
    }

    // MARK: - UK (NHS) — same for both sexes

    @Test func ukSameLimitsForBothSexes() {
        let male   = GuidelineChoice.uk.limits(for: .male)
        let female = GuidelineChoice.uk.limits(for: .female)
        #expect(male.dailyGrams   == female.dailyGrams)
        #expect(male.weeklyGrams  == female.weeklyGrams)
    }

    @Test func ukNoDailyLimit() {
        let l = GuidelineChoice.uk.limits(for: .male)
        #expect(l.dailyGrams == 0)
    }

    @Test func ukWeeklyLimit() {
        // 14 units × 10 ml × 0.789 g/ml = 110.46 g
        let l = GuidelineChoice.uk.limits(for: .female)
        #expect(l.weeklyGrams == 110.46)
    }

    // MARK: - US (NIAAA)

    @Test func usMaleLimits() {
        let l = GuidelineChoice.us.limits(for: .male)
        #expect(l.dailyGrams  == 28)
        #expect(l.weeklyGrams == 196)
    }

    @Test func usFemaleLimits() {
        let l = GuidelineChoice.us.limits(for: .female)
        #expect(l.dailyGrams  == 14)
        #expect(l.weeklyGrams == 98)
    }

    // MARK: - Custom

    @Test func customReturnsZeroSentinel() {
        let l = GuidelineChoice.custom.limits(for: .male)
        #expect(l.dailyGrams  == 0)
        #expect(l.weeklyGrams == 0)
    }

    // MARK: - effectiveDailyGrams

    @Test func effectiveDailyGrams_usesDailyWhenNonZero() {
        let l = GuidelineLimits(dailyGrams: 20, weeklyGrams: 100)
        #expect(l.effectiveDailyGrams == 20)
    }

    @Test func effectiveDailyGrams_fallsBackToWeeklyOver7_whenNoDaily() {
        let l = GuidelineLimits(dailyGrams: 0, weeklyGrams: 110.46)
        #expect(abs(l.effectiveDailyGrams - 110.46 / 7) < 0.0001)
    }

    // MARK: - effectiveLimits resolver

    @Test func effectiveLimits_nonCustom_matchesRawLimits() {
        let raw = GuidelineChoice.who.limits(for: .female)
        let resolved = GuidelineChoice.who.effectiveLimits(weeklyGoalGrams: 999, for: .female)
        #expect(resolved.dailyGrams == raw.dailyGrams)
        #expect(resolved.weeklyGrams == raw.weeklyGrams)
    }

    @Test func effectiveLimits_custom_usesWeeklyGoal() {
        let l = GuidelineChoice.custom.effectiveLimits(weeklyGoalGrams: 140, for: .male)
        #expect(l.weeklyGrams == 140)
        #expect(abs(l.dailyGrams - 140.0 / 7) < 0.0001)
        // Custom must yield a usable (non-zero) daily limit — the History bug.
        #expect(l.effectiveDailyGrams > 0)
    }

    @Test func effectiveLimits_custom_clampsZeroGoalToOne() {
        let l = GuidelineChoice.custom.effectiveLimits(weeklyGoalGrams: 0, for: .male)
        #expect(l.weeklyGrams == 1.0)
        #expect(l.effectiveDailyGrams > 0)
    }
}
