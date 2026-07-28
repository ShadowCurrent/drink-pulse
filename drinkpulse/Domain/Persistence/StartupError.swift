import Foundation

/// Coarse, non-PII categorization of a `ModelContainer` open failure
/// (STARTUP-03, D-08, Pitfall 1).
///
/// `StartupErrorView`'s copyable diagnostic text surfaces only
/// `diagnosticSummary` — never `error.localizedDescription` or any
/// `ModelConfiguration.url`, both of which can embed absolute filesystem
/// paths and internal SQLite diagnostic strings (ASVS V7/V8).
enum StartupError: Error, Equatable {
    /// `ModelContainer.init` failed even after `StoreBootstrap.makeContainer`'s
    /// own internal `recoverStore` move-aside-and-retry attempt.
    case storeUnavailable
    /// Reserved catch-all category — not yet reachable via `init(underlying:)`
    /// (Pitfall 1: current best-effort categorization maps every underlying
    /// error to `.storeUnavailable`).
    case unknown

    /// Non-PII, copy-paste diagnostic text — category only, matching the
    /// existing `"category: recovery"` logging convention in
    /// `StoreBootstrap.swift`. Never interpolate the underlying error or a
    /// file path here.
    var diagnosticSummary: String {
        switch self {
        case .storeUnavailable: "startup-error-category: store-unavailable"
        case .unknown:          "startup-error-category: unknown"
        }
    }

    init(underlying: Error) {
        // Best-effort coarse categorization — see Pitfall 1 for why this
        // stays deliberately shallow rather than parsing NSError codes.
        // `underlying` is intentionally not interpolated anywhere (D-08).
        _ = underlying
        self = .storeUnavailable
    }
}
