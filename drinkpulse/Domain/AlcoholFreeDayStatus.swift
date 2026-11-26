import Foundation

/// How one calendar day counts in the alcohol-free metrics (see `AlcoholFreeDayRule`).
nonisolated enum AlcoholFreeDayStatus: Equatable, Sendable {
    /// Before the first logged event, in the future, or today without alcohol.
    case notCounted
    /// A counted day with 0 g of alcohol.
    case alcoholFree
    /// A counted day with more than 0 g of alcohol.
    case drinking
}
