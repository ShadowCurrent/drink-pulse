import Foundation

nonisolated enum RiskLevel: Sendable {
    case safe      // pct < 0.5
    case caution   // 0.5 ≤ pct ≤ 1.0
    case exceeded  // pct > 1.0

    static func from(pct: Double) -> RiskLevel {
        if pct < 0.5  { return .safe }
        if pct <= 1.0 { return .caution }
        return .exceeded
    }
}
