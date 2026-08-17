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
        let yearsAgo = 30
        let dob = Calendar.current.date(byAdding: .year, value: -yearsAgo, to: .now)!
        let profile = UserProfile(dateOfBirth: dob)
        #expect(profile.ageYears == yearsAgo)
    }

    @Test func ageYears_defaultInit_isNil() {
        let profile = UserProfile()
        #expect(profile.ageYears == nil)
    }
}
