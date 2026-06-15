import Testing
@testable import drinkpulse

struct GuidelineLimitsTests {

    // MARK: - WHO

    @Test func whoMaleLimits() {
        // WHO assumes 2 alcohol-free days per week → weekly = daily × 5 (not × 7).
        let l = GuidelineChoice.who.limits(for: .male)
        #expect(l.dailyGrams == 20)
        #expect(l.weeklyGrams == 100)
    }

    @Test func whoFemaleLimits() {
        let l = GuidelineChoice.who.limits(for: .female)
        #expect(l.dailyGrams == 10)
        #expect(l.weeklyGrams == 50)
    }

    /// Regression guard: weekly must be daily×5 (100), never daily×7 (140).
    /// Guards against re-introducing the pre-plan-0028 bug.
    @Test func whoMaleWeekly_is100_notDailyTimesSeven() {
        let l = GuidelineChoice.who.limits(for: .male)
        #expect(l.weeklyGrams == 100, "WHO male weekly must be 100 g (daily×5); got \(l.weeklyGrams)")
        #expect(l.weeklyGrams != 140, "WHO male weekly must NOT be 140 g (the old daily×7 value)")
    }

    // MARK: - Germany (DHS)

    @Test func deMaleLimits() {
        // DHS: same 2-free-day convention as WHO → weekly = daily × 5.
        let l = GuidelineChoice.de.limits(for: .male)
        #expect(l.dailyGrams == 24)
        #expect(l.weeklyGrams == 120)
    }

    @Test func deFemaleLimits() {
        let l = GuidelineChoice.de.limits(for: .female)
        #expect(l.dailyGrams == 12)
        #expect(l.weeklyGrams == 60)
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
        // 14 units × 8.0 g/unit (10 ml × 0.8 display density) = 112 g — see plan-0025.
        let l = GuidelineChoice.uk.limits(for: .female)
        #expect(l.weeklyGrams == 112)
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

    // MARK: - Australia (NHMRC 2020)

    @Test func auMaleLimits() {
        // NHMRC 2020: ≤4 std drinks/day & ≤10/week; 1 AU std drink = 10 g.
        // Both limits independent; same for both sexes.
        let l = GuidelineChoice.au.limits(for: .male)
        #expect(l.dailyGrams  == 40)
        #expect(l.weeklyGrams == 100)
    }

    @Test func auFemaleLimits() {
        let l = GuidelineChoice.au.limits(for: .female)
        #expect(l.dailyGrams  == 40)
        #expect(l.weeklyGrams == 100)
    }

    @Test func auSameLimitsForBothSexes() {
        let male   = GuidelineChoice.au.limits(for: .male)
        let female = GuidelineChoice.au.limits(for: .female)
        #expect(male.dailyGrams   == female.dailyGrams)
        #expect(male.weeklyGrams  == female.weeklyGrams)
    }

    @Test func auEffectiveDailyGrams_usesPublishedDaily() {
        // AU supplies a real daily limit (40 g), so effectiveDailyGrams must
        // return 40, NOT fall back to weeklyGrams/7 = 100/7 ≈ 14.3.
        let l = GuidelineChoice.au.limits(for: .male)
        #expect(l.effectiveDailyGrams == 40)
    }

    // MARK: - Canada (Health Canada LRDG-2011)

    @Test func caMaleLimits() {
        // Health Canada: 3 std drinks/day, 15/week; 1 CA std drink = 13.45 g.
        let l = GuidelineChoice.ca.limits(for: .male)
        #expect(abs(l.dailyGrams  - 3 * 13.45) < 0.001)
        #expect(abs(l.weeklyGrams - 15 * 13.45) < 0.001)
    }

    @Test func caFemaleLimits() {
        // Health Canada: 2 std drinks/day, 10/week.
        let l = GuidelineChoice.ca.limits(for: .female)
        #expect(abs(l.dailyGrams  - 2 * 13.45) < 0.001)
        #expect(abs(l.weeklyGrams - 10 * 13.45) < 0.001)
    }

    @Test func caMaleLimitsExactGrams() {
        // Concrete values: 40.35 g/day, 201.75 g/week.
        let l = GuidelineChoice.ca.limits(for: .male)
        #expect(abs(l.dailyGrams  - 40.35) < 0.001)
        #expect(abs(l.weeklyGrams - 201.75) < 0.001)
    }

    @Test func caFemaleLimitsExactGrams() {
        // Concrete values: 26.9 g/day, 134.5 g/week.
        let l = GuidelineChoice.ca.limits(for: .female)
        #expect(abs(l.dailyGrams  - 26.9) < 0.001)
        #expect(abs(l.weeklyGrams - 134.5) < 0.001)
    }

    @Test func caEffectiveDailyGrams_usesPublishedDaily() {
        // CA supplies a real daily limit, so effectiveDailyGrams must NOT fall back.
        let lMale   = GuidelineChoice.ca.limits(for: .male)
        let lFemale = GuidelineChoice.ca.limits(for: .female)
        #expect(abs(lMale.effectiveDailyGrams   - 40.35) < 0.001)
        #expect(abs(lFemale.effectiveDailyGrams - 26.9)  < 0.001)
    }

    @Test func caEffectiveLimits_resolveCorrectly() {
        // effectiveLimits must pass through the raw CA limits unchanged (not custom).
        let resolved = GuidelineChoice.ca.effectiveLimits(weeklyGoalGrams: 999, for: .male)
        #expect(abs(resolved.dailyGrams  - 40.35) < 0.001)
        #expect(abs(resolved.weeklyGrams - 201.75) < 0.001)
    }

    @Test func auEffectiveLimits_resolveCorrectly() {
        let resolved = GuidelineChoice.au.effectiveLimits(weeklyGoalGrams: 999, for: .female)
        #expect(resolved.dailyGrams  == 40)
        #expect(resolved.weeklyGrams == 100)
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
