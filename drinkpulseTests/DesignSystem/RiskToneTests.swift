import SwiftUI
import Testing
@testable import drinkpulse

/// One risk palette (plan 0042, D0042-1): the prototype's `riskTone`, held as three asset
/// colour sets. Light = the former `RiskText*` Light values, Dark = the former `Risk*` Dark values.
@Suite struct RiskToneTests {

    static let light: [(RiskLevel, (Double, Double, Double))] = [
        (.safe, (0.11, 0.42, 0.14)),
        (.caution, (0.62, 0.30, 0.00)),
        (.exceeded, (0.72, 0.12, 0.12)),
    ]

    static let dark: [(RiskLevel, (Double, Double, Double))] = [
        (.safe, (0.30, 0.75, 0.32)),
        (.caution, (1.00, 0.68, 0.20)),
        (.exceeded, (1.00, 0.33, 0.30)),
    ]

    @Test(arguments: [0, 1, 2])
    func test_tone_light_matchesPalette(_ index: Int) {
        let (level, rgb) = Self.light[index]
        #expect(matches(resolved(level.tone, .light), rgb), "\(level)")
    }

    @Test(arguments: [0, 1, 2])
    func test_tone_dark_matchesPalette(_ index: Int) {
        let (level, rgb) = Self.dark[index]
        #expect(matches(resolved(level.tone, .dark), rgb), "\(level)")
    }

    /// Light tones double as text, so they must reach 4.5:1 on a white card.
    @Test(arguments: [RiskLevel.safe, .caution, .exceeded])
    func test_tone_light_meetsNonTextContrastOnWhiteCard(_ level: RiskLevel) {
        let ratio = contrastRatio(resolved(level.tone, .light), resolved(.white, .light))
        #expect(ratio >= 4.5, "\(level): \(ratio)")
    }

    /// Dark card = secondarySystemGroupedBackground Dark (#1C1C1E) mixed 7 % with the Dark accent.
    @Test(arguments: [RiskLevel.safe, .caution, .exceeded])
    func test_tone_dark_meetsContrastOnDarkCard(_ level: RiskLevel) {
        let card = hexColor(0x1C1C1E).mix(with: hexColor(0x3F86E8), by: 0.07)
        let ratio = contrastRatio(resolved(level.tone, .dark), resolved(card, .dark))
        #expect(ratio >= 4.5, "\(level): \(ratio)")
    }
}
