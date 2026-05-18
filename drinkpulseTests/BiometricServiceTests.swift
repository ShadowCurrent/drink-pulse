import Testing
import LocalAuthentication
@testable import drinkpulse

struct BiometricServiceTests {

    @Test func canAuthenticateReturnsFalseWhenNoPasscode() {
        // Inject a context that always reports it cannot evaluate the policy.
        let service = BiometricService(contextFactory: {
            AlwaysFailingLAContext()
        })
        #expect(service.canAuthenticate == false)
    }

    @Test func canAuthenticateReturnsTrueWhenPasscodeAvailable() {
        let service = BiometricService(contextFactory: {
            AlwaysSucceedingLAContext()
        })
        #expect(service.canAuthenticate == true)
    }
}

// MARK: - Test doubles

private final class AlwaysFailingLAContext: LAContext {
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        return false
    }
}

private final class AlwaysSucceedingLAContext: LAContext {
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        return true
    }
}
