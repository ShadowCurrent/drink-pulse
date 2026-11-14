# Phase 11: iOS 27 Release Verification - Pattern Map

**Mapped:** 2026-11-14
**Files analyzed:** 4 new + living-doc updates
**Analogs found:** 4 / 4 (all tracked in git, verified with `git ls-files`)

No production code changes. One test-only Swift file; the rest are evidence docs.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `.planning/phases/11-ios-27-release-verification/11-EVIDENCE.md` | evidence doc | batch (tool output to record) | `.planning/phases/10-data-platform-integration-modernization/10-EVIDENCE.md` (+ `08-BASELINE.md` header) | exact |
| `.planning/phases/11-ios-27-release-verification/11-A11Y-CHECKLIST.md` | owner checklist | request-response (owner result per item) | `10-DEVICE-SESSION.md` (+ `09-UAT.md` result format) | role-match |
| Debt ledger + SC5 discovery table (sections inside 11-EVIDENCE.md) | ledger | transform (read-only audit) | `10-EVIDENCE.md` disposition sections ("C008 disposition") | partial |
| `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift` | test (XCUITest) | request-response | `Features/History/HistoryDynamicTypeUITests.swift` (launch args) + `Features/Shell/ShellNavigationUITests.swift` (teardown, tab nav) | role-match |
| Living docs (README, PROJECT.md, ROADMAP.md, REQUIREMENTS.md, current-focus.md, open-questions.md, DEVLOG, STATE.md) | docs | append / edit | self (append-only DEVLOG; living docs edited in place) | n/a |

## Pattern Assignments

### `11-EVIDENCE.md`

**Analog:** `10-EVIDENCE.md`. Copy section skeleton: `## Toolchain and destination`, `## Zero-warning build`, `## Scoped ... suites`, `## Full suite`, `## Coverage`, `## File size`, then add `## Toolchain change`, `## Limitations`, `## Debt ledger`, `## Discovery reconciliation (SC5)`.

Toolchain section style (10-EVIDENCE.md lines 5-11):
```
- **Xcode:** 27.2, build version 27B52. **Swift:** 6.4.2 (`swiftlang-6.4.2.1.9`), language mode `SWIFT_VERSION = 6.0` ... **SDK:** iphonesimulator 27.2.
- **Destination:** iPhone 17 simulator, iOS 27.2 runtime (`com.apple.CoreSimulator.SimRuntime.iOS-27-2`) ... The simulator identifier is machine-specific and is deliberately not recorded.
- **Apple tooling route:** ... CLI fallback ... reason
```
Phase 11 changes: device is iPhone 18 Pro on 27.2 (name runtime build 24B8117; two "iPhone 18 Pro" exist, 27.0 and 27.2); runner recorded per run with the named reason when CLI (clean + Release, coverage).

Zero-warning gate (10-EVIDENCE.md "Zero-warning build"): `xcodebuild clean build-for-testing ... -derivedDataPath <fresh>` then pattern `(\.swift:[0-9]+:[0-9]+: |ld: |clang: )warning:` must match 0; classify `appintentsmetadataprocessor ... no AppIntents.framework dependency found` as tool notes. Add Release `clean build` and plain `grep -c 'warning:'`.

Full suite (10-EVIDENCE.md "Full suite"): detached, `-derivedDataPath build/... -resultBundlePath ...xcresult -enableCodeCoverage YES -collect-test-diagnostics never`, `.exit` file, summary via `xcrun xcresulttool get test-results summary`. Do NOT set `TEST_RUNNER_DP_RUN_FLASH_HARNESS`.

Coverage (10-EVIDENCE.md "Coverage"): `xcrun xccov view --report --json`; report overall, Services aggregate, Domain non-Persistence list, `StoreBootstrap.swift`. Label inherited Phase 10 numbers (94.61 overall, 2026-11-09) as historical. Domain gap stays "tracked in WINDOWS.md rows 1 and 7", not closed.

Rule: raw logs outside git (`~/Library/Logs/DrinkPulse/phase-11-ios27/<UTC stamp>/`), record SHA-256. Never record a UDID. Header style from `08-BASELINE.md` lines 1-8 (date, path, Xcode build, Swift, SDK, destination with runtime build).

Failure mapping: every failed test id matched to the CONTEXT exception table (hero-height, 2 History edit tests, Export dismiss flake, 2 D1 harness tests reported Skipped); no match = BLOCKER, re-run once alone per CONTEXT protocol.

