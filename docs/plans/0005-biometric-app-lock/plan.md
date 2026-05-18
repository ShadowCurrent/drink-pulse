# Plan 0005 — Biometric App Lock

**Status**: in-progress  
**Size**: medium  
**Created**: 2026-05-18  
**Frozen**: 2026-05-18  

---

## Goal

Add a toggle in Settings that lets the user lock DrinkPulse behind
Face ID or Touch ID. When enabled, the app locks immediately whenever
it transitions to the background, and requires biometric authentication
to unlock when it returns to the foreground.

## Behaviour spec

| Scenario | Result |
|---|---|
| Toggle enabled, app goes to background | `isLocked = true` |
| App returns to foreground while locked | Lock screen appears, biometric prompt fires automatically |
| Authentication succeeds | Lock screen dismissed |
| Authentication fails / cancelled | Lock screen stays; "Try again" button visible |
| Device has no biometrics but has a passcode | Toggle available; auth goes straight to passcode UI |
| Device has no passcode set at all | Toggle greyed out with explanatory footnote |
| Toggle disabled at any time | No lock, no overlay |

Policy: `LAPolicy.deviceOwnerAuthentication` — biometrics first; if
they fail or are unavailable, iOS automatically shows the device
passcode entry UI (identical to unlocking the iPhone). No custom
app-level PIN is involved — everything is handled by the system.
The toggle is available on any device that has a passcode set.

## Architecture

### New types

| File | Type | Role |
|---|---|---|
| `Domain/BiometricService.swift` | `struct BiometricService` (Sendable) | Wraps `LAContext`. Exposes `var canAuthenticate: Bool` (true when device passcode is set) and `func authenticate() async throws`. |
| `Features/Lock/AppLockState.swift` | `@Observable @MainActor final class AppLockState` | Single source of truth for transient lock state (`isLocked: Bool`). Injected app-wide via `@Environment`. |
| `Features/Lock/LockScreenView.swift` | `struct LockScreenView` | Full-screen overlay. On `.onAppear` triggers auth automatically. Shows "Try again" button on failure. |

### Modified files

| File | Change |
|---|---|
| `Domain/UserProfile.swift` | Add `var appLockEnabled: Bool = false` (new SwiftData field with default — lightweight migration, no schema version bump required) |
| `drinkpulseApp.swift` | Create `AppLockState()` as `@State`, inject into environment via `.environment(lockState)` |
| `ContentView.swift` | (1) `@Query` profiles to read `appLockEnabled`; (2) watch `@Environment(\.scenePhase)`; (3) on `.background` → if enabled, call `lockState.lock()`; (4) overlay `LockScreenView` when `lockState.isLocked` |
| `Features/Settings/SettingsView.swift` | Add "Privacy & Security" section with a `Toggle` bound to `profile.appLockEnabled`; disabled + footnote when `!BiometricService().canAuthenticate` (no device passcode) |

### Flow diagram

```
scenePhase → .background
    └─ profile.appLockEnabled == true
           └─ AppLockState.isLocked = true

scenePhase → .active  AND  isLocked == true
    └─ LockScreenView appears (ZStack overlay in ContentView)
           └─ .onAppear → BiometricService.authenticate()
                  ├─ success → AppLockState.isLocked = false
                  └─ failure → show "Try again" button
```

## Localization strings

Strings needed in both `en` and `pl` catalogs:

| Key | en | pl |
|---|---|---|
| `settings.section.privacy` | Privacy & Security | Prywatność i bezpieczeństwo |
| `settings.appLock` | App Lock | Blokada aplikacji |
| `settings.appLock.footer` | Uses Face ID, Touch ID, or your device passcode. Requires a device passcode to be set. | Używa Face ID, Touch ID lub kodu urządzenia. Wymaga ustawionego kodu urządzenia. |
| `lock.unlock` | Unlock | Odblokuj |
| `lock.tryAgain` | Try Again | Spróbuj ponownie |
| `lock.authFailed` | Authentication failed | Uwierzytelnianie nie powiodło się |

The button in `LockScreenView` uses `LAContext.biometryType` at
runtime to pick the right SF Symbol (`faceid` / `touchid` /
`lock.fill` when biometrics unavailable but passcode available).
The localized string `lock.unlock` is always shown as the button label.

## Tests

File: `drinkpulseTests/BiometricServiceTests.swift`

- `canAuthenticate` returns `false` when `LAContext` cannot evaluate
  `.deviceOwnerAuthentication` (no passcode set — tested via mock).
- `authenticate()` propagates `LAError.userCancel` correctly.

Note: actual biometric prompts cannot be triggered in unit tests.
The service will be designed with a protocol/closure injection point
for testability.

## Implementation order

1. `BiometricService` — pure logic, testable, no SwiftUI
2. `AppLockState` — simple `@Observable`
3. `UserProfile` — add `appLockEnabled` field
4. `LockScreenView` — UI only, receives closures for unlock/retry
5. `drinkpulseApp` + `ContentView` — wire up state, scenePhase, overlay
6. `SettingsView` — add toggle section
7. Localization strings
8. Tests

## Open issues / risks

- `LocalAuthentication` framework must be linked in Xcode (system
  framework, no SPM package needed — just `import LocalAuthentication`).
- `NSFaceIDUsageDescription` key must be added to `Info.plist` (or
  Xcode's "Privacy - Face ID Usage Description" target setting) before
  App Store submission. **Must be done as part of this plan.**
- If `appLockEnabled` is `true` and the user later removes the device
  passcode in iOS Settings, the next foreground will fail auth.
  Behaviour: lock screen stays with "Try again" — user must go to iOS
  Settings to set a passcode. No automatic disable is added (edge case,
  acceptable). With `.deviceOwnerAuthentication`, un-enrolling
  biometrics alone is not a problem — the policy falls back to passcode.
