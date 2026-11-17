import SwiftUI

extension Color {
    static let dpRiskLow      = Color("RiskLow")
    static let dpRiskModerate = Color("RiskModerate")
    static let dpRiskHigh     = Color("RiskHigh")

    /// Secondary text on glass cards. A hierarchical `.secondary` is drawn vibrant on glass, and
    /// even the concrete secondary label color is below 4.5:1 for small text on a light card, so
    /// this asset holds a darker light variant and a lighter dark variant (plan 11-17).
    static let dpSecondaryText = Color("SecondaryText")
}
