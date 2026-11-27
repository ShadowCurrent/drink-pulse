import SwiftUI

// Debug-only Developer tools (plan 0052, D0052-2). Copy is verbatim, not in the string catalog,
// so no Debug text ships in Release (D0052-4).
#if DEBUG
struct DeveloperSection: View {
    @Environment(\.replayOnboarding) private var replayOnboarding

    var body: some View {
        Section {
            Button {
                replayOnboarding?()
            } label: {
                Label {
                    Text(verbatim: "Replay Onboarding")
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
            .accessibilityIdentifier("dp_dev_replay_onboarding")
        } header: {
            Text(verbatim: "Developer")
        } footer: {
            Text(verbatim: "Debug builds only. A rehearsal: Done saves nothing, then Today's entrance plays.")
        }
    }
}

#Preview {
    Form { DeveloperSection() }
}
#endif
