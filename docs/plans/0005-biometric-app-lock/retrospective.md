# Retrospective — Plan 0005

**Completed**: 2026-05-18

## What went well

- `LAPolicy.deviceOwnerAuthentication` handled the entire auth flow without any
  custom UI for the passcode fallback — iOS does it automatically.
- Splitting lock state (transient `AppLockState`) from the persisted flag
  (`UserProfile.appLockEnabled`) kept each concern in exactly one place.
- `BiometricService` with an injected `LAContext` factory made unit tests possible
  without a protocol or mock framework.
- SwiftData handled the new `appLockEnabled` field as a lightweight migration with
  zero extra work — inline default was sufficient.

## What was harder than expected

- `NSFaceIDUsageDescription`: no standalone Info.plist exists in the project
  (uses `GENERATE_INFOPLIST_FILE = YES`). Required editing `project.pbxproj`
  directly via `INFOPLIST_KEY_NSFaceIDUsageDescription`.

## Decisions made during execution

- No deviations from the frozen plan.

## What to watch

- If the user disables the device passcode while `appLockEnabled` is `true`,
  the next foreground will fail auth and show the "Try again" screen. No
  automatic disable is implemented. Edge case; acceptable for now.
