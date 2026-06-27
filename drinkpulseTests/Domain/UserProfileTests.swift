import Testing
import Foundation
@testable import drinkpulse

struct UserProfileTests {

    // MARK: - ageYears

    @Test func ageYears_nilDateOfBirth_returnsNil() {
        let profile = UserProfile(dateOfBirth: nil)
        #expect(profile.ageYears == nil)
    }

    @Test func ageYears_exactYearsAgo_returnsCorrectAge() {
        // Build a DOB that is exactly 30 years before now so the calendar
        // computation always returns 30, regardless of when the test runs.
        let yearsAgo = 30
        let dob = Calendar.current.date(byAdding: .year, value: -yearsAgo, to: .now)!
        let profile = UserProfile(dateOfBirth: dob)
        #expect(profile.ageYears == yearsAgo)
    }

    @Test func ageYears_defaultInit_isNil() {
        // Default init passes no dateOfBirth → ageYears must be nil.
        let profile = UserProfile()
        #expect(profile.ageYears == nil)
    }
}
