import Testing
import UserNotifications
@testable import drinkpulse

@MainActor
@Suite(.serialized)
struct NotificationDelegateAssignmentTests {

    // Pins ordering only: the delegate is set by the time the call returns, with no suspension point.
    // It cannot prove system delivery timing on a killed app; the device cold taps (plan 10-14) do.
    @Test func assignNotificationDelegate_setsTheHandlerAsCenterDelegate_beforeItReturns() {
        let center = UNUserNotificationCenter.current()
        let previous = center.delegate
        defer { center.delegate = previous }
        let handler = NotificationActionHandler()

        drinkpulseApp.assignNotificationDelegate(handler)

        #expect((center.delegate as AnyObject?) === handler)
    }

    @Test func assignNotificationDelegate_calledTwiceWithTheSameHandler_keepsThatHandler() {
        let center = UNUserNotificationCenter.current()
        let previous = center.delegate
        defer { center.delegate = previous }
        let handler = NotificationActionHandler()

        drinkpulseApp.assignNotificationDelegate(handler)
        drinkpulseApp.assignNotificationDelegate(handler)

        #expect((center.delegate as AnyObject?) === handler)
    }
}
