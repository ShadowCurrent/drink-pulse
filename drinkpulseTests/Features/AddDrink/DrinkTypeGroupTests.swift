import Testing
@testable import drinkpulse

@MainActor
struct DrinkTypeGroupTests {

    // MARK: - Groups

    @Test func test_groups_coverEveryPickerCategory_onceEach() {
        let categories = DrinkTypeGroup.allCases.flatMap { $0.presets.map(\.category) }
        let expected = Set(DrinkCategory.allCases).subtracting([.cognac])
        #expect(categories.count == 16)
        #expect(Set(categories) == expected)
    }

    @Test func test_groups_order() {
        #expect(DrinkTypeGroup.allCases == [.beerCider, .wine, .spirits, .mixed])
        #expect(DrinkTypeGroup.beerCider.presets.map(\.category) == [.beer, .cider])
        #expect(DrinkTypeGroup.wine.presets.map(\.category) == [.wine, .champagne, .fortifiedWine])
        #expect(DrinkTypeGroup.spirits.presets.map(\.category)
                == [.vodka, .whiskey, .tequila, .brandy, .spirits, .liqueur, .shot])
        #expect(DrinkTypeGroup.mixed.presets.map(\.category)
                == [.cocktail, .alcopop, .hotDrink, .custom])
    }

    @Test func test_groups_titles() {
        #expect(DrinkTypeGroup.allCases.map(\.title)
                == ["Beer & Cider", "Wine", "Spirits", "Mixed & Other"])
    }

    @Test func test_brandyPreset_isNamedBrandyAndCognac() {
        #expect(DrinkTypePreset.brandy.name == "Brandy & Cognac")
    }

    @Test func test_spiritRows_haveDistinctIcons() {
        let icons = DrinkTypeGroup.spirits.presets.map(\.icon)
        #expect(Set(icons).count == icons.count)
    }

    // MARK: - pickerCategory

    @Test func test_pickerCategory_mapsCognacToBrandy_andKeepsOthers() {
        #expect(DrinkTypeGroup.pickerCategory(for: .cognac) == .brandy)
        for category in DrinkCategory.allCases where category != .cognac {
            #expect(DrinkTypeGroup.pickerCategory(for: category) == category)
        }
    }

    // MARK: - Search

    @Test func test_presetsMatching_emptyQuery_returnsAll() {
        for group in DrinkTypeGroup.allCases {
            #expect(group.presets(matching: "") == group.presets)
            #expect(group.presets(matching: "  ") == group.presets)
        }
    }

    @Test func test_presetsMatching_cognac_findsBrandyRow() {
        #expect(DrinkTypeGroup.spirits.presets(matching: "cognac").map(\.category) == [.brandy])
    }

    @Test func test_presetsMatching_isCaseAndDiacriticInsensitive() {
        #expect(DrinkTypeGroup.spirits.presets(matching: "WHISK").map(\.category) == [.whiskey])
        #expect(DrinkTypeGroup.spirits.presets(matching: "téquila").map(\.category) == [.tequila])
    }

    @Test func test_sections_noMatch_isEmpty() {
        for group in DrinkTypeGroup.allCases {
            #expect(group.presets(matching: "zzz").isEmpty)
        }
    }
}
