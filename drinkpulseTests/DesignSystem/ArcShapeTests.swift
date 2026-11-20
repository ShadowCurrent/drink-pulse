import SwiftUI
import Testing
@testable import drinkpulse

/// Animatable hero arc (plan 0042, Task 4): without `animatableData` SwiftUI cannot interpolate
/// the sweep, so every change of `to` jumped.
@Suite struct ArcShapeTests {

    @Test func test_animatableData_readsAndWritesTo() {
        var arc = ArcShape(from: 0, to: 0.3)
        arc.animatableData = 0.7
        #expect(arc.to == 0.7)
        #expect(arc.animatableData == 0.7)
    }

    @Test func test_path_changesWithAnimatableData() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        var arc = ArcShape(from: 0, to: 0.3)
        let short = arc.path(in: rect).boundingRect
        arc.animatableData = 0.7
        let long = arc.path(in: rect).boundingRect
        #expect(short != long)
    }

    @Test(arguments: [(ColorSchemeContrast.standard, 0.2), (.increased, 0.4)])
    func test_trackOpacity(_ contrast: ColorSchemeContrast, _ expected: Double) {
        #expect(DPArcProgress.trackOpacity(contrast) == expected)
    }
}
