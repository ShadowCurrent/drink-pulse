import Foundation

extension GuidelineChoice {
    static let selectable: [GuidelineChoice] = GuidelineChoice.allCases.filter { $0 != .custom }
}
