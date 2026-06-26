# Execution journal — 0016 log-reminder local notifications

Append-only. Dated entries recording deviations from the frozen plan
and discoveries during execution.

## 2026-06-26 — Plan frozen, reconciliation with current code

Plan was drafted 2026-05-19; repo has moved to plan-0034 since. Reconciled
the plan against current reality before coding:

- **ADR number deviation**: plan step 0 says create
  `docs/decisions/0005-services-layer.md`. ADR 0005, 0006, 0007 are now
  taken (density / volume-provenance ADRs). No Services-layer ADR exists
  yet. → Created **`0008-services-layer.md`** instead (next free number).
- **No `Services/` layer exists** — confirmed (`find drinkpulse -type d
  -name Services` empty; no services ADR). This plan introduces it as
  planned.
- **Settings is now a `ScrollView` of `SettingsSection` glass cards**
  (plan-0027), not a `List`. `ReminderSection` is built as a
  `SettingsSection` with `SettingsRow` rows to match the current design,
  added to `SettingsView`'s `SettingsForm` VStack — not the plan's
  old List-row assumption.
- **Navigation / tap-action wiring**: AddDrink is presented from
  `RootShellView` via `@State private var showAddDrink` + a single
  `.sheet(isPresented:)`. The notification tap flips that state. Used a
  `@AppStorage(dp_pending_add_drink)` flag (survives cold launch, read &
  cleared `.onAppear`) plus a `NotificationCenter` async-sequence event
  (`.task`) for the already-running case — no Combine, no ObservableObject.
- **`scheduleIfEnabled` on launch/scenePhase**: wired in `RootShellView`
  via `@Environment(\.scenePhase)` `.onChange` + `.task`, reading the
  AppStorage-backed values through `ReminderService`.
- **AppStorage keys** centralised in `AppStorageKeys` (existing
  convention) rather than scattered string literals.

## 2026-06-26 — Implementation

Created:
- `docs/decisions/0008-services-layer.md` (ADR; not the plan's `0005`).
- `drinkpulse/Services/NotificationScheduling.swift` (protocol + thin
  `UNUserNotificationCenter` adapter via `@retroactive @unchecked Sendable`).
- `drinkpulse/Services/ReminderService.swift` (`@MainActor`; makeRequest,
  schedule [remove-then-add idempotent], cancel, requestAuthorization,
  scheduleIfEnabled; static `defaultCenter()` picks the UI-test stub under
  `-dp_uitest`).
- `drinkpulse/Services/NotificationActionHandler.swift`
  (`UNUserNotificationCenterDelegate`; tap → pending flag + event).
- `drinkpulse/Services/UITestNotificationCenter.swift` (launch-arg-gated
  non-prompting stub — added so the UI test drives the real toggle without the
  locale-dependent, one-shot system permission alert; inert in production).
- `drinkpulse/Features/Settings/Components/ReminderSection.swift`.
- `drinkpulseTests/Services/ReminderServiceTests.swift` (11 tests + the
  `FakeNotificationCenter`; placed under `Services/` per CLAUDE.md test-mirror
  rule, not the plan's target-root path).
- `drinkpulseUITests/Features/Settings/ReminderSettingsUITests.swift` (2 tests).

Modified:
- `drinkpulse/DesignSystem/AppStorageKeys.swift` (reminder keys + pending flag).
- `drinkpulse/Features/Settings/SettingsView.swift` (insert `ReminderSection`).
- `drinkpulse/drinkpulseApp.swift` (set the notification delegate in `init`).
- `drinkpulse/Features/Shell/RootShellView.swift` (pending-flag onAppear,
  NotificationCenter async-sequence task, scheduleIfEnabled on scenePhase).
- `drinkpulse/Localizable.xcstrings` (8 keys).
- `docs/architecture.md` (Services/ in folder layout + a Services-layer section).
- Living docs: README, roadmap, current-focus, DEVLOG.

### UI-test regression found and fixed (during the full run)
Adding `ReminderSection` above the Privacy section pushed the App Lock row
further down, so `SettingsUITests.test_appLockRow_isPresentAndAddressable`'s
single `swipeUp()` no longer made the row hittable → deterministic failure.
Per the UI-test-bug policy this is a small fix: changed the test to scroll
until the row is hittable (loop, max 6 swipes). Re-ran `SettingsUITests` → all
5 green.

`HistoryUnitDisplayUITests.test_unitSwitch_reRendersSubtitle` failed once in
the full run but **passes in isolation** (verified twice) — pre-existing
timing flakiness under full-suite load, unrelated to this change (it touches
neither History nor unit-switching).

### Coverage (from xcresult)
- `ReminderService.swift`: **100% (50/50)** — exceeds the ≥85% Services target.
- App target overall: **93.61%** (≥90%).
- Excluded as framework glue (no public initializers to drive in a unit test):
  `NotificationScheduling` adapter, `NotificationActionHandler` delegate.
  `ReminderSection` is a SwiftUI view (excluded; covered by the UI test).
</content>
</invoke>
