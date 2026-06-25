import Foundation

/// A selectable currency: an ISO 4217 code plus a short display symbol.
/// Value type, no behaviour beyond lookup — currency never enters any
/// alcohol/risk/BAC calculation. Stored on `ConsumptionEvent.priceCurrency`
/// alongside the price so an amount is never reinterpreted when the user
/// later changes their profile currency.
nonisolated struct CurrencyOption: Identifiable, Hashable, Sendable {
    let code: String
    let symbol: String

    var id: String { code }
}

nonisolated enum CurrencyCatalog {
    /// Short common list (owner decision, plan-0034) — a `.menu` picker, not a
    /// full ISO 4217 catalogue. Codes are uppercase ISO 4217.
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

    /// Fallback when no profile currency is set or a stored code is unknown.
    static let defaultCode = "USD"

    /// The catalogue entry for `code`, or the `defaultCode` entry when `code`
    /// is nil/unknown. Never returns nil — the picker always has a valid
    /// selection.
    static func option(for code: String?) -> CurrencyOption {
        if let code, let match = common.first(where: { $0.code == code }) {
            return match
        }
        return common.first(where: { $0.code == defaultCode }) ?? common[0]
    }

    /// The display symbol for `code`, or the default's symbol when unknown.
    static func symbol(for code: String?) -> String {
        option(for: code).symbol
    }
}
