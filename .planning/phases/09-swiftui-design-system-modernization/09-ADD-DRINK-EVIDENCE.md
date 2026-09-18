# Add Drink evidence — Phase 09

**Date:** 2026-09-18  
**Toolchain:** Xcode 27.0 (27A266a), iPhoneSimulator SDK 27.0  
**Runtime:** iOS 27.0 — iPhone 18 Pro  
**LOCAL_IOS_27_UDID:** `1D35E1B8-4141-4EFF-A493-52CB37B600A5`

## Changed and checked paths

- `drinkpulse/Features/AddDrink/AddDrinkView.swift` reads the sheet-root `@Environment(\.dismiss)` action.
- `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift` passes the typed `DismissAction` through the existing navigation route and invokes it for grid cancellation.
- `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift` uses that same action for detail cancellation.
- `drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift` invokes it only after insertion, identity de-duplication, and Health write hooks.
- `drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift` covers originating-tab grid cancellation and save-plus-persistence.
- `drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift` covers semantic Cancel discovery and the Xcode 27 `voiceOverService` dismissal path.

## Official Apple API basis

Xcode MCP `DocumentationSearch` was used for the official SwiftUI `DismissAction` and XCTest `XCUIVoiceOverService` documentation. `DismissAction` is a `@MainActor`, `Sendable` action obtained from `EnvironmentValues.dismiss`; Apple documents that its behavior depends on the environment where it is read. The action is therefore read at the presented sheet root and passed explicitly to the pushed destination. `XCUIVoiceOverService` supplies the iOS 27 test-only VoiceOver enable, speech, navigation, and disable APIs used by the regression.

## Automated checks

| Check | Source | Result |
|---|---|---|
| Build for testing | Xcode MCP `BuildProject(buildForTesting: true)` | Pass |
| Add Drink UI regressions | Xcode MCP `RunSomeTests`: `drinkpulseUITests/AddDrinkFlowUITests` | Pass — 6/6 |
| Shell and VoiceOver regressions | Xcode MCP `RunSomeTests`: `drinkpulseUITests/ShellNavigationUITests` | Pass — 4/4 |
| Combined focused regression run | Xcode MCP `RunSomeTests` for both suites | Pass — 10/10 |

## Human check

**Result: pass.** On the selected iOS 27 simulator, the owner verified every changed Add Drink path:

- From a non-Home tab, grid Cancel returns to the originating tab.
- From a drink-detail screen, Cancel returns to the originating tab.
- Saving returns to the originating tab and preserves the new drink in History.
- The visible Cancel control has the expected semantic label and works with VoiceOver.

The owner also reported a separate pre-existing-or-uncertain Dashboard visual issue: after opening and closing Add Drink from Settings, then switching to Dashboard, Dashboard flashes for about one second. This observation is not recorded as an Add Drink acceptance failure; it is being reproduced and diagnosed separately before any source change.

No full-suite result is claimed.
