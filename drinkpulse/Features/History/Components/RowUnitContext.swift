import Foundation

/// The three display units a History row actually renders, as a plain value.
///
/// Rows must not take `UserProfile` — it is an observable SwiftData model class, so
/// reading *any* of its properties from a row body establishes an observation
/// dependency on the whole object. Editing body weight, date of birth or the weekly
/// goal then invalidates every visible row even though none of them render those
/// values. Passing this POD instead narrows the dependency to the three enums a row
/// genuinely needs, and makes rows equatable so SwiftUI can skip unchanged bodies.
/// Finding A6-1.
struct RowUnitContext: Equatable, Sendable {
    let alcoholUnit: AlcoholUnit
    let guideline: GuidelineChoice
    let unitSystem: UnitSystem

    /// Fallbacks are lifted verbatim from `EventRow`'s previous computed properties,
    /// so behaviour with a missing profile is provably unchanged.
    init(_ profile: UserProfile?) {
        self.alcoholUnit = profile?.alcoholUnit ?? .standardDrinks
        self.guideline = profile?.guidelineChoice ?? .who
        self.unitSystem = profile?.unitSystem ?? .metric
    }

    /// Memberwise initialiser for tests and previews, which should not have to build
    /// a `UserProfile` (and therefore a `ModelContainer`) to render a row.
    init(alcoholUnit: AlcoholUnit, guideline: GuidelineChoice, unitSystem: UnitSystem) {
        self.alcoholUnit = alcoholUnit
        self.guideline = guideline
        self.unitSystem = unitSystem
    }

    /// Volume→mass density for this display mode and guideline. Callers previously
    /// repeated the `alcoholUnit.density(for: guideline)` pairing at every site
    /// (`EventRow`, `HistoryCalendarDayDetail`, `HistoryCalendarView`); this keeps the
    /// two halves of the pairing together. Physical mass (calories, future BAC) must
    /// still use `AlcoholUnit.physicalDensityGramsPerMl`, never this.
    var density: Double { alcoholUnit.density(for: guideline) }
}
