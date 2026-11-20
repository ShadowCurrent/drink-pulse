import SwiftUI

/// Brand colours: Frost (owner choice 2026-11-20, plan 0040; prototype FINDINGS 5c–5d).
/// HIG Branding: brand colour in the content layer (hero card, faint background tint);
/// controls stay system-styled; the accent is used only for the primary action, selection
/// and amount charts. HIG Color: the brand blue never reuses the risk scale (`RiskLevel.tone`).
nonisolated enum Brand {
    /// `AccentColor` asset: Light #2F6CC2 (>= 4.5:1 on white), Dark #3F86E8. The same asset is
    /// the app's global accent (`ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`), so system
    /// controls tint with it. Loaded by name, not `Color.accentColor`, so the value does not
    /// depend on a view's `tint` environment. An asset colour resolves per appearance without a
    /// closure, so it is safe to resolve off the main actor.
    static let accent = Color("AccentColor")

    /// Text and gauge colour on the hero mesh: navy on the Light pastel, white in Dark.
    static func ink(for scheme: ColorScheme) -> Color {
        scheme == .light ? hex(0x0C1B3A) : .white
    }

    /// 3×3 hero mesh. Light: pastel, light enough for the navy ink (>= 7:1).
    /// Dark: deep navy, dark enough for white text (>= 4.5:1).
    static func heroMesh(for scheme: ColorScheme) -> [Color] {
        let values: [UInt32] = scheme == .light
            ? [0xF4F8FF, 0xEAF2FE, 0xF0F5FC, 0xE6EFFD, 0xDBEAFE, 0xE4EEFB, 0xF2F7FF, 0xDDEAFC, 0xF6F9FF]
            : [0x0A1630, 0x0C1B3A, 0x0E1F42, 0x0D1D3E, 0x15305E, 0x122852, 0x0B1834, 0x1A3768, 0x0F2246]
        return values.map(hex)
    }

    /// Share of the accent mixed into the grouped page background: 6 % Light, 18 % Dark (the
    /// Dark base is pure black, so 10 % was invisible). Increase Contrast removes the tint.
    static func tintFraction(scheme: ColorScheme, contrast: ColorSchemeContrast) -> Double {
        guard contrast != .increased else { return 0 }
        return scheme == .dark ? 0.18 : 0.06
    }

    /// Share of the accent mixed into the card / row surface: 7 % in Dark only (a neutral
    /// #1C1C1E clashes with the navy-black page). Increase Contrast removes it.
    static func surfaceFraction(scheme: ColorScheme, contrast: ColorSchemeContrast) -> Double {
        guard contrast != .increased, scheme == .dark else { return 0 }
        return 0.07
    }

    private static func hex(_ value: UInt32) -> Color {
        Color(red: Double((value >> 16) & 0xFF) / 255,
              green: Double((value >> 8) & 0xFF) / 255,
              blue: Double(value & 0xFF) / 255)
    }
}
