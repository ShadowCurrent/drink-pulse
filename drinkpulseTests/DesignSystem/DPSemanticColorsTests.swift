import Testing
import SwiftUI
import UIKit
@testable import drinkpulse

/// Small-text tokens must reach WCAG 4.5:1 on the Frost page they sit on (Form section footers
/// are drawn on the tinted page, not on a row surface).
@MainActor
@Suite struct DPSemanticColorsTests {

    /// The Frost page as `BrandBackdrop` draws it with standard contrast.
    private func page(_ scheme: ColorScheme) -> Color.Resolved {
        let fraction = Brand.tintFraction(scheme: scheme, contrast: .standard)
        return resolved(Color(uiColor: .systemGroupedBackground).mix(with: Brand.accent, by: fraction), scheme)
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func test_deniedText_meetsSmallTextContrast_onFrostPage(_ scheme: ColorScheme) {
        let ratio = contrastRatio(resolved(Color.dpDeniedText, scheme), page(scheme))
        #expect(ratio >= 4.5, "\(scheme): \(ratio)")
    }

    @Test func test_deniedText_staysRed_inBothSchemes() {
        for scheme in [ColorScheme.light, .dark] {
            let ink = resolved(Color.dpDeniedText, scheme)
            #expect(ink.red > ink.green + 0.3 && ink.red > ink.blue + 0.3, "\(scheme): \(ink)")
        }
    }
}
