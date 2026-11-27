import SwiftUI
import SwiftData
import OSLog

@Observable @MainActor final class OnboardingViewModel {
    var step: Int = 0
    var sex: BiologicalSex? = nil
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

    /// Set by the first successful `complete(into:)` so a double tap on Done
    /// cannot insert two profiles (D0048-6).
    private(set) var isCompleted = false

    func complete(into context: ModelContext) {
        guard let sex, !isCompleted else { return }
        isCompleted = true
        context.insert(UserProfile(
            biologicalSex: sex,
            guidelineChoice: guideline,
            unitSystem: unitSystem
        ))
        do {
            try context.save()
        } catch {
            // The main context autosaves later; log the error type only (no health data).
            Self.logger.error("Onboarding profile save failed: \(String(describing: type(of: error)), privacy: .public)")
        }
    }

    private static let logger = Logger(subsystem: "com.drinkpulse.app", category: "Onboarding")
}
