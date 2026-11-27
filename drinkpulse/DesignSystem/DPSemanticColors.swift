import SwiftUI

extension Color {
    /// Secondary text, section headers, hint footers and picker values on the Frost tint (List /
    /// Form screens and cards). System secondary grey is only about 3.2–3.4:1 on the Light tint,
    /// below 4.5:1 for small text; this asset reaches 4.96:1, with a darker Light variant and a
    /// lighter Dark variant (plan 11-17, plan 0043).
    static let dpSecondaryText = Color("SecondaryText")

    /// Permission-denied messages in Form section footers, drawn on the Frost page. System red is
    /// about 3:1 there (below 4.5:1 for footnote text), so this asset holds a darker Light red
    /// (#B3261E) and a lighter Dark red (#FF6961) (owner choice 2026-11-21, plan 0043 review).
    static let dpDeniedText = Color("DeniedText")
}
