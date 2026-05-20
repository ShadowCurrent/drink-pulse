import Testing
@testable import drinkpulse
import SwiftUI

@Suite("DPTheme")
struct DPThemeTests {

    @Test("primary is distinct per case")
    func primary_distinctPerCase() {
        let primaries = DPTheme.allCases.map { UIColor($0.primary) }
        let unique = Set(primaries.map { c -> String in
            var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0
            c.getRed(&r, green: &g, blue: &b, alpha: nil)
            return "\(r.rounded(to: 3)),\(g.rounded(to: 3)),\(b.rounded(to: 3))"
        })
        #expect(unique.count == DPTheme.allCases.count)
    }

    @Test("gradientStart and gradientEnd are distinct per case")
    func gradient_endpointsDistinct() {
        for theme in DPTheme.allCases {
            #expect(UIColor(theme.gradientStart) != UIColor(theme.gradientEnd),
                    "Gradient endpoints identical for \(theme)")
        }
    }

    @Test("rawValue round-trip preserves all cases")
    func rawValue_roundTrip() {
        for theme in DPTheme.allCases {
            #expect(DPTheme(rawValue: theme.rawValue) == theme)
        }
    }

    @Test("invalid rawValue returns nil")
    func rawValue_invalid_returnsNil() {
        #expect(DPTheme(rawValue: "neon") == nil)
        #expect(DPTheme(rawValue: "") == nil)
    }

    @Test("displayName is non-empty for all cases")
    func displayName_nonEmpty() {
        for theme in DPTheme.allCases {
            #expect(!theme.displayName.isEmpty)
        }
    }

    @Test("all cases covered — count is 3")
    func allCases_count() {
        #expect(DPTheme.allCases.count == 3)
    }
}

private extension CGFloat {
    func rounded(to places: Int) -> CGFloat {
        let factor = pow(10.0, CGFloat(places))
        return (self * factor).rounded() / factor
    }
}
