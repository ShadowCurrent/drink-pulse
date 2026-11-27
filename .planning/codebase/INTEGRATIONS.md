---
last_mapped_commit: 19ce3159ee64540aaea8411fc85f24e6bea68714
last_mapped_at: 2026-11-27
---
# External Integrations

**Analysis Date:** 2026-11-27

## Summary

DrinkPulse makes no network calls. No `URLSession`, `URLRequest`, or socket code exists under `drinkpulse/`. The app has no backend, no third-party SDKs, no analytics, no crash reporters, and no account system (`AGENTS.md` privacy policy). Integrations are Apple on-device frameworks plus local file import/export. CloudKit sync is planned but disabled.

## APIs & External Services

**Network APIs:**
- None.
- The only `URL(string:)` use opens the iOS Settings app via `UIApplication.openSettingsURLString` (no network):
  - `drinkpulse/Features/Settings/Components/HealthSection.swift`
  - `drinkpulse/Features/Settings/Components/ReminderSection.swift`
  - `drinkpulse/Features/Settings/Components/WeeklySummarySection.swift`
  - `drinkpulse/Features/Settings/SettingsView.swift`

**Third-party SDKs:**
- None. No analytics, crash reporting, advertising, or attribution SDKs.

## Apple Health (HealthKit)

**Purpose:** Write each logged drink to Apple Health as Alcohol Consumption (`HKQuantityType(.numberOfAlcoholicBeverages)`) and read back own samples to avoid duplicate writes.

**Implementation:**
- Adapter: `drinkpulse/Services/HealthKitAdapter.swift` (wraps `HKHealthStore`)
- Protocol boundary: `drinkpulse/Services/HealthWriting.swift`
- Service: `drinkpulse/Services/HealthService.swift`
- Environment injection: `drinkpulse/Services/HealthServiceEnvironment.swift`
- Write triggers: `drinkpulse/Services/HealthWriteHooks.swift`
- Test doubles: `drinkpulse/Services/UITestHealthStore.swift` (UI tests), `drinkpulseTests/Services/FakeHealthStore.swift` (unit tests)
- Mapping: 14 g pure alcohol = 1 standard drink (`docs/domain.md`)
- Sample identity: device-local `HKQuantitySample.uuid`, stored under metadata key `HealthSampleMetadata.eventUUIDKey`, linking to `ConsumptionEvent.uuid`. Not synced, not exported. A foreign or absent sample id means "write fresh." (`docs/decisions/0011-health-write-back-and-device-local-sample-identity.md`)

**Auth:**
- `HKHealthStore.requestAuthorization(toShare:read:)` for `numberOfAlcoholicBeverages` only
- Status via `authorizationStatus(for:)`, mapped to `HealthAuthStatus` (`.authorized`, `.denied`, `.notDetermined`)
- Requested from onboarding (`drinkpulse/Features/Onboarding/Components/HealthStep.swift`) and Settings (`drinkpulse/Features/Settings/Components/HealthSection.swift`)

**Configuration:**
- Entitlement: `com.apple.developer.healthkit` = true, `com.apple.developer.healthkit.access` = empty array (`drinkpulse/drinkpulse.entitlements`)
- Usage strings (`drinkpulse/Info.plist`):
  - `NSHealthShareUsageDescription` - reads own Alcohol Consumption entries to avoid duplicates
  - `NSHealthUpdateUsageDescription` - writes logged drinks as Alcohol Consumption

## Local Notifications (UserNotifications)

**Purpose:** Drink reminders, weekly summary notifications, and notification action handling.

**Implementation:**
- Wrapper protocol: `drinkpulse/Services/NotificationScheduling.swift` (`UNUserNotificationCenter` conformance)
- Reminders: `drinkpulse/Services/ReminderService.swift`
- Weekly summary: `drinkpulse/Services/WeeklySummaryService.swift`
- Delegate and actions: `drinkpulse/Services/NotificationActionHandler.swift`, assigned in `drinkpulse/drinkpulseApp.swift`
- Test doubles: `drinkpulse/Services/UITestNotificationCenter.swift`, `drinkpulseTests/Services/SlowNotificationCenter.swift`

**Auth:** `requestAuthorization(options: [.alert, .sound])`. Local only. No push entitlement, no APNs token.

## Data Storage

**Databases:**
- SwiftData (SQLite-backed) in the app container, local only
  - Connection: none (no URL or credentials; `ModelConfiguration(schema:isStoredInMemoryOnly: false)`)
  - Client: SwiftData `ModelContainer` / `@Query` / `ModelContext`
  - Schema and migrations: see `.planning/codebase/STACK.md` (Persistence Layout)
- CloudKit: NOT active. `StoreBootstrap.cloudKitContainerID = "iCloud.com.drinkpulse.app"` in `drinkpulse/Domain/Persistence/StoreBootstrap.swift` is declared but unused for the production store. No iCloud entitlement exists.

**File Storage:**
- Local filesystem only, via SwiftUI file importer/exporter:
  - Backup JSON export/import (`drinkpulse/Domain/DataTransfer/BackupDocument.swift`, `drinkpulse/Domain/DataTransfer/ExportBundle.swift`)
  - Legacy CSV import from DrinkControl (`drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift`)
  - UI in `drinkpulse/Features/Settings/Components/DataSection.swift`
- Export files contain full user history. Treat as sensitive. Never auto-upload or cache.

**Caching:**
- None. No cache service.

## Authentication & Identity

**Auth Provider:**
- None. No login or accounts (out of scope per `AGENTS.md`).
- Health permissions are the only identity-adjacent authorization (HealthKit, above).

## Monitoring & Observability

**Error Tracking:**
- None (no third-party crash reporter, by policy).

**Logs:**
- `os.Logger` with subsystem `com.drinkpulse.app` and per-area categories (e.g. `startup`, `ReminderService`, `ReminderSection`, `WeeklySummarySection`). Viewed through Apple's on-device tooling only.
- View load diagnostics: `drinkpulse/Diagnostics/ViewLoadLogger.swift`
- Policy: no PII or health values in logs; interpolated user data stays `privacy: .private`.

## CI/CD & Deployment

**Hosting:**
- None. No server. Distribution through Apple (App Store) only.

**CI Pipeline:**
- None detected in the repo (no `.github/` workflows). Quality gates run locally via `xcodebuild` (`AGENTS.md`).

## Developer Tooling (not shipped)

- Xcode MCP bridge: `.mcp.json` runs `xcrun mcpbridge` over stdio. Requires Xcode open with `drinkpulse.xcodeproj`.
- Claude Code: `.claude/settings.json` (SessionStart hook `.claude/hooks/check-xcode.sh`; `swiftui-expert-skill` plugin enabled)
- Local-only data files in repo root (not part of the app): `drinkcontrol.csv`, `drinkpulse-backup-2026-06-12.json`. Contain personal data; do not commit or quote.

## Environment Configuration

**Required env vars:**
- None. The app reads no environment variables at runtime.

**Secrets location:**
- None. No API keys, tokens, or credentials exist in the repo. Signing identity is handled by Xcode Automatic signing (team `NXXRPVVLH8`).

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Planned Integration (not active)

- CloudKit sync via SwiftData's built-in integration: container `iCloud.com.drinkpulse.app`. Requires an iCloud/CloudKit entitlement and a CloudKit-enabled `ModelConfiguration`. Enabling it is one-way and needs explicit owner approval (`AGENTS.md`). Decision: `docs/decisions/0001-swiftdata-cloudkit.md`.

---

*Integration audit: 2026-11-27*
