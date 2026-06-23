import SwiftUI
import SwiftData

@Observable @MainActor final class OnboardingViewModel {
    var step: Int = 0
    var sex: BiologicalSex? = nil
    var dateOfBirth: Date? = nil
    var guideline: GuidelineChoice = .who
    private(set) var guidelineExplicitlyPicked = false

    /// Auto-picked volume unit. Defaults from the device locale's measurement
    /// system (plan-0030); the user can override it later in Settings.
    var unitSystem: UnitSystem

    let totalSteps = 3

    init(locale: Locale = .current) {
        unitSystem = Self.unitSystem(for: locale)
    }

    /// Maps a locale's measurement system to a volume unit:
    /// `.metric` → `.metric`, `.us` → `.usCustomary`, `.uk` → `.imperial`.
    /// Any unrecognized system falls back to `.metric`.
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

    func skipStep() {
        advance()
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
    }
}
