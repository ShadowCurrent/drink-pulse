import SwiftUI

/// App-level tab destinations. Named `AppTab` to avoid collision with SwiftUI's `Tab` type.
enum AppTab: String, CaseIterable {
    case home
    case insights
    case history
    case settings

    var label: String {
        switch self {
        case .home:     String(localized: "tab.home")
        case .insights: String(localized: "tab.insights")
        case .history:  String(localized: "tab.history")
        case .settings: String(localized: "tab.settings")
        }
    }

    var icon: String {
        switch self {
        case .home:     "house"
        case .insights: "chart.bar"
        case .history:  "clock"
        case .settings: "gearshape"
        }
    }

    var activeIcon: String {
        switch self {
        case .home:     "house.fill"
        case .insights: "chart.bar.fill"
        case .history:  "clock.fill"
        case .settings: "gearshape.fill"
        }
    }
}
