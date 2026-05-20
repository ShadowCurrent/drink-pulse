import Testing
@testable import drinkpulse

struct AlcoholUnitTests {

    // MARK: - unitLabel

    @Test func unitLabel_allCases_nonEmpty() {
        for unit in AlcoholUnit.allCases {
            #expect(!unit.unitLabel.isEmpty, "unitLabel is empty for \(unit)")
        }
    }

    @Test func unitLabel_grams_matchesLocalizedKey() {
        #expect(AlcoholUnit.grams.unitLabel == String(localized: "unit.g"))
    }

    @Test func unitLabel_units_matchesLocalizedKey() {
        #expect(AlcoholUnit.units.unitLabel == String(localized: "unit.units"))
    }

    @Test func unitLabel_standardDrinks_matchesLocalizedKey() {
        #expect(AlcoholUnit.standardDrinks.unitLabel == String(localized: "unit.standardDrinks"))
    }

    // MARK: - displayName

    @Test func displayName_allCases_nonEmpty() {
        for unit in AlcoholUnit.allCases {
            #expect(!unit.displayName.isEmpty, "displayName is empty for \(unit)")
        }
    }

    @Test func displayName_allCases_distinct() {
        let names = AlcoholUnit.allCases.map(\.displayName)
        #expect(Set(names).count == names.count, "Duplicate displayName values detected")
    }

    @Test func displayName_grams_matchesLocalizedKey() {
        #expect(AlcoholUnit.grams.displayName == String(localized: "settings.alcoholUnit.grams"))
    }

    @Test func displayName_units_matchesLocalizedKey() {
        #expect(AlcoholUnit.units.displayName == String(localized: "settings.alcoholUnit.units"))
    }

    @Test func displayName_standardDrinks_matchesLocalizedKey() {
        #expect(AlcoholUnit.standardDrinks.displayName == String(localized: "settings.alcoholUnit.standardDrinks"))
    }
}
