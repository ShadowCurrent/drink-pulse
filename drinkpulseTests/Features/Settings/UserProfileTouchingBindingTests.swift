import Testing
import Foundation
@testable import drinkpulse

@MainActor
struct UserProfileTouchingBindingTests {

    private let past = Date(timeIntervalSince1970: 1_000)

    private func makeProfile(dateOfBirth: Date? = nil) -> UserProfile {
        let profile = UserProfile(dateOfBirth: dateOfBirth, unitSystem: .metric)
        profile.modifiedDate = past
        return profile
    }

    // MARK: - touchingBinding

    @Test func test_touchingBinding_writesAndTouches_whenValueChanges() {
        let profile = makeProfile()
        profile.touchingBinding(\.unitSystem).wrappedValue = .imperial
        #expect(profile.unitSystem == .imperial)
        #expect(profile.modifiedDate > past)
    }

    @Test func test_touchingBinding_doesNotTouch_whenValueIsSame() {
        let profile = makeProfile()
        profile.touchingBinding(\.unitSystem).wrappedValue = .metric
        #expect(profile.unitSystem == .metric)
        #expect(profile.modifiedDate == past)
    }

    @Test func test_touchingBinding_readsCurrentValue() {
        let profile = makeProfile()
        profile.unitSystem = .usCustomary
        #expect(profile.touchingBinding(\.unitSystem).wrappedValue == .usCustomary)
    }

    // MARK: - dateOfBirthBinding

    @Test func test_dateOfBirthBinding_readsDefault_whenNil() throws {
        let profile = makeProfile()
        let value = profile.dateOfBirthBinding.wrappedValue
        let expected = try #require(Calendar.current.date(byAdding: .year, value: -30, to: .now))
        #expect(Calendar.current.isDate(value, inSameDayAs: expected))
        #expect(profile.dateOfBirth == nil)
        #expect(profile.modifiedDate == past)
    }

    @Test func test_dateOfBirthBinding_readsStoredValue() {
        let dob = Date(timeIntervalSince1970: 500_000_000)
        let profile = makeProfile(dateOfBirth: dob)
        #expect(profile.dateOfBirthBinding.wrappedValue == dob)
    }

    @Test func test_dateOfBirthBinding_writesAndTouches_onlyOnChange() {
        let dob = Date(timeIntervalSince1970: 500_000_000)
        let profile = makeProfile(dateOfBirth: dob)

        profile.dateOfBirthBinding.wrappedValue = dob
        #expect(profile.modifiedDate == past)

        let newDob = Date(timeIntervalSince1970: 600_000_000)
        profile.dateOfBirthBinding.wrappedValue = newDob
        #expect(profile.dateOfBirth == newDob)
        #expect(profile.modifiedDate > past)
    }
}
