import Testing
import Foundation
@testable import drinkpulse

@MainActor
struct UserProfileTouchingBindingTests {

    private let past = Date(timeIntervalSince1970: 1_000)

    private func makeProfile() -> UserProfile {
        let profile = UserProfile(unitSystem: .metric)
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
}
