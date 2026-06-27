import Foundation

enum UnitSystem: String, Codable, CaseIterable, Sendable {
    case metric       // millilitres
    case usCustomary  // US fluid ounces (1 fl oz = 29.5735 ml)
    case imperial     // Imperial fluid ounces (1 fl oz = 28.4131 ml)
}
