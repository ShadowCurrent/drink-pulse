import Testing
import Foundation
@testable import drinkpulse

struct StartupErrorTests {

    @Test func diagnosticSummary_storeUnavailable_returnsCoarseCategory() {
        #expect(StartupError.storeUnavailable.diagnosticSummary == "startup-error-category: store-unavailable")
    }

    @Test func diagnosticSummary_unknown_returnsCoarseCategory() {
        #expect(StartupError.unknown.diagnosticSummary == "startup-error-category: unknown")
    }

    @Test func init_fromArbitraryError_categorizesAsStoreUnavailable() {
        let underlying = NSError(domain: "any.domain", code: 1)
        #expect(StartupError(underlying: underlying) == .storeUnavailable)
    }

    @Test func equatable_sameCase_areEqual() {
        #expect(StartupError.storeUnavailable == StartupError.storeUnavailable)
    }
}
