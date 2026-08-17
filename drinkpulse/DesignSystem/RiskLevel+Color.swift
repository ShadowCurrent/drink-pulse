import SwiftUI

extension RiskLevel {
    var color: Color {
        switch self {
        case .safe:     return .dpGreen
        case .caution:  return .dpAmber
        case .exceeded: return .dpRed
        }
    }

    var chartColor: Color {
        switch self {
        case .safe:     return .dpRiskLow
        case .caution:  return .dpRiskModerate
        case .exceeded: return .dpRiskHigh
        }
    }
}
