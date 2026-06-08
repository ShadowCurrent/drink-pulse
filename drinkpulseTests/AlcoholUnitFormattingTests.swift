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
        // 1 UK unit = 7.89 g (10 ml × 0.789); 20.0 g / 7.89 = 2.534… → "2.5"
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
        #expect(AlcoholUnit.units.gramsPerUnit(for: .uk)  == 7.89)
        #expect(AlcoholUnit.units.gramsPerUnit(for: .us)  == 14.0)
        #expect(AlcoholUnit.units.gramsPerUnit(for: .who) == 10.0)
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .us)  == 14.0)
        #expect(AlcoholUnit.standardDrinks.gramsPerUnit(for: .who) == 10.0)
    }

    // MARK: - displayValue (rounded numeric, agrees with formattedValue)

    @Test func displayValue_roundsToOneDecimal() {
        // 9.86 g / 10 = 0.986 -> rounds to 1.0, same as the "%.1f" string
        #expect(AlcoholUnit.units.displayValue(9.86, guideline: .who) == 1.0)
        #expect(AlcoholUnit.units.displayValue(20.0, guideline: .who) == 2.0)
        #expect(AlcoholUnit.grams.displayValue(19.5, guideline: .de)  == 19.5)
        // standard drinks: 10 g non-US, 14 g US
        #expect(AlcoholUnit.standardDrinks.displayValue(9.86, guideline: .who) == 1.0)
        #expect(AlcoholUnit.standardDrinks.displayValue(13.7, guideline: .us)  == 1.0)
    }

    @Test func displayValue_matchesFormattedValueString() {
        for g in [0.0, 9.86, 19.6, 20.0, 28.0] {
            #expect(String(format: "%.1f", AlcoholUnit.units.displayValue(g, guideline: .who))
                    == AlcoholUnit.units.formattedValue(g, guideline: .who))
        }
    }
}
