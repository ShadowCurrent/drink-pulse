import SwiftUI
import SwiftData

@Observable @MainActor final class OnboardingViewModel {
    var step: Int = 0
    var sex: BiologicalSex? = nil
    var dateOfBirth: Date? = nil
    var guideline: GuidelineChoice = .who
    private(set) var guidelineExplicitlyPicked = false

    let totalSteps = 3

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
        let hasData = sex != nil || dateOfBirth != nil || guidelineExplicitlyPicked
        guard hasData else { return }
        context.insert(UserProfile(
            biologicalSex: sex ?? .male,
            dateOfBirth: dateOfBirth,
            guidelineChoice: guideline
        ))
    }
}
