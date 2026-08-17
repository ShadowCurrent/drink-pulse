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
    @AppStorage(AppStorageKeys.onboardingDone) private var onboardingDone = false
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
        Self.assignNotificationDelegate(notificationHandler)
    }

    nonisolated private static func assignNotificationDelegate(_ handler: NotificationActionHandler) {
        Task.detached(priority: .userInitiated) {
            let center = UNUserNotificationCenter.current()
            await MainActor.run {
                center.delegate = handler
            }
        }
    }
    @State private var forceOnboardingPending = UITestSeed.forceShowOnboarding

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
                    Group {
                        if onboardingDone && !forceOnboardingPending {
                            RootShellView()
                                .onAppear {
                                    seedIfUITest(context: container.mainContext)
                                    let dedupeClock = ContinuousClock()
                                    let dedupeStart = dedupeClock.now
                                    RecordDeduplicator.sweep(in: container.mainContext)
                                    let dedupeMs = dedupeStart.duration(to: dedupeClock.now).milliseconds
                                    startupLog.notice("RecordDeduplicator.sweep finished in \(dedupeMs, privacy: .public) ms")
                                }
                        } else {
                            OnboardingView(onFinish: {
                                onboardingDone = true
                                forceOnboardingPending = false
                            })
                        }
                    }
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

    private func seedIfUITest(context: ModelContext) {
        guard UITestSeed.isActive else { return }
        let existing = (try? context.fetchCount(FetchDescriptor<ConsumptionEvent>())) ?? 0
        guard existing == 0 else { return }
        UITestSeed.seedFixtures(into: context)
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