### `11-A11Y-CHECKLIST.md`

**Analog:** `10-DEVICE-SESSION.md` structure: title, plan/coverage line, `## Privacy rule (read first)`, `## Stop rule`, then per-step rows. Result vocabulary from `09-UAT.md`:
```
### 4. Retained visual and accessibility behavior
expected: ...
result: pass
```
Use `result: pass | fail | open` per item, plus `source: automated | human` columns kept separate. Items: probe (VoiceOver + rotor present on simulator?), AlcoholAreaChart Audio Graph (05-UAT test 5), WeekdayBarChart Audio Graph (test 6), Reduce Motion (05-UAT test 4, plus `DPArcProgress.swift:18`, `ConsumptionOverviewCard.swift:110`, `HistoryCalendarView.swift:61`), Dynamic Type AX5, light/dark, Increase Contrast. State "simulator, not device". Use a cloned simulator (`xcrun simctl clone`), reset and delete after.

### `AccessibilityAuditUITests.swift`

**Analog A (launch args), `HistoryDynamicTypeUITests.swift` lines 15-26:**
```swift
private let ax5Category = "UICTContentSizeCategoryAccessibilityXXXL"

private func launchApp(contentSizeCategory: String) {
    app = XCUIApplication()
    app.launchArguments += [
        "-dp_onboarding_done", "YES",
        "-dp_uitest", "YES",
        "-dp_uitest_unit", "metric",
        "-UIPreferredContentSizeCategoryName", contentSizeCategory,
    ]
    app.launch()
}
```
Seeded dataset arg also exists: `"-dp_uitest_dataset", "multiday"`.

**Analog B (class shell, tab names, tab nav), `ShellNavigationUITests.swift` lines 1-20:**
```swift
import XCTest

@MainActor
final class ShellNavigationUITests: XCTestCase {
    private var app: XCUIApplication!
    private let tabNames = ["Home", "Insights", "History", "Settings"]
    override func setUpWithError() throws { continueAfterFailure = false }
```
Tab access: `app.tabBars.buttons["History"]`, `waitForExistence(timeout: 10)`, then `.tap()`.

**Teardown pattern for global state (ShellNavigationUITests lines ~118-128):** register `addTeardownBlock { ... }` before changing simulator-global state (VoiceOver there; here use for `XCUIDevice.shared.appearance` restore). Skip on environment failure with `throw XCTSkip(...)`.

**Core new call (no repo analog; signature verified in RESEARCH):** `try app.performAccessibilityAudit(for: .all) { issue in ... }`; return true only for issues allow-listed by ledger id. Never match system UI by localized label (Polish simulator locale). Place under `drinkpulseUITests/Features/Shell/` (mirror rule, file-system-synchronized, no pbxproj edit). Keep under 300 lines; English only; no `print`. Confirm test name appears in log.

## Shared Patterns

- **Privacy rule:** counts/PASS/FAIL only, no personal values or UDIDs in committed docs (`10-DEVICE-SESSION.md` "Privacy rule").
- **Runner record:** Xcode MCP first (resolve `workspaceIdentifier` via `XcodeListWorkspaces`, entry ending `drinkpulse.xcodeproj`); CLI only for named missing capability (clean/Release build, coverage); never infer a result from an MCP timeout (09-03 precedent).
- **Append-only vs living:** DEVLOG append-only; living docs (README, PROJECT, ROADMAP, REQUIREMENTS, current-focus, open-questions, architecture if touched) edited to match reality. Do not edit 09-VERIFICATION.md or other frozen records; list them in the ledger. STATE.md contradiction (current_phase 09 vs roadmap) must be surfaced.
- **Language:** English only.

## No Analog Found

| File | Role | Reason |
|---|---|---|
| Debt ledger table | ledger | No prior phase has a table of all open debt; build from RESEARCH "Debt Ledger Inputs" (D1, WINDOWS rows 1-4,6-11, 8 pending todos, open-questions, verification record states, Phase 10 residuals) |
| SC5 discovery table | audit | Use RESEARCH "SC5" table; note inventory vs register ID namespace collision (C001-C021 vs C001-C013) |
| `performAccessibilityAudit` usage | test | No audit exists in the repo |

## Metadata

**Analog search scope:** `.planning/phases/08-10`, `drinkpulseUITests/Features/*`
**Files scanned:** about 10 read, 50 listed
**Pattern extraction date:** 2026-11-14
