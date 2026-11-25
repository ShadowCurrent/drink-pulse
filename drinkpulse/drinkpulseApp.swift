import SwiftUI
import SwiftData
import UserNotifications
import OSLog

private let startupLog = Logger(subsystem: "com.drinkpulse.app", category: "startup")

private extension Duration {
    var milliseconds: Int64 {
        let (seconds, attoseconds) = components
        return seconds * 1000 + attoseconds / 1_000_000_000_000_000
    }
}

@main
struct drinkpulseApp: App {
    @AppStorage(AppStorageKeys.colorScheme) private var colorSchemeRaw: String = "system"
    private let notificationHandler = NotificationActionHandler()
    @State private var healthService = HealthService()
    private let schema = Schema([
        DrinkTemplate.self,
        ConsumptionEvent.self,
        UserProfile.self,
    ])

    init() {
        UITestSeed.resetTransientDefaults()
        if UITestSeed.seedPendingOpenInsights {
            UserDefaults.standard.set(true, forKey: AppStorageKeys.pendingOpenInsights)
        }
        let clock = ContinuousClock()
        let start = clock.now
        Self.assignNotificationDelegate(notificationHandler)
        let assignMs = start.duration(to: clock.now).milliseconds
        startupLog.notice("Notification delegate assigned in \(assignMs, privacy: .public) ms")
    }

    static func assignNotificationDelegate(_ handler: NotificationActionHandler) {
        UNUserNotificationCenter.current().delegate = handler
    }
    @State private var containerState: ContainerLoadState = .loading
    @State private var isRetrying = false

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": .light
        case "dark":  .dark
        default:      nil
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch containerState {
                case .loading:
                    Color(.systemBackground).ignoresSafeArea()
                case .ready(let container):
                    // Always the shell; first run presents onboarding as a cover over it (D0048-1).
                    RootShellView()
                        .modelContainer(container)
                case .failed(let error):
                    StartupErrorView(error: error, isRetrying: isRetrying, onRetry: retryContainerLoad)
                }
            }
            .preferredColorScheme(preferredColorScheme)
            .environment(\.healthService, healthService)
            .task { await loadContainerIfNeeded() }
        }
    }

    @MainActor
    private func loadContainerIfNeeded() async {
        guard case .loading = containerState else { return }
        let clock = ContinuousClock()
        let start = clock.now
        defer {
            let elapsedMs = start.duration(to: clock.now).milliseconds
            startupLog.notice("Container load finished in \(elapsedMs, privacy: .public) ms")
        }
        if UITestSeed.isActive {
            do {
                containerState = .ready(try UITestSeed.makeContainer(schema: schema))
                ViewLoadNavigation.markRequested()
            } catch {
                containerState = .failed(StartupError(underlying: error))
            }
            return
        }
        let configuration = StoreBootstrap.productionConfiguration(schema: schema)
        let storeExistedBefore = FileManager.default.fileExists(atPath: configuration.url.path)
        startupLog.notice("Container load starting — pre-existing store: \(storeExistedBefore, privacy: .public)")
        do {
            containerState = .ready(try StoreBootstrap.makeContainer(schema: schema, configuration: configuration))
            ViewLoadNavigation.markRequested()
        } catch {
            containerState = .failed(StartupError(underlying: error))
        }
    }

    @MainActor
    private func retryContainerLoad() {
        isRetrying = true
        containerState = .loading
        Task {
            await loadContainerIfNeeded()
            isRetrying = false
        }
    }
}
