# External Integrations

**Analysis Date:** 2026-07-18

## APIs & External Services

**None.** No REST APIs, SDKs, or external services are used. The app is entirely on-device.

---

## Data Storage

**Primary Database:**
- SwiftData (on-device SQLite)
  - Models: `DrinkTemplate`, `ConsumptionEvent`, `UserProfile`
  - Schema versions: managed in `Domain/Persistence/Schemas/` (versioned snapshots)
  - Migrations: `MigrationPlan` defines transitions between schema versions
  - Container: created in `drinkpulseApp.swift` via `StoreBootstrap.makeContainer()`
  - Access: views query via `@Query`, mutations via `@Environment(\.modelContext)`

**File Storage:**
- Local filesystem only
  - Exported backups: JSON format written to app container (`BackupExport.swift`)
  - Imported backups: read from document picker via `CoreTransferable` 
  - DrinkControl legacy import: CSV parsing from file (`DrinkControlImporter.swift`)
  - No cloud file storage; exports are user-initiated and stored on device/locally shared

**Caching:**
- No persistent cache layer
- Transient state: `@State`, `@Observable` view models
- Schema cache: SwiftData's internal metadata store (not exposed)

## Authentication & Identity

**Auth Provider:**
- None — app requires no login or account
- Privacy-first: all data stays on-device
- User identification: internal to app (UserProfile stored in SwiftData)

**Device Identity (HealthKit-specific):**
- `ConsumptionEvent.healthKitUUID` — device-local cache of Apple Health sample UUID
- Not synced, not exported — purely for device-local deduplication
- Used by `HealthService` to prevent duplicate writes to Health

## Apple Health Integration

**Type: Optional, opt-in write-only**

**HealthKit Capability:**
- Framework: `HealthKit` (iOS 26+)
- Entitlement: `com.apple.developer.healthkit` in `.entitlements`
- Permission: User grants write authorization during onboarding or in Settings

