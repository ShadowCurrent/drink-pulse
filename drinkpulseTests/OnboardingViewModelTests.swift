import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct OnboardingViewModelTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test("Default guideline is WHO")
    func defaultGuidelineIsWHO() {
        let vm = OnboardingViewModel()
        #expect(vm.guideline == .who)
        #expect(!vm.guidelineExplicitlyPicked)
    }

    @Test("complete with no selections inserts UserProfile with defaults")
    func completeWithNoSelectionsInsertsDefaultProfile() throws {
        let c = try makeContainer()
        let vm = OnboardingViewModel()
        vm.complete(into: c.mainContext)
        let profiles = try c.mainContext.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        #expect(profiles[0].biologicalSex == .male)
        #expect(profiles[0].guidelineChoice == .who)
    }

    @Test("complete with sex inserts UserProfile")
    func completeWithSexInsertsProfile() throws {
        let c = try makeContainer()
        let vm = OnboardingViewModel()
        vm.sex = .female
        vm.complete(into: c.mainContext)
        let profiles = try c.mainContext.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        #expect(profiles[0].biologicalSex == .female)
        #expect(profiles[0].dateOfBirth == nil)
    }

    @Test("complete with dateOfBirth inserts UserProfile with correct DOB")
    func completeWithDOBInsertsProfile() throws {
        let c = try makeContainer()
        let vm = OnboardingViewModel()
        let dob = Calendar.current.date(byAdding: .year, value: -28, to: .now)!
        vm.dateOfBirth = dob
        vm.complete(into: c.mainContext)
        let profiles = try c.mainContext.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        #expect(profiles[0].dateOfBirth == dob)
        #expect(profiles[0].ageYears == 28)
    }

    @Test("complete with explicit guideline inserts profile")
    func completeWithExplicitGuidelineInsertsProfile() throws {
        let c = try makeContainer()
        let vm = OnboardingViewModel()
        vm.setGuideline(.uk)
        vm.complete(into: c.mainContext)
        let profiles = try c.mainContext.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        #expect(profiles[0].guidelineChoice == .uk)
    }

    @Test("complete with default guideline (not explicitly picked) still inserts profile")
    func completeWithDefaultGuidelineUnpickedInsertsProfile() throws {
        let c = try makeContainer()
        let vm = OnboardingViewModel()
        vm.complete(into: c.mainContext)
        let profiles = try c.mainContext.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        #expect(profiles[0].guidelineChoice == .who)
    }

    @Test("advance increments step, stops at last")
    func advanceIncrements() {
        let vm = OnboardingViewModel()
        #expect(vm.step == 0)
        vm.advance()
        #expect(vm.step == 1)
        vm.advance()
        #expect(vm.step == 2)
        vm.advance() // already at last step, should not increment
        #expect(vm.step == 2)
    }

    @Test("setGuideline marks as explicitly picked")
    func setGuidelineMarksExplicit() {
        let vm = OnboardingViewModel()
        vm.setGuideline(.de)
        #expect(vm.guidelineExplicitlyPicked)
        #expect(vm.guideline == .de)
    }

    @Test("skipStep advances step identically to advance")
    func skipStep_advancesStep() {
        let vm = OnboardingViewModel()
        #expect(vm.step == 0)
        vm.skipStep()
        #expect(vm.step == 1)
    }

    // MARK: - Unit-system locale default (plan-0030)

    @Test("metric locale maps to .metric")
    func metricLocaleMapsToMetric() {
        #expect(OnboardingViewModel.unitSystem(for: Locale(identifier: "de_DE")) == .metric)
        #expect(OnboardingViewModel.unitSystem(for: Locale(identifier: "fr_FR")) == .metric)
    }

    @Test("US locale maps to .usCustomary")
    func usLocaleMapsToUSCustomary() {
        #expect(OnboardingViewModel.unitSystem(for: Locale(identifier: "en_US")) == .usCustomary)
    }

    @Test("UK locale maps to .imperial")
    func ukLocaleMapsToImperial() {
        #expect(OnboardingViewModel.unitSystem(for: Locale(identifier: "en_GB")) == .imperial)
    }

    @Test("init picks unitSystem from locale")
    func initPicksUnitSystemFromLocale() {
        let vm = OnboardingViewModel(locale: Locale(identifier: "en_US"))
        #expect(vm.unitSystem == .usCustomary)
    }

    @Test("override is honored when completing")
    func overrideIsHonored() throws {
        let c = try makeContainer()
        let vm = OnboardingViewModel(locale: Locale(identifier: "en_US"))
        vm.unitSystem = .metric  // user overrides the locale default
        vm.complete(into: c.mainContext)
        let profiles = try c.mainContext.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles[0].unitSystem == .metric)
    }

    @Test("locale default flows into the saved profile")
    func localeDefaultFlowsIntoProfile() throws {
        let c = try makeContainer()
        let vm = OnboardingViewModel(locale: Locale(identifier: "en_GB"))
        vm.complete(into: c.mainContext)
        let profiles = try c.mainContext.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles[0].unitSystem == .imperial)
    }
}
