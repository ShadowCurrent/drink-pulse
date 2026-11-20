import SwiftUI

extension RiskLevel {
    /// The one risk colour for every risk mark and risk text (plan 0042, D0042-1). Asset colour
    /// sets: Light is dark enough for text on a white card (>= 4.5:1), Dark is light enough for
    /// the dark card. Asset colours resolve per appearance without a closure, and `tone` is
    /// `nonisolated`, so Swift Charts can resolve it off the main actor.
    nonisolated var tone: Color {
        switch self {
        case .safe:     return Color("RiskLow")
        case .caution:  return Color("RiskModerate")
        case .exceeded: return Color("RiskHigh")
        }
    }
}