**What is written:**
- Sample type: `HKQuantityType(.numberOfAlcoholicBeverages)` — count of standard drinks
- Conversion: `grams ÷ 14.0` (Apple's fixed definition of one standard drink = 14 g)
- Metadata: `dp_event_uuid` (maps Health sample back to in-app event for deduplication)
- Trigger: automatic on add/edit/delete via `HealthWriteHooks` (plan-0036)

**Implementation:**
- Service: `HealthService` (`Services/HealthService.swift`) — orchestrates write/update/delete
- Adapter: `HealthKitAdapter` (`Services/HealthKitAdapter.swift`) — thin wrapper over `HKHealthStore`
- Fake: `UITestHealthStore` — in-memory stub for UI tests (never prompts for permission)
- Error handling: best-effort, non-blocking; Health failures never block in-app operations
- Idempotency: per-event serial task chains prevent race conditions on rapid edit/delete

**Status:**
- Read authorization: not used (app doesn't import Health data)
- Write authorization: user-requested, stored in Health's access controls
- Failures logged but not surfaced to user (Health is optional auxiliary, not critical path)

---

## Local Notifications

**Type: Opt-in daily reminder**

**Framework:** UserNotifications (iOS 26+)

**What triggers:**
- Daily local notification: "Time to log your drinks" (plan-0016, ADR-0010)
- User sets time via Settings time picker (default: 21:00)
- Repeats daily at the chosen time
- User can enable/disable in Settings

**Implementation:**
- Service: `ReminderService` (`Services/ReminderService.swift`) — schedules/cancels requests
- Protocol: `NotificationScheduling` — injected, so tests can use a fake
- Fake: `UITestNotificationCenter` — in-memory stub (no real scheduling in UI tests)
- Storage: reminder time persisted in `@AppStorage` via `AppStorageKeys`
- Idempotency: one fixed request ID (`dp.daily.log.reminder`) means rescheduling overwrites

**Tap handler:**
- `NotificationActionHandler` listens via `UNUserNotificationCenter.delegate`
- Tapping reminder opens app to AddDrink screen (cold launch or foreground)

---

## CloudKit & Sync

**Status: Planned, currently disabled**

**Framework:** SwiftData's built-in CloudKit integration (iOS 26+)

**Current state:**
- Entitlement not enabled; feature is gated
- Gate point: `StoreBootstrap.productionConfiguration()` controls whether CloudKit is added to the container config
- Documentation: plan-0023 Phase A (schema prep for CloudKit), Phase B (enable CloudKit)

**When enabled (future):**
- SwiftData handles bidirectional sync automatically
- User must have iCloud account; data syncs to private CloudKit database
- Conflict resolution: last-write-wins via `modifiedDate` (see ADR-0011)
- Model constraint: no `@Attribute(.unique)`, all properties optional or have defaults
- Deduplication: `RecordDeduplicator.sweep()` collects records by `uuid` and removes duplicates

---

## Export/Import

**Type: User-initiated JSON backup**

**Export Format:**
- JSON file containing:
  - UserProfile (sex, DOB, guideline choice, unit preferences)
  - Array of ConsumptionEvent (with all fields)
  - Array of DrinkTemplate (category presets)
- File type: `com.haniewicz.drinkpulse.backup` (custom UTType via `UniformTypeIdentifiers`)
- Location: shared via document picker (user chooses destination)

**Implementation:**
- Export: `BackupExport` class serializes models to JSON
- Importer: `DataImporter` parses JSON and upserts/merges into SwiftData
- Error handling: detailed `ImportError` enum; user shown error dialog

**Legacy DrinkControl Import:**
- CSV format from competing app "DrinkControl"
- Importer: `DrinkControlImporter` parses CSV, derives ABV guesses, maps to DrinkPulse templates
- Used for one-time migration; not reversible

**Data Protection:**
- Exports contain full user history and body metrics — treated as sensitive
- Never auto-uploaded; user explicitly initiates export
- Import validates all fields before writing to SwiftData

---

## Webhooks & Callbacks

**Incoming:**
- None — no server endpoints

**Outgoing:**
- None — no external APIs called

---

## Environment Configuration

**Required env vars:**
- None — app has no external service dependencies

**Secrets location:**
- None — no API keys, OAuth tokens, or credentials in code
- All configuration via `@AppStorage` (UserDefaults) — user preferences only

**Access Control:**
- HealthKit: user grants/denies via system prompt (plan-0036)
- Notifications: user grants/denies via system prompt (plan-0016)
- App data: protected by iOS app sandbox

---

## Monitoring & Observability

**Error Tracking:**
- None — no Sentry, Crashlytics, or similar
- Errors logged locally via `OSLog` only

**Logs:**
- Framework: `OSLog` with structured logging
- Subsystem: `com.drinkpulse.app`
- Categories: `HealthService`, `ReminderService`, etc. (per-feature)
- Privacy: never log PII (health data, consumption details, timestamps) — only categories/counts
- Destination: device only; not uploaded

**Diagnostics:**
- Use Xcode Console or Apple's on-device debugging tools
- No telemetry or usage tracking

---

## CI/CD & Deployment

**Hosting:**
- App Store (future release; currently in early development)
- No backend services

**CI Pipeline:**
- None currently configured
- Build/test via manual Xcode commands or local scripts

**Deployment:**
- Manual: build archive in Xcode, upload to App Store Connect
- No automated release pipeline

---

## Data Migration & Versioning

**Schema Versioning:**
- SwiftData `VersionedSchema` snapshots in `Domain/Persistence/Schemas/`
- Each version is a complete snapshot, never edited in place
- New property changes = new schema version + new migration stage
- Two versions must never conflict on the same device

**Migration Stages:**
- `MigrationPlan` defines lightweight migrations when needed (e.g., data transformations)
- Forward-compatible with CloudKit (all models support CloudKit-safe shape)
- Immutable once shipped (prevents "model version unknown" errors on device)

---

*Integration audit: 2026-07-18*
