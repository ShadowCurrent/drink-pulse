import SwiftUI

extension Color {
    /// App-wide brand accent (Ember). Single source of truth is the
    /// `AccentColor` asset (drives controls + previews); this is a named alias
    /// for non-control uses such as tinted backgrounds.
    static let dpAccent = Color.accentColor
}
