import SwiftUI

/// Test helpers for colour tokens: resolve a `Color` in a given appearance and measure
/// WCAG 2.x contrast between two resolved colours.

func resolved(_ color: Color, _ scheme: ColorScheme) -> Color.Resolved {
    var environment = EnvironmentValues()
    environment.colorScheme = scheme
    return color.resolve(in: environment)
}

/// sRGB hex constant (0xRRGGBB) as a `Color`.
func hexColor(_ value: UInt32) -> Color {
    Color(red: Double((value >> 16) & 0xFF) / 255,
          green: Double((value >> 8) & 0xFF) / 255,
          blue: Double(value & 0xFF) / 255)
}

/// WCAG 2.x relative luminance, from the gamma-encoded sRGB components.
func relativeLuminance(_ color: Color.Resolved) -> Double {
    func channel(_ value: Float) -> Double {
        let c = Double(value)
        return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * channel(color.red) + 0.7152 * channel(color.green) + 0.0722 * channel(color.blue)
}

func contrastRatio(_ a: Color.Resolved, _ b: Color.Resolved) -> Double {
    let la = relativeLuminance(a)
    let lb = relativeLuminance(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
}

/// True when every RGB component of `color` is within `tolerance` of `rgb`.
func matches(_ color: Color.Resolved, _ rgb: (Double, Double, Double), tolerance: Double = 0.005) -> Bool {
    abs(Double(color.red) - rgb.0) <= tolerance
        && abs(Double(color.green) - rgb.1) <= tolerance
        && abs(Double(color.blue) - rgb.2) <= tolerance
}
