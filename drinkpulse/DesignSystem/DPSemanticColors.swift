import SwiftUI

extension Color {
    // Risk-level semantic colours (adaptive light/dark via Asset Catalog).
    // Use these wherever the *meaning* is "risk level" — not the accent palette.
    static let dpRiskLow      = Color("RiskLow")
    static let dpRiskModerate = Color("RiskModerate")
    static let dpRiskHigh     = Color("RiskHigh")
}
