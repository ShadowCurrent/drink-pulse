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
        // 1 UK unit = 8.0 g (10 ml × 0.8)
        // 20 g / 8.0 = 2.5
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
}
