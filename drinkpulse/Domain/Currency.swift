import Foundation

nonisolated struct CurrencyOption: Identifiable, Hashable, Sendable {
    let code: String
    let symbol: String

    var id: String { code }
}

nonisolated enum CurrencyCatalog {
    static let common: [CurrencyOption] = [
        .init(code: "USD", symbol: "$"),
        .init(code: "EUR", symbol: "€"),
        .init(code: "GBP", symbol: "£"),
        .init(code: "PLN", symbol: "zł"),
        .init(code: "CHF", symbol: "Fr"),
        .init(code: "SEK", symbol: "kr"),
        .init(code: "NOK", symbol: "kr"),
        .init(code: "DKK", symbol: "kr"),
        .init(code: "CZK", symbol: "Kč"),
        .init(code: "CAD", symbol: "$"),
        .init(code: "AUD", symbol: "$"),
        .init(code: "JPY", symbol: "¥"),
    ]

    static let defaultCode = "USD"

    static func option(for code: String?) -> CurrencyOption {
        if let code, let match = common.first(where: { $0.code == code }) {
            return match
        }
        return common.first(where: { $0.code == defaultCode }) ?? common[0]
    }

    static func symbol(for code: String?) -> String {
        option(for: code).symbol
    }
}
