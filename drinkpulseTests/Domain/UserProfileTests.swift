import Testing
import Foundation
@testable import drinkpulse

struct UserProfileTests {

    // MARK: - touch

    @Test func touch_advancesModifiedDate() {
        let past = Date(timeIntervalSince1970: 1_000)
        let profile = UserProfile()
        profile.modifiedDate = past
        profile.touch()
        #expect(profile.modifiedDate > past)
    }
}
