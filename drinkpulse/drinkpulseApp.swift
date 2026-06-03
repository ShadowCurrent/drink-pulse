import SwiftUI
import SwiftData

@main
struct drinkpulseApp: App {
    @AppStorage("dp_onboarding_done") private var onboardingDone = false
    @AppStorage("dp_theme") private var theme: DPTheme = .ember
    @AppStorage("dp_color_scheme") private var colorSchemeRaw: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": .light
        case "dark":  .dark
        default:      nil
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DrinkTemplate.self,
            ConsumptionEvent.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try StoreBootstrap.makeContainer(schema: schema, configuration: modelConfiguration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingDone {
                    RootShellView()
                } else {
                    OnboardingView(onFinish: { onboardingDone = true })
                }
            }
            .environment(\.dpTheme, theme)
            .tint(theme.primary)
            .preferredColorScheme(preferredColorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
