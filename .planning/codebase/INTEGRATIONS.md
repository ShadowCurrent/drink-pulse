---
last_mapped_commit: 8f0cefeb8c0f6f0169a34fe15b31dce3c8005d57
last_mapped_at: 2026-11-18
---
# External Integrations

**Analysis Date:** 2026-11-18

## Summary

DrinkPulse makes no network calls. The app has no backend, no third-party SDKs, no analytics, no crash reporters, and no account system (AGENTS.md privacy policy). All integrations are Apple on-device frameworks plus file import/export. CloudKit sync is planned but not enabled.

## APIs & External Services

**Network APIs:**
- None. No `URLSession`, `URLRequest`, WebSocket, or third-party HTTP client in `drinkpulse/`.
- The only `URL(string:)` use is `UIApplication.openSettingsURLString`, which opens the iOS Settings app (no network):
  - `drinkpulse/Features/Settings/Components/HealthSection.swift`
  - `drinkpulse/Features/Settings/Components/ReminderSection.swift`
  - `drinkpulse/Features/Settings/Components/WeeklySummarySection.swift`
  - `drinkpulse/Features/Settings/SettingsView.swift`

**Third-party SDKs:**
- None detected. No analytics, crash reporting, advertising, or attribution SDKs.

## Apple Health (HealthKit)

**Purpose:** Write each logged drink to Apple Health as Alcohol Consumption (`HKQuantityType(.numberOfAlcoholicBeverages)`), and read back own samples to avoid duplicates.

**Implementation:**
- Adapter: `drinkpulse/Services/HealthKitAdapter.swift` (`HKHealthStore`, type `numberOfAlcoholicBeverages`, 14 g pure alcohol = 1 standard drink)
- Protocol boundary: `drinkpulse/Services/HealthWriting.swift`; service: `drinkpulse/Services/HealthService.swift`; environment injection: `drinkpulse/Services/HealthServiceEnvironment.swift`
- Write triggers: `drinkpulse/Services/HealthWriteHooks.swift`
- Test doubles: `drinkpulse/Services/UITestHealthStore.swift` (UI tests), `drinkpulseTests/Services/FakeHealthStore.swift`
- Sample identity: device-local `HKQuantitySample.uuid`, stored with metadata key `HealthSampleMetadata.eventUUIDKey` linking to `ConsumptionEvent.uuid`; not synced, not exported (ADR `docs/decisions/0011-health-write-back-and-device-local-sample-identity.md`)

**Auth:**
- `HKHealthStore.requestAuthorization(toShare:read:)` for `numberOfAlcoholicBeverages` only
- Status via `authorizationStatus(for:)` mapped to `HealthAuthStatus` (`.authorized`, `.denied`, `.notDetermined`)
- Requested from onboarding (`drinkpulse/Features/Onboarding/Components/HealthStep.swift`) and Settings (`drinkpulse/Features/Settings/Components/HealthSection.swift`)

**Configuration:**
- Entitlement: `com.apple.developer.healthkit` = true in `drinkpulse/drinkpulse.entitlements`
- Usage strings in `drinkpulse/Info.plist`:
  - `NSHealthShareUsageDescription` - reads own Alcohol Consumption entries to avoid duplicates
  - `NSHealthUpdateUsageDescription` - writes logged drinks as Alcohol Consumption

## Local Notifications (UserNotifications)

**Purpose:** Drink reminders and weekly summary notifications, with action handling.

**Implementation:**
- Wrapper protocol: `drinkpulse/Services/NotificationScheduling.swift` (`UNUserNotificationCenter` retroactively conformed)
- Reminders: `drinkpulse/Services/ReminderService.swift`
- Weekly summary: `drinkpulse/Services/WeeklySummaryService.swift`
- Delegate and action responses: `drinkpulse/Services/NotificationActionHandler.swift`, assigned in `drinkpulse/drinkpulseApp.swift` (`UNUserNotificationCenter.current().delegate = handler`)
- Test doubles: `drinkpulse/Services/UITestNotificationCenter.swift`, `drinkpulseTests/Services/SlowNotificationCenter.swift`

**Auth:** `requestAuthorization(options: [.alert, .sound])`. Notifications are local only; no push entitlement or APNs token.

## Data Storage

