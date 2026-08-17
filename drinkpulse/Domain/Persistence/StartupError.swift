import Foundation

enum StartupError: Error, Equatable {
    case storeUnavailable
    case unknown

    var diagnosticSummary: String {
        switch self {
        case .storeUnavailable: "startup-error-category: store-unavailable"
        case .unknown:          "startup-error-category: unknown"
        }
    }

    init(underlying: Error) {
        _ = underlying
        self = .storeUnavailable
    }
}
