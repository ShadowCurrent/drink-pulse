import Foundation

nonisolated enum RiskLevel: Sendable {
    case safe
    case caution
    case exceeded

    static func from(pct: Double) -> RiskLevel {
        if pct < 0.5  { return .safe }
        if pct <= 1.0 { return .caution }
        return .exceeded
    }
}
