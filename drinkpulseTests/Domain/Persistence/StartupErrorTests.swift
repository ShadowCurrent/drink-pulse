import Testing
import Foundation
@testable import drinkpulse

/// Unit coverage for `StartupError`'s non-PII categorization (STARTUP-03,
/// D-08, Pitfall 1). These tests pin the exact diagnostic strings surfaced
/// on `StartupErrorView` — never `error.localizedDescription`, never a file
/// path.
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
