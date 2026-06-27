import Foundation

enum ImportError: LocalizedError {
    case unsupportedVersion(Int)
    case decodeFailure(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let v):
            return String(format: String(localized: "import.error.unsupportedVersion"), v)
        case .decodeFailure:
            return String(localized: "import.error.decodeFailure")
        }
    }
}
