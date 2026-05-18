import LocalAuthentication

struct BiometricService: Sendable {
    private let contextFactory: @Sendable () -> LAContext

    init(contextFactory: @Sendable @escaping () -> LAContext = { LAContext() }) {
        self.contextFactory = contextFactory
    }

    var canAuthenticate: Bool {
        contextFactory().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    var biometryType: LABiometryType {
        let ctx = contextFactory()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        return ctx.biometryType
    }

    func authenticate(reason: String) async throws {
        let ctx = contextFactory()
        try await ctx.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        )
    }
}
