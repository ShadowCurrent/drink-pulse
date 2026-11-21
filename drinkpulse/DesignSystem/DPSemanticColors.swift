import SwiftUI

extension Color {
    /// Secondary text on glass cards. A hierarchical `.secondary` is drawn vibrant on glass, and
    /// even the concrete secondary label color is below 4.5:1 for small text on a light card, so
    /// this asset holds a darker light variant and a lighter dark variant (plan 11-17).
    static let dpSecondaryText = Color("SecondaryText")

    /// Permission-denied messages in Form section footers, drawn on the Frost page. System red is
    /// about 3:1 there (below 4.5:1 for footnote text), so this asset holds a darker Light red
    /// (#B3261E) and a lighter Dark red (#FF6961) (owner choice 2026-11-21, plan 0043 review).
    static let dpDeniedText = Color("DeniedText")
}
