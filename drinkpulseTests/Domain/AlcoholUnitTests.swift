import Testing
import Foundation
@testable import drinkpulse

struct AlcoholUnitTests {

    // MARK: - Cases (plan-0029: exactly grams + standardDrinks)

    @Test func allCases_areGramsAndStandardDrinks() {
        #expect(Set(AlcoholUnit.allCases) == Set([.grams, .standardDrinks]))
    }

    // MARK: - unitLabel(for:)

    @Test func unitLabel_allCases_nonEmpty() {
        for unit in AlcoholUnit.allCases {
            for guideline in GuidelineChoice.allCases {
                #expect(!unit.unitLabel(for: guideline).isEmpty,
                        "unitLabel is empty for \(unit) / \(guideline)")
            }
        }
    }

    @Test func unitLabel_grams_isAlwaysGrams() {
        for guideline in GuidelineChoice.allCases {
            #expect(AlcoholUnit.grams.unitLabel(for: guideline) == String(localized: "unit.g"))
        }
    }

    @Test func unitLabel_standardDrinks_uk_readsUnits() {
        // Sub-decision #1: UK reads "units" in standard-drinks mode.
        #expect(AlcoholUnit.standardDrinks.unitLabel(for: .uk) == String(localized: "unit.units"))
    }

    @Test func unitLabel_standardDrinks_nonUK_readsStandardDrinks() {
        for guideline in GuidelineChoice.allCases where guideline != .uk {
            #expect(AlcoholUnit.standardDrinks.unitLabel(for: guideline)
                    == String(localized: "unit.standardDrinks"),
                    "non-UK guideline \(guideline) should read 'standard drinks'")
        }
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

    @Test func displayName_standardDrinks_matchesLocalizedKey() {
        #expect(AlcoholUnit.standardDrinks.displayName == String(localized: "settings.alcoholUnit.standardDrinks"))
    }

    // MARK: - Decode migration (plan-0029): retired "units" and unknown raw → standardDrinks

    private func decode(_ raw: String) throws -> AlcoholUnit {
        let json = Data("\"\(raw)\"".utf8)
        return try JSONDecoder().decode(AlcoholUnit.self, from: json)
    }

    @Test func decode_units_mapsToStandardDrinks() throws {
        #expect(try decode("units") == .standardDrinks)
    }

    @Test func decode_unknownRaw_mapsToStandardDrinks() throws {
        #expect(try decode("wibble") == .standardDrinks)
    }

    @Test func decode_knownRaws_roundTrip() throws {
        #expect(try decode("grams") == .grams)
        #expect(try decode("standardDrinks") == .standardDrinks)
    }
}
