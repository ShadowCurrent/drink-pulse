import SwiftUI
import SwiftData

@Observable @MainActor final class OnboardingViewModel {
    var step: Int = 0
    var sex: BiologicalSex? = nil
    var dateOfBirth: Date? = nil
    var guideline: GuidelineChoice = .who
    private(set) var guidelineExplicitlyPicked = false

    var unitSystem: UnitSystem

    let totalSteps = 4

    init(locale: Locale = .current) {
        unitSystem = Self.unitSystem(for: locale)
    }

    static func unitSystem(for locale: Locale) -> UnitSystem {
        switch locale.measurementSystem {
        case .us:       return .usCustomary
        case .uk:       return .imperial
        case .metric:   return .metric
        default:        return .metric
        }
    }

    func advance() {
        guard step < totalSteps - 1 else { return }
        step += 1
    }

    func goBack() {
        guard step > 0 else { return }
        step -= 1
    }

    func setGuideline(_ choice: GuidelineChoice) {
        guideline = choice
        guidelineExplicitlyPicked = true
    }

    func complete(into context: ModelContext) {
        context.insert(UserProfile(
            biologicalSex: sex ?? .male,
            dateOfBirth: dateOfBirth,
            guidelineChoice: guideline,
            unitSystem: unitSystem
        ))
        try? context.save()
    }
}
