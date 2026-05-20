import SwiftUI

/// Brand palette. Controls app-wide `.tint()` and FAB gradient.
/// Card backgrounds are theme-independent (system glass).
enum DPTheme: String, Codable, CaseIterable {
    case ember
    case forest
    case iris

    // MARK: - Colours (pre-converted from oklch; see plan-0008)

    var primary: Color {
        switch self {
        case .ember:  Color(red: 0.980, green: 0.365, blue: 0.212)  // #FA5D36
        case .forest: Color(red: 0.000, green: 0.506, blue: 0.251)  // #008140
        case .iris:   Color(red: 0.490, green: 0.357, blue: 0.902)  // #7D5BE6
        }
    }

    var gradientStart: Color { primary }

    var gradientEnd: Color {
        switch self {
        case .ember:  Color(red: 1.000, green: 0.486, blue: 0.000)  // #FF7C00
        case .forest: Color(red: 0.322, green: 0.580, blue: 0.125)  // #529420
        case .iris:   Color(red: 0.722, green: 0.365, blue: 0.945)  // #B85DF1
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Display

    var displayName: String {
        switch self {
        case .ember:  String(localized: "theme.ember")
        case .forest: String(localized: "theme.forest")
        case .iris:   String(localized: "theme.iris")
        }
    }
}

#Preview("Swatches") {
    VStack(spacing: 20) {
        ForEach(DPTheme.allCases, id: \.self) { theme in
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.gradient)
                    .frame(width: 60, height: 36)
                Circle()
                    .fill(theme.primary)
                    .frame(width: 28, height: 28)
                Text(theme.displayName)
                    .font(.headline)
            }
        }
    }
    .padding()
}
