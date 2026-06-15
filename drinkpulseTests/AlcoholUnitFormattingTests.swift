import Testing
@testable import drinkpulse

/// Tests for AlcoholUnit.formattedValue — verifies guideline-aware conversion.
struct AlcoholUnitFormattingTests {

    // MARK: - Grams (always direct)

    @Test func gramsFormatsDirectly() {
        #expect(AlcoholUnit.grams.formattedValue(20.0, guideline: .who) == "20.0")
    }

    @Test func gramsOneDecimalPlace() {
        #expect(AlcoholUnit.grams.formattedValue(19.5, guideline: .de) == "19.5")
    }

    // MARK: - UK Units (gramsPerUnit varies by guideline)

    @Test func ukUnitsWithUKGuideline() {
        // 1 UK unit = 8.0 g (10 ml × 0.8 display density); 20.0 g / 8.0 = 2.5 → "2.5"
        #expect(AlcoholUnit.units.formattedValue(20.0, guideline: .uk) == "2.5")
    }

    @Test func ukUnitsWithWHOGuideline() {
        // WHO/DE/custom: 10 g/unit
        // 20 g / 10.0 = 2.0
        #expect(AlcoholUnit.units.formattedValue(20.0, guideline: .who) == "2.0")
    }

    @Test func ukUnitsWithDEGuideline() {
        // DE: 10 g/unit
        #expect(AlcoholUnit.units.formattedValue(20.0, guideline: .de) == "2.0")
    }

    @Test func ukUnitsWithUSGuideline() {
        // US: 14 g/drink
        // 28 g / 14.0 = 2.0
        #expect(AlcoholUnit.units.formattedValue(28.0, guideline: .us) == "2.0")
    }

    // MARK: - Standard Drinks

    @Test func standardDrinksNonUS() {
        // WHO/DE/UK: 10 g/drink
        // 20 g / 10.0 = 2.0
        #expect(AlcoholUnit.standardDrinks.formattedValue(20.0, guideline: .who) == "2.0")
        #expect(AlcoholUnit.standardDrinks.formattedValue(20.0, guideline: .de)  == "2.0")
        #expect(AlcoholUnit.standardDrinks.formattedValue(20.0, guideline: .uk)  == "2.0")
    }

    @Test func standardDrinksUS() {
        // US: 14 g/drink
        // 28 g / 14.0 = 2.0
        #expect(AlcoholUnit.standardDrinks.formattedValue(28.0, guideline: .us) == "2.0")
    }

    @Test func standardDrinksUSVsWHO() {
        // Same 20 g gives different counts: WHO = 2.0, US = 1.4
        #expect(AlcoholUnit.standardDrinks.formattedValue(20.0, guideline: .who) == "2.0")
        #expect(AlcoholUnit.standardDrinks.formattedValue(20.0, guideline: .us)  == "1.4")
    }

    // MARK: - Zero

    @Test func zeroGramsForAllUnits() {
        for guideline in GuidelineChoice.allCases {
            #expect(AlcoholUnit.grams.formattedValue(0, guideline: guideline)         == "0.0")
            #expect(AlcoholUnit.units.formattedValue(0, guideline: guideline)         == "0.0")
            #expect(AlcoholUnit.standardDrinks.formattedValue(0, guideline: guideline) == "0.0")
        }
    }

    // MARK: - gramsPerUnit

    @Test func gramsPerUnit_values() {
        #expect(AlcoholUnit.grams.gramsPerUnit(for: .who) == 1.0)
        #expect(AlcoholUnit.units.gramsPerUnit(for: .uk)  == 8.0)
        #expect(AlcoholUnit.units.gramsPerUnit(for: .us)  == 14.0)
        #expect(AlcoholUnit.units.gramsPerUnit(for: .who) == 10.0)
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .us)  == 14.0)
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .who) == 10.0)
    }

    @Test func gramsPerUnit_au_is10ForBothUnitModes() {
        // NHMRC standard drink = 10 g; same as European WHO/DE standard.
        #expect(AlcoholUnit.units.gramsPerUnit(for: .au)         == 10.0)
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .au) == 10.0)
    }

    @Test func gramsPerUnit_ca_is13point45ForBothUnitModes() {
        // Health Canada standard drink = 13.45 g (341 ml × 5% × 0.789).
        #expect(AlcoholUnit.units.gramsPerUnit(for: .ca)         == 13.45)
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .ca) == 13.45)
    }

    @Test func gramsPerUnit_ca_formattedStandardDrink() {
        // 13.45 g / 13.45 g per drink = 1.0 drink
        #expect(AlcoholUnit.standardDrinks.formattedValue(13.45, guideline: .ca) == "1.0")
    }

    @Test func gramsPerUnit_au_formattedStandardDrink() {
        // 10.0 g / 10.0 g per drink = 1.0 drink
        #expect(AlcoholUnit.standardDrinks.formattedValue(10.0, guideline: .au) == "1.0")
    }

    // MARK: - densityGramsPerMl (display-unit dependent — plan-0025)

    @Test func densityGramsPerMl_values() {
        #expect(AlcoholUnit.grams.densityGramsPerMl == 0.789)
        #expect(AlcoholUnit.units.densityGramsPerMl == 0.8)
        #expect(AlcoholUnit.standardDrinks.densityGramsPerMl == 0.789)
        #expect(AlcoholUnit.physicalDensityGramsPerMl == 0.789)
    }
}
