import Foundation

extension RiskLevel {
    /// The status label shown with the risk tone (plan 0046, D0046-15; `VOICE.md`). Thresholds
    /// stay in `RiskLevel.from(pct:)`; only the copy lives here.
    nonisolated var statusTitle: String {
        switch self {
        case .safe:     return String(localized: "dashboard.risk.safe")
        case .caution:  return String(localized: "dashboard.risk.caution")
        case .exceeded: return String(localized: "dashboard.risk.exceeded")
        }
    }

    /// The SF Symbol of the status glyph (plan 0046, D0046-3).
    nonisolated var statusSymbol: String {
        switch self {
        case .safe:     return "checkmark.circle.fill"
        case .caution:  return "exclamationmark.circle.fill"
        case .exceeded: return "exclamationmark.triangle.fill"
        }
    }
}
