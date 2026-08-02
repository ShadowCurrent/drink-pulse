# External Integrations

**Analysis Date:** 2026-08-02

## APIs & External Services

**None.** No REST APIs, SDKs, or external services are used. The app is entirely on-device.

---

## Data Storage

**Primary Database:**
- SwiftData (on-device SQLite)
  - Models: `DrinkTemplate`, `ConsumptionEvent`, `UserProfile` (`Domain/` layer)
  - Schema versions: V1–V4 snapshots in `Domain/Persistence/Schemas/`
  - Migrations: `MigrationPlan` defines transitions (V1→V2, V2→V3, V3→V4)
  - Container: created in `drinkpulseApp.swift` via `StoreBootstrap.makeContainer()`
  - Access: views query via `@Query`, mutations via `@Environment(\.modelContext)`

**File Storage:**
- Local filesystem only
  - Exported backups: JSON format via `BackupDocument` and `BackupExport`
  - Import: document picker via `CoreTransferable` + `DataImporter`
  - DrinkControl legacy import: CSV parsing via `DrinkControlImporter`
  - No cloud file storage; exports are user-initiated

**Caching:**
- No persistent cache layer beyond SwiftData
- Transient state: `@State` (views), `@Observable` (view models)

## Authentication & Identity

**Auth Provider:**
- None — app requires no login or account
- Privacy-first: all data stays on-device

**Device Identity (HealthKit-specific):**
- `ConsumptionEvent.healthKitUUID` — device-local cache of Apple Health sample UUID
- Not synced, not exported — purely for device-local deduplication

## Apple Health Integration

**Type: Optional, opt-in write-only**

**Framework & Entitlement:**
- Framework: `HealthKit` (iOS 26+)
- Entitlement: `com.apple.developer.healthkit` in `.entitlements`
- Permission type: write access (user grants via system prompt)

**What is Written:**
- Sample type: `HKQuantityType(.numberOfAlcoholicBeverages)` — count
- Conversion: event's `pureAlcoholGrams ÷ 14.0` (Apple's standard drink = 14 g)
- Metadata: `dp_event_uuid` — links Health sample back to in-app event for deduplication
- Trigger: automatic on log/edit/delete via `HealthWriteHooks` (plan-0036)

**Implementation:**
- Service: `HealthService` — orchestrates write/update/remove (`Services/HealthService.swift`)
- Adapter: `HealthKitAdapter` — thin wrapper over `HKHealthStore` (`Services/HealthKitAdapter.swift`)
- Fake: `UITestHealthStore` — in-memory stub for UI tests (no permission prompts)
- Error handling: best-effort, non-blocking; Health failures never halt in-app operations
- Concurrency: per-event serial task chains prevent race conditions on rapid edit/delete

