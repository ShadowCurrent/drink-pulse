import Testing
@testable import drinkpulse

/// Tests for AlcoholUnit conversion: density (mode × guideline), grams-per-unit,
/// and formattedValue. Target numbers hand-verified in plan-0029 / ADR-0006.
struct AlcoholUnitFormattingTests {

    // MARK: - density(for:) — mode × guideline (plan-0029 / ADR-0006)

    @Test func density_grams_is0789_forAllGuidelines() {
        for guideline in GuidelineChoice.allCases {
            #expect(AlcoholUnit.grams.density(for: guideline) == 0.789,
                    ".grams must always use physical 0.789 (\(guideline))")
        }
    }

    @Test func density_standardDrinks_usAndCa_is0789() {
        #expect(AlcoholUnit.standardDrinks.density(for: .us) == 0.789)
        #expect(AlcoholUnit.standardDrinks.density(for: .ca) == 0.789)
    }

    @Test func density_standardDrinks_euAndUk_is08() {
        for guideline in [GuidelineChoice.who, .de, .uk, .au, .custom] {
            #expect(AlcoholUnit.standardDrinks.density(for: guideline) == 0.8,
                    "EU/UK std-drinks density should be 0.8 (\(guideline))")
        }
    }

    @Test func physicalDensity_is0789() {
        #expect(AlcoholUnit.physicalDensityGramsPerMl == 0.789)
    }

    // MARK: - Canonical reference drinks in std-drinks mode (the target table)

    /// Mass of a single portion in the given mode/guideline, then formatted to the unit.
    private func formatted(volumeMl: Double, abv: Double,
                           unit: AlcoholUnit, guideline: GuidelineChoice) -> String {
        let grams = volumeMl * abv * unit.density(for: guideline)
        return unit.formattedValue(grams, guideline: guideline)
    }

    @Test func stdDrinks_euBeer_500ml5pct_reads2point0() {
        // WHO/DE/AU: 500 ml × 5 % × 0.8 = 20.0 g; 20 / 10 = 2.00
        for guideline in [GuidelineChoice.who, .de, .au] {
            #expect(formatted(volumeMl: 500, abv: 0.05, unit: .standardDrinks, guideline: guideline) == "2.0")
        }
    }

    @Test func stdDrinks_ukBeer_500ml5pct_reads2point5() {
        // UK: 500 ml × 5 % × 0.8 = 20.0 g; 20 / 8 = 2.50
        #expect(formatted(volumeMl: 500, abv: 0.05, unit: .standardDrinks, guideline: .uk) == "2.5")
    }

    @Test func stdDrinks_usReferenceBeer_355ml5pct_reads1point0() {
        // US: 355 ml × 5 % × 0.789 = 14.0 g; 14 / 14 = 1.00
        #expect(formatted(volumeMl: 355, abv: 0.05, unit: .standardDrinks, guideline: .us) == "1.0")
    }

    @Test func stdDrinks_caReferenceBeer_341ml5pct_reads1point0() {
        // CA: 341 ml × 5 % × 0.789 = 13.45 g; 13.45 / 13.45 = 1.00
        #expect(formatted(volumeMl: 341, abv: 0.05, unit: .standardDrinks, guideline: .ca) == "1.0")
    }

    @Test func gramsMode_beer_500ml5pct_reads19point7_forAllGuidelines() {
        for guideline in GuidelineChoice.allCases {
            // 500 ml × 5 % × 0.789 = 19.725 g
            #expect(formatted(volumeMl: 500, abv: 0.05, unit: .grams, guideline: guideline) == "19.7")
        }
    }

    // MARK: - Grams (always direct)

    @Test func gramsFormatsDirectly() {
        #expect(AlcoholUnit.grams.formattedValue(20.0, guideline: .who) == "20.0")
    }

    @Test func gramsOneDecimalPlace() {
        #expect(AlcoholUnit.grams.formattedValue(19.5, guideline: .de) == "19.5")
    }

    // MARK: - Standard Drinks formattedValue (gramsPerUnit varies by guideline)

    @Test func standardDrinks_uk_8gPerUnit() {
        // 20.0 g / 8.0 = 2.5
        #expect(AlcoholUnit.standardDrinks.formattedValue(20.0, guideline: .uk) == "2.5")
    }

    @Test func standardDrinks_euGuidelines_10gPerDrink() {
        #expect(AlcoholUnit.standardDrinks.formattedValue(20.0, guideline: .who) == "2.0")
        #expect(AlcoholUnit.standardDrinks.formattedValue(20.0, guideline: .de)  == "2.0")
        #expect(AlcoholUnit.standardDrinks.formattedValue(20.0, guideline: .au)  == "2.0")
    }

    @Test func standardDrinks_us_14gPerDrink() {
        #expect(AlcoholUnit.standardDrinks.formattedValue(28.0, guideline: .us) == "2.0")
    }

    @Test func standardDrinks_usVsWHO() {
        // Same 20 g gives different counts: WHO = 2.0, US = 1.4
        #expect(AlcoholUnit.standardDrinks.formattedValue(20.0, guideline: .who) == "2.0")
        #expect(AlcoholUnit.standardDrinks.formattedValue(20.0, guideline: .us)  == "1.4")
    }

    // MARK: - Zero

    @Test func zeroGramsForAllUnits() {
        for guideline in GuidelineChoice.allCases {
            #expect(AlcoholUnit.grams.formattedValue(0, guideline: guideline)          == "0.0")
            #expect(AlcoholUnit.standardDrinks.formattedValue(0, guideline: guideline) == "0.0")
        }
    }

    // MARK: - gramsPerUnit

    @Test func gramsPerUnit_grams_isIdentity() {
        for guideline in GuidelineChoice.allCases {
            #expect(AlcoholUnit.grams.gramsPerUnit(for: guideline) == 1.0)
        }
    }

    @Test func gramsPerUnit_standardDrinks_values() {
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .uk)     == 8.0)
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .us)     == 14.0)
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .ca)     == 13.45)
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .who)    == 10.0)
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .de)     == 10.0)
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .au)     == 10.0)
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .custom) == 10.0)
    }

    @Test func gramsPerUnit_ca_formattedStandardDrink() {
        #expect(AlcoholUnit.standardDrinks.formattedValue(13.45, guideline: .ca) == "1.0")
    }

    @Test func gramsPerUnit_au_formattedStandardDrink() {
        #expect(AlcoholUnit.standardDrinks.formattedValue(10.0, guideline: .au) == "1.0")
    }

    // MARK: - Guideline limits rendered in standard drinks (plan-0029 target table)

    private func dailyDrinks(_ guideline: GuidelineChoice, sex: BiologicalSex) -> String {
        AlcoholUnit.standardDrinks.formattedValue(guideline.limits(for: sex).dailyGrams, guideline: guideline)
    }

    private func weeklyDrinks(_ guideline: GuidelineChoice, sex: BiologicalSex) -> String {
        AlcoholUnit.standardDrinks.formattedValue(guideline.limits(for: sex).weeklyGrams, guideline: guideline)
    }

    @Test func limits_who_male_dailyAndWeeklyInDrinks() {
        // 20 g daily / 10 = 2.0; 100 g weekly / 10 = 10.0
        #expect(dailyDrinks(.who, sex: .male)  == "2.0")
        #expect(weeklyDrinks(.who, sex: .male) == "10.0")
    }

    @Test func limits_de_male_dailyAndWeeklyInDrinks() {
        // 24 g / 10 = 2.4; 120 g / 10 = 12.0
        #expect(dailyDrinks(.de, sex: .male)  == "2.4")
        #expect(weeklyDrinks(.de, sex: .male) == "12.0")
    }

    @Test func limits_au_dailyAndWeeklyInDrinks() {
        // 40 g / 10 = 4.0; 100 g / 10 = 10.0
        #expect(dailyDrinks(.au, sex: .male)  == "4.0")
        #expect(weeklyDrinks(.au, sex: .male) == "10.0")
    }

    @Test func limits_uk_weeklyIs14Drinks() {
        // 112 g / 8 = 14.0 units
        #expect(weeklyDrinks(.uk, sex: .male) == "14.0")
    }

    @Test func limits_us_male_dailyAndWeeklyInDrinks() {
        // 28 g / 14 = 2.0; 196 g / 14 = 14.0
        #expect(dailyDrinks(.us, sex: .male)  == "2.0")
        #expect(weeklyDrinks(.us, sex: .male) == "14.0")
    }

    @Test func limits_ca_male_dailyAndWeeklyInDrinks() {
        // 40.35 g / 13.45 = 3.0; 201.75 g / 13.45 = 15.0
        #expect(dailyDrinks(.ca, sex: .male)  == "3.0")
        #expect(weeklyDrinks(.ca, sex: .male) == "15.0")
    }
}
