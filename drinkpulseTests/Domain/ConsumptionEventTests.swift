import Testing
import Foundation
@testable import drinkpulse

struct ConsumptionEventTests {

    // MARK: - displayName: customName override

    @Test func displayName_returnsCustomName_whenSet() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05,
                                     category: .beer, icon: "🍺", customName: "Tyskie")
        #expect(event.displayName(in: .metric) == "Tyskie")
    }

    @Test func displayName_trimsLeadingTrailingWhitespace() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05,
                                     category: .beer, icon: "🍺", customName: "  Tyskie  ")
        #expect(event.displayName(in: .metric) == "Tyskie")
    }

    @Test func displayName_preservesInternalWhitespace() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05,
                                     category: .beer, icon: "🍺", customName: "Tyskie Full")
        #expect(event.displayName(in: .metric) == "Tyskie Full")
    }

    // MARK: - displayName: derived from category + volume when customName absent

    @Test func displayName_derivedFromVolume_whenCustomNameIsNil() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05,
                                     category: .beer, icon: "🍺")
        #expect(event.displayName(in: .metric) == "Can")
    }

    @Test func displayName_derivedFromVolume_whenCustomNameIsEmpty() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05,
                                     category: .beer, icon: "🍺", customName: "")
        #expect(event.displayName(in: .metric) == "Can")
    }

    @Test func displayName_derivedFromVolume_whenCustomNameIsWhitespaceOnly() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05,
                                     category: .beer, icon: "🍺", customName: "   ")
        #expect(event.displayName(in: .metric) == "Can")
    }

    @Test func displayName_exactVolumeMatch_beer473_isUSPint() {
        // 473 ml = US "Pint" (16 oz). No enteredUnit → resolves via passed unit.
        let event = ConsumptionEvent(volumeMl: 473, abv: 0.05,
                                     category: .beer, icon: "🍺")
        #expect(event.displayName(in: .usCustomary) == "Pint")
    }

    @Test func displayName_exactVolumeMatch_beerPintUK() {
        let event = ConsumptionEvent(volumeMl: 568, abv: 0.05,
                                     category: .beer, icon: "🍺")
        #expect(event.displayName(in: .imperial) == "Pint")
    }

    @Test func displayName_perRegionName_568IsStovepipeInUS() {
        // The merged 568 ml option reads "Stovepipe" in US, "Pint" in metric/imperial.
        let event = ConsumptionEvent(volumeMl: 568, abv: 0.05,
                                     category: .beer, icon: "🍺")
        #expect(event.displayName(in: .usCustomary) == "Stovepipe")
    }

    @Test func displayName_orphanedVolume_fallsBackToFormatVolume() {
        // 490 ml is not a preset serving (no match within tolerance) → formatVolume.
        let event = ConsumptionEvent(volumeMl: 490, abv: 0.05,
                                     category: .beer, icon: "🍺")
        #expect(event.displayName(in: .metric) == "490 ml")
    }

    @Test func displayName_wineStandardGlass() {
        let event = ConsumptionEvent(volumeMl: 150, abv: 0.13,
                                     category: .wine, icon: "🍷")
        #expect(event.displayName(in: .metric) == "Standard")
    }

    @Test func displayName_customCategory_emptyDescriptor_fallsBackToFormatVolume() {
        // Custom preset options carry an empty descriptor → name resolution skips
        // them and falls back to formatVolume.
        let event = ConsumptionEvent(volumeMl: 250, abv: 0.05,
                                     category: .custom, icon: "🥤")
        #expect(event.displayName(in: .metric) == "250 ml")
    }

    // MARK: - displayName: provenance (enteredUnit, plan-0031 / ADR-0007)

    @Test func displayName_resolvesViaEnteredUnit_notCurrentProfile() {
        // Logged in imperial at 568 ml → "Pint". Even when the CURRENT profile unit
        // is US, the name stays "Pint" (not "Stovepipe") because provenance wins.
        let event = ConsumptionEvent(volumeMl: 568, abv: 0.05, enteredUnit: .imperial, category: .beer, icon: "🍺")
        #expect(event.displayName(in: .usCustomary) == "Pint")
        #expect(event.displayName(in: .metric) == "Pint")
    }

    @Test func displayName_enteredUnitUS_gives_StovepipeRegardlessOfProfile() {
        let event = ConsumptionEvent(volumeMl: 568, abv: 0.05, enteredUnit: .usCustomary, category: .beer, icon: "🍺")
        #expect(event.displayName(in: .imperial) == "Stovepipe")
    }

    @Test func displayName_nilEnteredUnit_fallsBackToCurrentProfileUnit() {
        let event = ConsumptionEvent(volumeMl: 568, abv: 0.05,
                                     category: .beer, icon: "🍺")
        #expect(event.displayName(in: .usCustomary) == "Stovepipe")
        #expect(event.displayName(in: .imperial) == "Pint")
    }

    // MARK: - displayName: quantity ×N (plan-0025)

    @Test func displayName_appendsQuantity_whenMoreThanOne() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, quantity: 10, category: .beer, icon: "🍺")
        #expect(event.displayName(in: .metric) == "Bottle ×10")
    }

    @Test func displayName_noQuantitySuffix_whenOne() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        #expect(event.displayName(in: .metric) == "Bottle")
    }

    @Test func displayName_customNameWithQuantity() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, quantity: 3, category: .beer, icon: "🍺", customName: "Tyskie")
        #expect(event.displayName(in: .metric) == "Tyskie ×3")
    }

    // MARK: - duplicated (plan-0026 + plan-0031 enteredUnit)

    @Test func duplicated_copiesEveryValueField() {
        let template = DrinkTemplate(name: "House Lager", category: .beer,
                                     defaultVolumeMl: 500, abv: 0.05, icon: "🍺", colorHex: "#C8A24B")
        let original = ConsumptionEvent(
            volumeMl: 500, abv: 0.052, quantity: 3, enteredUnit: .imperial,
            category: .beer, icon: "🍺", template: template,
            customName: "Tyskie", notes: "with dinner", price: 12.5, priceCurrency: "PLN"
        )

        let copy = original.duplicated()

        #expect(copy.priceCurrency == original.priceCurrency)
        #expect(copy.volumeMl == original.volumeMl)
        #expect(copy.abv == original.abv)
        #expect(copy.quantity == original.quantity)
        #expect(copy.enteredUnit == original.enteredUnit)
        // A duplicate is a distinct record: it must NOT share identity (plan-0023).
        #expect(copy.uuid != original.uuid)
        #expect(copy.category == original.category)
        #expect(copy.icon == original.icon)
        #expect(copy.customName == original.customName)
        #expect(copy.notes == original.notes)
        #expect(copy.price == original.price)
    }

    @Test func duplicated_preservesTemplateReference() {
        let template = DrinkTemplate(name: "House Lager", category: .beer,
                                     defaultVolumeMl: 500, abv: 0.05, icon: "🍺", colorHex: "#C8A24B")
        let original = ConsumptionEvent(volumeMl: 500, abv: 0.05,
                                        category: .beer, icon: "🍺", template: template)

        let copy = original.duplicated()

        #expect(copy.template === template)
    }

    @Test func duplicated_resetsTimestampToNowByDefault() {
        let lastYear = Date(timeIntervalSinceNow: -60 * 60 * 24 * 365)
        let original = ConsumptionEvent(consumptionDate: lastYear, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")

        let before = Date.now
        let copy = original.duplicated()
        let after = Date.now

        #expect(copy.consumptionDate >= before)
        #expect(copy.consumptionDate <= after)
    }

    @Test func duplicated_respectsExplicitTimestamp() {
        let target = Date(timeIntervalSince1970: 1_700_000_000)
        let original = ConsumptionEvent(volumeMl: 500, abv: 0.05,
                                        category: .beer, icon: "🍺")

        let copy = original.duplicated(consumptionDate: target)

        #expect(copy.consumptionDate == target)
    }

    @Test func duplicated_returnsDistinctInstance() {
        let original = ConsumptionEvent(volumeMl: 500, abv: 0.05,
                                        category: .beer, icon: "🍺")

        let copy = original.duplicated()

        #expect(copy !== original)
    }
}
