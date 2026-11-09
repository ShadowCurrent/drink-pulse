import Foundation

/// Loads backup fixture JSON from the test bundle. Never reads from a repository path.
enum BackupFixtureLoader {

    enum LoadError: Error, CustomStringConvertible {
        case resourceNotFound(String)

        var description: String {
            switch self {
            case .resourceNotFound(let name):
                return "Fixture resource '\(name).json' not found in the test bundle"
            }
        }
    }

    private final class BundleAnchor {}

    /// Returns the bytes of `<name>.json`, looking in the `Fixtures` subdirectory first, then the bundle root.
    static func data(named name: String) throws -> Data {
        let bundle = Bundle(for: BundleAnchor.self)
        let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
            ?? bundle.url(forResource: name, withExtension: "json")
        guard let url else { throw LoadError.resourceNotFound(name) }
        return try Data(contentsOf: url)
    }
}
