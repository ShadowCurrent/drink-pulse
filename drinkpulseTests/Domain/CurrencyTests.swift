import Testing
@testable import drinkpulse

struct CurrencyTests {
    @Test func common_containsCoreCurrencies() {
        let codes = CurrencyCatalog.common.map(\.code)
        #expect(codes.contains("USD"))
        #expect(codes.contains("EUR"))
        #expect(codes.contains("GBP"))
        #expect(codes.contains("PLN"))
    }

    @Test func common_codesAreUnique() {
        let codes = CurrencyCatalog.common.map(\.code)
        #expect(Set(codes).count == codes.count)
    }

    @Test func option_returnsMatchForKnownCode() {
        let option = CurrencyCatalog.option(for: "EUR")
        #expect(option.code == "EUR")
        #expect(option.symbol == "€")
    }

    @Test func option_fallsBackToDefaultForUnknownCode() {
        let option = CurrencyCatalog.option(for: "XYZ")
        #expect(option.code == CurrencyCatalog.defaultCode)
    }

    @Test func option_fallsBackToDefaultForNil() {
        let option = CurrencyCatalog.option(for: nil)
        #expect(option.code == CurrencyCatalog.defaultCode)
    }

    @Test func symbol_returnsKnownSymbol() {
        #expect(CurrencyCatalog.symbol(for: "GBP") == "£")
    }

    @Test func symbol_unknownCode_returnsDefaultSymbol() {
        let expected = CurrencyCatalog.option(for: nil).symbol
        #expect(CurrencyCatalog.symbol(for: "XYZ") == expected)
    }

    @Test func defaultCode_isInCatalog() {
        #expect(CurrencyCatalog.common.contains { $0.code == CurrencyCatalog.defaultCode })
    }
}
