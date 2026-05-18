import SwiftUI
import LocalAuthentication

struct LockScreenView: View {
    let onUnlock: () -> Void

    @State private var authFailed = false
    private let service = BiometricService()

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: lockIcon)
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                Text(String(localized: "lock.title"))
                    .font(.title2)
                    .fontWeight(.semibold)

                if authFailed {
                    Text(String(localized: "lock.authFailed"))
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await attemptAuth() }
                } label: {
                    Label(String(localized: "lock.unlock"), systemImage: lockIcon)
                        .frame(maxWidth: 280)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .onAppear {
            Task { await attemptAuth() }
        }
    }

    private var lockIcon: String {
        switch service.biometryType {
        case .faceID:   return "faceid"
        case .touchID:  return "touchid"
        default:        return "lock.fill"
        }
    }

    private func attemptAuth() async {
        authFailed = false
        do {
            try await service.authenticate(
                reason: String(localized: "lock.authReason")
            )
            onUnlock()
        } catch {
            let code = (error as? LAError)?.code
            if code != .userCancel && code != .systemCancel {
                authFailed = true
            }
        }
    }
}

#Preview {
    LockScreenView(onUnlock: {})
}
