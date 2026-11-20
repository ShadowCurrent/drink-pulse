import SwiftUI
import Testing
@testable import drinkpulse

/// Frost palette, tint and card surface (plan 0042, Task 2; prototype FINDINGS 5c–5d).
@Suite struct BrandTests {

    @Test func test_accent_resolvesFrost_inBothSchemes() {
        #expect(matches(resolved(Brand.accent, .light), (0.184, 0.424, 0.761)))
        #expect(matches(resolved(Brand.accent, .dark), (0.247, 0.525, 0.910)))
    }

    @Test func test_accent_light_meetsTextContrastOnWhite() {
        let ratio = contrastRatio(resolved(Brand.accent, .light), resolved(.white, .light))
        #expect(ratio >= 4.5, "\(ratio)")
    }

    @Test(arguments: [
        (ColorScheme.light, ColorSchemeContrast.standard, 0.06),
        (.dark, .standard, 0.18),
        (.light, .increased, 0.0),
        (.dark, .increased, 0.0),
    ])
    func test_tintFraction(_ scheme: ColorScheme, _ contrast: ColorSchemeContrast, _ expected: Double) {
        #expect(Brand.tintFraction(scheme: scheme, contrast: contrast) == expected)
    }

    @Test(arguments: [
        (ColorScheme.light, ColorSchemeContrast.standard, 0.0),
        (.dark, .standard, 0.07),
        (.light, .increased, 0.0),
        (.dark, .increased, 0.0),
    ])
    func test_surfaceFraction(_ scheme: ColorScheme, _ contrast: ColorSchemeContrast, _ expected: Double) {
        #expect(Brand.surfaceFraction(scheme: scheme, contrast: contrast) == expected)
    }

    @Test func test_ink_light_isNavy_andMeetsContrastOnEveryLightMeshStop() {
        let ink = resolved(Brand.ink(for: .light), .light)
        #expect(matches(ink, (12.0 / 255, 27.0 / 255, 58.0 / 255)))
        for stop in Brand.heroMesh(for: .light) {
            let ratio = contrastRatio(ink, resolved(stop, .light))
            #expect(ratio >= 7, "\(ratio)")
        }
    }

    @Test func test_ink_dark_isWhite_andMeetsContrastOnEveryDarkMeshStop() {
        let ink = resolved(Brand.ink(for: .dark), .dark)
        #expect(matches(ink, (1, 1, 1)))
        for stop in Brand.heroMesh(for: .dark) {
            let ratio = contrastRatio(ink, resolved(stop, .dark))
            #expect(ratio >= 4.5, "\(ratio)")
        }
    }

    @Test func test_heroMesh_hasNineStops_inBothSchemes() {
        #expect(Brand.heroMesh(for: .light).count == 9)
        #expect(Brand.heroMesh(for: .dark).count == 9)
    }
}