**Authorization:**
- Read: not used (app doesn't query Health data)
- Write: user-requested during onboarding or Settings; stored in Health's access controls
- Failures: logged but not surfaced (Health is optional, not critical path)

---

## Local Notifications

**Type: Opt-in daily reminder**

**Framework:** UserNotifications (iOS 26+)

**What Triggers:**
- Daily local notification: "Time to log your drinks"
- User sets time via Settings time picker (default: 21:00)
- Repeats daily; user can enable/disable
- Separate weekly summary notification (via `WeeklySummaryService`)

**Implementation:**
- Service: `ReminderService` — schedules/cancels requests (`Services/ReminderService.swift`)
- Protocol: `NotificationScheduling` — injected for testability
- Fake: `UITestNotificationCenter` — in-memory stub for UI tests
- Storage: reminder time via `@AppStorage` + `AppStorageKeys`
- Idempotency: fixed request ID (`dp.daily.log.reminder`) means reschedule overwrites

**Tap Handler:**
- `NotificationActionHandler` — listens via `UNUserNotificationCenter.delegate`
- Tapping reminder opens app to AddDrink (cold launch or foreground)
- Weekly summary tap navigates to Insights tab

---

## CloudKit & Sync

**Status: Planned, currently disabled (plan-0023 Phase B)**

**Framework:** SwiftData's built-in CloudKit integration

**Current State:**
- Entitlement not provisioned; feature is gated
- Gate point: `StoreBootstrap.productionConfiguration()` in `Domain/Persistence/StoreBootstrap.swift`
- Schema is already CloudKit-compatible (Phase A completed):
  - No `@Attribute(.unique)`
  - All properties optional or have defaults
  - `uuid` identity + `modifiedDate` LWW clock

**When Enabled (Phase B, future):**
- SwiftData handles bidirectional sync automatically
- Private CloudKit database per iCloud user
- Conflict resolution: last-write-wins via `modifiedDate` (ADR-0011)
- Deduplication: `RecordDeduplicator.sweep()` on launch + post-sync (ADR-0010)
- Requires: iCloud account, provisioned container `iCloud.com.drinkpulse.app`

---

## Export/Import

**Type: User-initiated JSON backup**

**Export Format:**
- File: `BackupDocument` (SwiftUI `FileDocument`)
- Contents:
  - Version number (v1 or v2)
  - Optional `UserProfile` (sex, DOB, guideline choice, units)
  - Array of `ExportRecord` (ConsumptionEvent snapshots with `uuid`, `modifiedDate`)
  - Array of `TemplateRecord` (DrinkTemplate snapshots)
- File type: custom via `UniformTypeIdentifiers`
- Mechanism: SwiftUI `.fileExporter` with off-main-actor encoding

**Import Process:**
- Source: document picker via `CoreTransferable`
- Parsing: `DataImporter` decodes JSON v1 or v2
- Merging: upsert strategy (identity-based with LWW via `modifiedDate`)
- Profile: replaced (not merged) on import
- Error handling: detailed `ImportError` enum, shown to user

**Legacy DrinkControl Import:**
- Source: CSV from competing app DrinkControl
- Parser: `DrinkControlImporter` derives ABV guesses, maps categories
- Used for: one-time historical migration
- Not reversible

**Data Protection:**
- Exports contain full history + body metrics — treated as sensitive
- Never auto-uploaded; user explicitly initiates
- Imports validate all fields before SwiftData write

---

## Webhooks & Callbacks

**Incoming:**
- None — no server endpoints

**Outgoing:**
- None — no external APIs called

---

## Environment Configuration

**Required Env Vars:**
- None — app has no external service dependencies

**Secrets Location:**
- None — no API keys, OAuth tokens, or credentials
- All configuration via `@AppStorage` (UserDefaults) — user preferences only

**Access Control:**
- HealthKit: user grants/denies via system prompt
- Notifications: user grants/denies via system prompt
- App data: protected by iOS app sandbox

---

## Monitoring & Observability

**Error Tracking:**
- None — no Sentry, Crashlytics, or third-party error reporters
- Errors logged locally via `OSLog` only

**Logs:**
- Framework: `OSLog` with structured logging
- Subsystem: `com.drinkpulse.app` (stable across all sessions)
- Categories: `startup`, `migration`, `HealthService`, `ReminderService`, etc. (per component)
- Privacy: never log PII (health data, consumption details, timestamps) — only categories/counts
- Destination: device only; never uploaded

**Diagnostics:**
- Xcode Console (live debugging)
- Apple on-device debugging tools
- No telemetry, usage tracking, or remote reporting

---

## CI/CD & Deployment

**Hosting:**
- App Store (future; currently early development)
- No backend services

**CI Pipeline:**
- None currently configured
- Build/test via manual Xcode or local scripts

**Deployment:**
- Manual: archive in Xcode, upload to App Store Connect
- No automated release pipeline

---

## Data Migration & Versioning

**Schema Versioning:**
- `VersionedSchema` snapshots in `Domain/Persistence/Schemas/` (SchemaV1.swift–SchemaV4.swift)
- Each version immutable once shipped (frozen as self-contained snapshot)
- New property changes → new schema version + new migration stage
- Never edit a shipped version in place (causes "model version unknown" errors)

**Migration Stages in `MigrationPlan`:**
- **v1→v2** (custom): backfills `uuid` + `modifiedDate` per row, fetches V2 snapshot types
- **v2→v3** (custom): backfills `creationDate` from `consumptionDate`, fetches V3 snapshot types
- **v3→v4** (lightweight): additive optional `healthKitUUID` (plan-0036), no data transform
- Forward-compatible with CloudKit and HealthKit (identity + LWW preserved)

---

*Integration audit: 2026-08-02*
