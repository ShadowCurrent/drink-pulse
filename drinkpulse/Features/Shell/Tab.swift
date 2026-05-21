import Foundation

/// App-level tab destinations. Named `AppTab` to avoid collision with SwiftUI's `Tab` type.
enum AppTab: Hashable {
    case home
    case insights
    case history
    case settings
}