**Primary database:**
- SwiftData on-device store in the app container. No remote database.
- Container and recovery: `drinkpulse/Domain/Persistence/StoreBootstrap.swift`, `drinkpulse/Domain/Persistence/ContainerLoadState.swift`, `drinkpulse/Domain/Persistence/StartupError.swift`
- Schemas: `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift` to `SchemaV4.swift`
- Migrations: `drinkpulse/Domain/Persistence/MigrationPlan.swift`
- Corrupt-store recovery copies stores aside (max 3 kept) in Application Support

**CloudKit (planned, OFF):**
- Container identifier constant: `iCloud.com.drinkpulse.app` (`StoreBootstrap.cloudKitContainerID`)
- Not wired: production `ModelConfiguration` has no CloudKit database option, and the entitlements file has no iCloud or CloudKit keys.
- Decisions: `docs/decisions/0001-swiftdata-cloudkit.md` (status Accepted), `docs/decisions/0010-cloudkit-ready-identity-and-lww.md` (CloudKit-safe model shape and last-write-wins identity)
- Enabling CloudKit is a one-way, owner-approved step (AGENTS.md).

**File storage:**
- User-initiated file import and export only, via SwiftUI `fileImporter` and `fileExporter` in `drinkpulse/Features/Settings/Components/DataSection.swift`
- Export: JSON backup (`drinkpulse/Domain/DataTransfer/BackupDocument.swift`, `BackupExport.swift`, `ExportBundle.swift`), content type `.json`
- Import: JSON backup (`DataImporter.swift`) and CSV from DrinkControl (`DrinkControlImporter.swift`), content types `.json`, `.commaSeparatedText`, `.plainText`
- Export files contain full history and are treated as sensitive; never auto-uploaded or cached (AGENTS.md)

**Caching:** None. No cache layer or external cache service.

## Authentication & Identity

- None. No login, accounts, or identity provider (out of scope per AGENTS.md).
- Apple ID is used only implicitly by the platform for future CloudKit sync; not requested by the app.

## Monitoring & Observability

**Error tracking:** None (no third-party crash reporter).

**Logs:**
- `os.Logger` (`import OSLog`) with subsystem `com.drinkpulse.app` and per-area categories: `startup`, `persistence`, `migration`, `performance`, `HealthService`, `ReminderService`, `WeeklySummaryService`, `NotificationActionHandler`, and others
- Examples: `drinkpulse/drinkpulseApp.swift`, `drinkpulse/Domain/Persistence/MigrationPlan.swift`, `drinkpulse/Diagnostics/ViewLoadLogger.swift`
- Logs stay on device; viewable via Console or Xcode. No telemetry export.

## CI/CD & Deployment

**Hosting:** Apple App Store distribution (no server hosting). Not yet configured in-repo.

**CI pipeline:** None detected. No `.github/workflows`, no `ci` config in the repository. Quality gates run locally via `xcodebuild` (see `AGENTS.md`).

**Developer tooling (not shipped):**
- Xcode MCP bridge: `.mcp.json` runs `xcrun mcpbridge`, requires Xcode open with `drinkpulse.xcodeproj`
- Claude Code hook: `.claude/hooks/check-xcode.sh` (SessionStart, warns when Xcode is not running)
- Claude Code plugin: `swiftui-expert@swiftui-expert-skill` enabled in `.claude/settings.json`

## Environment Configuration

**Required env vars:** None for the app. No `.env` file is used.

**Secrets location:** No secrets exist in the repository. Signing identity lives in the developer's Keychain; team ID `NXXRPVVLH8` is in the project file (not a secret).

**Local data files (sensitive, do not commit):**
- `drinkcontrol.csv` and `drinkpulse-backup-2026-06-12.json` at repository root are personal exports (existence noted only; contents not read)

## Webhooks & Callbacks

**Incoming:** None. No server endpoints, no URL schemes or universal links handling detected.

**Outgoing:** None. No webhooks, no HTTP callbacks.

## Privacy Constraints on Integrations

- No network calls except future SwiftData CloudKit sync (AGENTS.md)
- No analytics, crash reporters, or ad SDKs
- Health data (consumption, body metrics, goals) never leaves the device except through the user's Apple Health and their own export files
- `os.Logger` messages must not include user data (use `privacy: .private`)

---

*Integration audit: 2026-11-18*
