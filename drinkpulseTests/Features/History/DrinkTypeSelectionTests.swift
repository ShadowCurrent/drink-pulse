import Testing
@testable import drinkpulse

@MainActor
struct DrinkTypeSelectionTests {

    @Test func test_apply_sameRow_returnsNil() {
        #expect(DrinkTypeSelection.apply(.wine, to: .wine) == nil)
    }

    @Test func test_apply_cognacEvent_tapBrandy_returnsNil() {
        // The Brandy & Cognac row stands for a Cognac event; tapping it keeps `.cognac`.
        #expect(DrinkTypeSelection.apply(.brandy, to: .cognac) == nil)
    }

    @Test func test_apply_otherRow_returnsTapped() {
        #expect(DrinkTypeSelection.apply(.beer, to: .wine) == .beer)
        #expect(DrinkTypeSelection.apply(.whiskey, to: .cognac) == .whiskey)
    }

    @Test func test_isSelected_marksPickerRowOfCurrent() {
        #expect(DrinkTypeSelection.isSelected(.brandy, current: .cognac))
        #expect(DrinkTypeSelection.isSelected(.wine, current: .wine))
        #expect(!DrinkTypeSelection.isSelected(.beer, current: .wine))
    }
}
