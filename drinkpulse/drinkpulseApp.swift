import SwiftUI
import SwiftData
import UserNotifications

@main
struct drinkpulseApp: App {
    @AppStorage(AppStorageKeys.onboardingDone) private var onboardingDone = false
    @AppStorage(AppStorageKeys.colorScheme) private var colorSchemeRaw: String = "system"
    /// Retained delegate that routes a reminder tap to "open Add Drink"
    /// (plan-0016). Set as the notification-centre delegate in `init` so a
    /// cold launch from a tapped reminder is still captured.
    private let notificationHandler = NotificationActionHandler()
    /// Single shared Apple Health write-back service (plan-0036). Provided into
    /// the environment so Settings (W4), onboarding (W8) and the write hooks (W5)
    /// share one instance (its per-event serialization holds only per instance).
    /// Picks the real `HKHealthStore` adapter, or the non-prompting UI-test stub
    /// under `-dp_uitest`.
    @State private var healthService = HealthService()
    /// Schema for the app's three model types. A plain instance `let` — no
    /// longer wrapped in an eagerly-evaluated container-creation closure
    /// (STARTUP-02).
    private let schema = Schema([
        DrinkTemplate.self,
        ConsumptionEvent.self,
        UserProfile.self,
    ])

    init() {
        // Clear cross-run UserDefaults pollution before any view reads it
        // (no-op in production). Keeps reminder UI tests deterministic.
        UITestSeed.resetTransientDefaults()
        // ENGG-07 tap-routing UI test hook: stands in for a real weekly-summary
        // notification tap having already happened before this cold launch.
        // Gated purely on the launch argument; inert whenever it is absent, i.e.
        // always inert in production.
        if UITestSeed.seedPendingOpenInsights {
            UserDefaults.standard.set(true, forKey: AppStorageKeys.pendingOpenInsights)
        }
        UNUserNotificationCenter.current().delegate = notificationHandler
    }
    /// One-shot flag: when `-dp_force_onboarding YES` is active, starts `true`
    /// and flips to `false` after `OnboardingView.onFinish` fires, allowing
    /// the normal `onboardingDone` gate to take over. Inert in production
    /// (UITestSeed.forceShowOnboarding is always false outside UI tests).
    @State private var forceOnboardingPending = UITestSeed.forceShowOnboarding

    /// Container lifecycle state (STARTUP-02, D-11, D-12). Populated by a
    /// `.task` that runs after the first frame renders — never by `init` or
    /// an eagerly-evaluated stored property. `.loading`'s subtree renders
    /// only the existing system launch background (no new UI); `.ready`'s
    /// subtree is the only one `.modelContainer(_:)` ever attaches to;
    /// `.failed`'s subtree shows `StartupErrorView` instead of crashing.
    @State private var containerState: ContainerLoadState = .loading
    /// `true` while a Retry-triggered container load is in flight (D-10) —
    /// disables the Retry button and shows an inline spinner until it
    /// resolves.
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
                    // D-11: no new UI here — the existing system-generated
                    // launch background simply holds until the container
                    // resolves.
                    Color(.systemBackground).ignoresSafeArea()
                case .ready(let container):
                    Group {
                        // forceOnboardingPending starts true when -dp_force_onboarding YES
                        // is in the launch args (onboarding locale-default UI tests). It is
                        // cleared by onFinish, after which normal routing resumes. Inert in
                        // production — UITestSeed.forceShowOnboarding is always false there.
                        if onboardingDone && !forceOnboardingPending {
                            RootShellView()
                                .onAppear {
                                    seedIfUITest(context: container.mainContext)
                                    // Cross-device de-dup (plan-0023): collapse any records
                                    // that share a uuid (backup re-import, or — Phase B —
                                    // a CloudKit sync that delivered the same logical record
                                    // twice). Idempotent: a clean store is a no-op.
                                    RecordDeduplicator.sweep(in: container.mainContext)
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

    // Inserts deterministic fixtures into the in-memory store when the UI-test
    // hook is active. No-op in production (UITestSeed.isActive is false).
    private func seedIfUITest(context: ModelContext) {
        guard UITestSeed.isActive else { return }
        // Idempotent: .onAppear can fire more than once; only seed an empty store
        // so the shell re-appearing never inserts duplicate fixtures.
        let existing = (try? context.fetchCount(FetchDescriptor<ConsumptionEvent>())) ?? 0
        guard existing == 0 else { return }
        UITestSeed.seedFixtures(into: context)
    }

    /// Opens the model container (STARTUP-02). Guarded so a second
    /// invocation while already `.ready` — or already re-loading via
    /// `retryContainerLoad`'s own `Task` — is a no-op (Pitfall 3).
    @MainActor
    private func loadContainerIfNeeded() async {
        guard case .loading = containerState else { return }
        if UITestSeed.isActive {
            do {
                containerState = .ready(try UITestSeed.makeContainer(schema: schema))
            } catch {
                containerState = .failed(StartupError(underlying: error))
            }
            return
        }
        // CloudKit OFF (plan-0023 Phase B gated) — the single flip point lives in
        // StoreBootstrap.productionConfiguration.
        let configuration = StoreBootstrap.productionConfiguration(schema: schema)
        do {
            containerState = .ready(try StoreBootstrap.makeContainer(schema: schema, configuration: configuration))
        } catch {
            containerState = .failed(StartupError(underlying: error))
        }
    }

    /// Re-attempts the full container-open sequence from scratch (D-06,
    /// D-07) — never a "create a fresh empty store" shortcut. Always
    /// re-invokes `loadContainerIfNeeded()`, the exact same path used at
    /// launch, so Retry always re-runs `StoreBootstrap.makeContainer`'s
    /// full open→recover→open sequence.
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
