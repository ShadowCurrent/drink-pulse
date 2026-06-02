import SwiftUI

extension RiskLevel {
    // Badge, text, progress bar coloring.
    var color: Color {
        switch self {
        case .safe:     return .dpGreen
        case .caution:  return .dpAmber
        case .exceeded: return .dpRed
        }
    }

    // Arc and bar chart coloring (semantic palette).
    var chartColor: Color {
        switch self {
        case .safe:     return .dpRiskLow
        case .caution:  return .dpRiskModerate
        case .exceeded: return .dpRiskHigh
        }
    }
}
