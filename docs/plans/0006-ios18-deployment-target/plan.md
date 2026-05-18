# Plan 0006 — Raise Deployment Target to iOS 18

**Status**: completed
**Frozen**: 2026-05-18
**Size**: small
**Created**: 2026-05-18

---

## Goal

Raise the minimum deployment target from iOS 17 to iOS 18. Justified by
current adoption data (2026-05-18): 66% iOS 26 · 24% iOS 18 · 10% Earlier —
"Earlier" covers iOS 17 and below combined. App is not yet published so no
existing users are affected.

Alongside the bump:
- Replace `.tabItem` with the iOS 18 `Tab {}` syntax in `ContentView`
- Replace the in-app biometric lock toggle with a system-settings deep link
  row (user-facing: "App Lock → opens Settings → DrinkPulse → Require Face ID")
- Remove all lock-related code that is no longer needed

---

## Changes

### 1 — Deployment target

`project.pbxproj`: change `IPHONEOS_DEPLOYMENT_TARGET = 17.0` →
`IPHONEOS_DEPLOYMENT_TARGET = 18.0` in all 4 build configurations
(app Debug, app Release, tests Debug, tests Release).

### 2 — TabView syntax (ContentView.swift)

Replace `.tabItem { Label(...) }` pattern with iOS 18 `Tab` view:

```swift
TabView {
    Tab(String(localized: "tab.home"), systemImage: "house.fill") {
        NavigationStack { DashboardView() }
    }
    Tab(String(localized: "tab.history"), systemImage: "calendar") {
        NavigationStack { HistoryView() }
    }
    Tab(String(localized: "tab.settings"), systemImage: "gear") {
        NavigationStack { SettingsView() }
    }
}
```

### 3 — In-app biometric lock → system settings deep link

**Files to delete:**
- `drinkpulse/Domain/BiometricService.swift`
- `drinkpulse/Features/Lock/AppLockState.swift`
- `drinkpulse/Features/Lock/LockScreenView.swift`
- `drinkpulseTests/BiometricServiceTests.swift`

**`UserProfile.swift`**: remove `appLockEnabled: Bool` field and its `init`
parameter. App not yet published — no migration required; local dev databases
can be reset by deleting the app.

**`drinkpulseApp.swift`**: remove `@State private var lockState = AppLockState()`
and `.environment(lockState)`.

**`ContentView.swift`**: remove `@Environment(AppLockState.self)`,
`@Environment(\.scenePhase)`, `@State private var didApplyInitialLock`,
`appLockEnabled` computed property, lock overlay ZStack, `.onAppear` lock
trigger, and `.onChange(of: scenePhase)` lock trigger.

**`SettingsView.swift`**: replace the Privacy & Security `Toggle` with a
tappable row that opens `UIApplication.openSettingsURLString`:

```
Privacy & Security
┌─────────────────────────────────────────┐
│  App Lock                          ›    │
└─────────────────────────────────────────┘
  Managed by iOS. To enable, go to
  Settings → DrinkPulse → Require Face ID.
```

Row is always tappable (no disabled state). `import UIKit` needed in
`SettingsView.swift` for `UIApplication`.

**`project.pbxproj`**: remove `INFOPLIST_KEY_NSFaceIDUsageDescription`;
deregister `BiometricServiceTests.swift` from PBXBuildFile, PBXFileReference,
group, and Sources build phase.

**`Localizable.xcstrings`**: remove 8 keys added in plan-0005
(`lock.authFailed`, `lock.authReason`, `lock.title`, `lock.unlock`,
`settings.appLock`, `settings.appLock.footer`,
`settings.appLock.footer.unavailable`) and add 2 new ones:

| Key | en | pl | de |
|---|---|---|---|
| `settings.systemLock` | App Lock | Blokada aplikacji | App-Sperre |
| `settings.systemLock.footer` | Managed by iOS. To enable, open Settings → DrinkPulse → Require Face ID. | Zarządzane przez iOS. Aby włączyć, otwórz Ustawienia → DrinkPulse → Wymagaj Face ID. | Von iOS verwaltet. Zum Aktivieren: Einstellungen → DrinkPulse → Face ID erforderlich. |

Note: `settings.section.privacy` key stays — the section header is still used.

### 4 — Docs & config

- `CLAUDE.md` — minimum deployment: iOS 17 → iOS 18
- `docs/product.md` — update minimum iOS reference
- `docs/architecture.md` — update minimum iOS reference
- `docs/roadmap.md` — mark "Biometric lock migration" and "New TabView syntax"
  as ✅ done under the iOS 18 conditional section; add note that deployment
  target bump is complete

---

## Implementation order

1. Delete lock files (`BiometricService`, `AppLockState`, `LockScreenView`,
   `BiometricServiceTests`)
2. `UserProfile` — remove `appLockEnabled`
3. `drinkpulseApp` + `ContentView` — remove lock wiring; restore `Tab {}` syntax
4. `SettingsView` — replace toggle with deep link row
5. `project.pbxproj` — bump target, remove Face ID key, deregister test file
6. `Localizable.xcstrings` — swap lock keys for systemLock keys
7. Docs: CLAUDE.md, product.md, architecture.md, roadmap.md

---

## Risks

- `Tab {}` TabView was the original iOS 26 API that was reverted in plan-0002
  when the target was lowered to iOS 17. With iOS 18 as minimum it is safe.
- Removing `appLockEnabled` from the SwiftData model is safe on live databases.
  SwiftData performs a lightweight migration automatically — the column stays
  orphaned in SQLite but causes no issues. No user action required.
