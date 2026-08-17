import Foundation

struct RowUnitContext: Equatable, Sendable {
    let alcoholUnit: AlcoholUnit
    let guideline: GuidelineChoice
    let unitSystem: UnitSystem

    init(_ profile: UserProfile?) {
        self.alcoholUnit = profile?.alcoholUnit ?? .standardDrinks
        self.guideline = profile?.guidelineChoice ?? .who
        self.unitSystem = profile?.unitSystem ?? .metric
    }

    init(alcoholUnit: AlcoholUnit, guideline: GuidelineChoice, unitSystem: UnitSystem) {
        self.alcoholUnit = alcoholUnit
        self.guideline = guideline
        self.unitSystem = unitSystem
    }

    var density: Double { alcoholUnit.density(for: guideline) }
}
