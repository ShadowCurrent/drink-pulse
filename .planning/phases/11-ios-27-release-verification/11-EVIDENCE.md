# Phase 11 Evidence

Evidence for the iOS 27 release verification (MOD-04, VER-01, VER-02, VER-03). Capture started 2026-11-14 at base commit `4c04a25` (phase-start commit `2aa9156`; the working tree held no uncommitted change when capture began, `git status --short` empty). Xcode 27.2 (27B52), Apple Swift 6.4.2 (`swiftlang-6.4.2.1.9`), iphonesimulator 27.2 and iphoneos 27.2 SDKs. Primary destination: iPhone 18 Pro simulator, iOS 27.2 runtime build 24B8117. Raw logs stay outside git; every recorded log carries its SHA-256.

## Toolchain and destination

- **Xcode:** 27.2, build version 27B52 (`xcodebuild -version`). **Swift:** `Apple Swift version 6.4.2 (swiftlang-6.4.2.1.9 clang-2100.4.1.1)`, target `arm64-apple-macosx27.2.0` (`swift --version`); language mode `SWIFT_VERSION = 6.0` for the app and test targets. **SDKs:** `xcrun --sdk iphonesimulator --show-sdk-version` prints 27.2 and `xcrun --sdk iphoneos --show-sdk-version` prints 27.2. **Host:** `sw_vers` reports macOS ProductVersion 27.2.1, BuildVersion 26B131.
- **Destination (primary):** iPhone 18 Pro simulator on the iOS 27.2 runtime `com.apple.CoreSimulator.SimRuntime.iOS-27-2`, runtime build 24B8117 (`xcrun simctl list runtimes` prints `iOS 27.2 (27.2 - 24B8117)`). Exactly one device named "iPhone 18 Pro" exists under that runtime key; the `iOS-27-2-iPhone19-4` runtime (build 24B91016s) and the iOS 27.0 runtime were not used. The Xcode MCP active destination was the same device (Simulators group, osVersion 27.2). The simulator identifier is machine-specific and is deliberately not recorded; it is kept in the out-of-git `udid.txt` of the log directory.
- **Apple tooling route:** Xcode MCP only for every build and test step (owner decision D11-20; workspace resolved at run time with `XcodeListWorkspaces`, the identifier is never written to a file). The CLI `xcodebuild` is allowed in exactly two owner-approved steps, each a named missing capability of the MCP server: (1) one Release-configuration build (the MCP `BuildProject` tool accepts only `buildForTesting` and `workspaceIdentifier`, so it cannot select a configuration); (2) one full-suite test run with `-enableCodeCoverage YES` (MCP cannot collect coverage; plan 11-05). There is no CLI Debug build. Each evidence row records its runner and the reason. CLI runs made before the D11-20 override are not evidence.
- **Official source for the command-line flags:** the Xcode 27.2 `xcodebuild -help` output (lists `-configuration NAME`, `-destination DESTINATIONSPECIFIER`, `-derivedDataPath PATH`, `-resultBundlePath PATH`, `-enableCodeCoverage YES|NO`) and the Xcode 27.2 `xcrun xcresulttool help` output (Xcode Result Bundle Tool version 25407), cited as tool output. Apple online documentation was not needed for these flags.
- **Log directory:** `~/Library/Logs/DrinkPulse/phase-11-ios27/<UTC stamp>/`, outside git. Derived-data paths are `build/p11-*` (gitignored).

## Toolchain change vs Phase 08

The first three columns are historical: they quote what earlier phases recorded and are not reused as the current toolchain.

| Item | Phase 08 baseline (historical) | Phase 09 (historical) | Phase 10 (historical) | Phase 11 (this run) |
|------|--------------------------------|-----------------------|-----------------------|---------------------|
| Xcode version and build | 27.0 (27A266a) | 27.0 (27A266a) | 27.2 (27B52) | 27.2 (27B52) |
| Swift | Apple Swift 6.4 (`swiftlang-6.4.0.34.1`) | not recorded | 6.4.2 (`swiftlang-6.4.2.1.9`) | 6.4.2 (`swiftlang-6.4.2.1.9`) |
| SDK | iOS 27.0 SDK | iPhoneSimulator 27.0 | iphonesimulator 27.2 | iphonesimulator 27.2, iphoneos 27.2 |
| Simulator model and runtime build | iPhone 18 Pro, iOS 27.0 build 24A434 | iPhone 18 Pro, iOS 27.0 runtime (build not recorded) | iPhone 17, iOS 27.2 runtime (build not recorded) | iPhone 18 Pro, iOS 27.2 build 24B8117 |
| Deployment target | 27.0 | 27.0 | 27.0 | 27.0 |

Phase 08 strings are quoted only in the historical column above and are not reused as current.

### Consequences

- The Phase 11 builds use SDK 27.2 with deployment target 27.0 and run on the iOS 27.2 runtime.
- The iOS 27.0 runtime exists on this Mac but was not run in this phase; this is a limitation, recorded again under `## Limitations` by plan 11-04.
- Phase 09 evidence mixes toolchains (Xcode 27.0 evidence on the iOS 27.0 simulator against later 27.2 work).
- Phase 10 coverage and device numbers are historical and are labelled with their phase and date wherever they are quoted.

## Zero-warning build (MOD-04)

Warning gate pattern, applied to the raw log of every build: `(\.swift:[0-9]+:[0-9]+: |ld: |clang: )warning:` (Swift, linker and clang diagnostics) plus a plain count of every `warning:` line and a deprecation count `warning:.*deprecat|deprecat.*warning`. A build counts only when its success marker is in its log and, for the CLI build, its exit file reads 0; the MCP build is counted from its tool result and full log; each build has its own derived-data folder and its own out-of-git log; builds never ran concurrently.

### Build rows

| Row | Date | HEAD | Runner and reason | Result | Success marker | Gate-pattern count | All `warning:` lines | Deprecation count |
|-----|------|------|-------------------|--------|----------------|--------------------|----------------------|-------------------|
| Debug (iphonesimulator 27.2) | 2026-11-14 | `ee67fd1` | Xcode MCP `BuildProject` (buildForTesting), Xcode DerivedData for this project removed first | built successfully, error list empty, `elapsedTime` 17.789 s | `** BUILD SUCCEEDED **` | 0 | 3 | 0 |
| Release (iphoneos 27.2) | 2026-11-14 | `ee67fd1` | CLI `xcodebuild`; reason: the MCP `BuildProject` tool cannot select the Release configuration (named missing capability, owner-approved in D11-20) | exit 0 | `** BUILD SUCCEEDED **` | 0 | 2 | 0 |
| Release (iphonesimulator 27.2) | not used (pre-override CLI run) | n/a | n/a | n/a | n/a | n/a | n/a | n/a |

Superseded and removed (not evidence): the first Debug row (a CLI `build-for-testing` run made before owner decision D11-20) and the incremental MCP success check that accompanied it.

**Debug procedure (runner "Xcode MCP BuildProject (buildForTesting), DerivedData removed first"):** `rm -rf ~/Library/Developer/Xcode/DerivedData/drinkpulse-*` (7 folders removed; no other path touched, `build/` untouched), then MCP `BuildProject` with `buildForTesting` true on the active destination (iPhone 18 Pro, iOS 27.2). The log shows `SwiftDriver Compilation` and `Ld` steps for all three targets (`drinkpulse`, `drinkpulseTests`, `drinkpulseUITests`) into a fresh DerivedData folder, so it is a full, non-incremental build of the app and both test bundles. MCP `GetBuildLog` with severity `warning` returned `totalFound` 0 and no entries (the tool lists compiler issues, not tool console notes). Logs: `mcp-debug-build.log` sha256 `6d019bd43a4c2dc0e3dc458649be321a93924e523905c002d69959a000e5a2fd` (the `BuildProject` full log; the `GetBuildLog` full log file is byte-identical, same digest) and `mcp-debug-build.result.txt` sha256 `6a05b09fe2655f042e4ad390e6760df9c0763c5efb1a578f3dcc604c8722bcc6` (the two tool results, no temporary paths). The name `dismissSheet` appears on 0 lines of the Debug log.

**Debug warning lines (3, all one class):** each is `appintentsmetadataprocessor ... warning: Metadata extraction skipped, no AppIntents.framework dependency found`. They are external tool notes (see the classification table below); the gate pattern does not match them.

**Release command (the single approved CLI build):** `xcodebuild clean build -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Release -destination "generic/platform=iOS" -derivedDataPath build/p11-release-device CODE_SIGNING_ALLOWED=NO`, stdout and stderr to `release-device-build.log`, exit status to `release-device-build.exit` (value 0), both in the out-of-git stamp directory. The log contains `** CLEAN SUCCEEDED **` and `** BUILD SUCCEEDED **` and compiles against the iPhoneOS 27.2 SDK without signing. It is not a signed archive. Log: `release-device-build.log` sha256 `7076a9477dbcfc25ab0b59c8b6598a7865fb1b4376c6c834d0beeb90b170c041`. The name `dismissSheet` appears on 0 lines of the Release log.

**Release warning lines (2):** (1) one `appintentsmetadataprocessor ... warning: Metadata extraction skipped, no AppIntents.framework dependency found` tool note; (2) `warning: All interface orientations must be supported unless the app requires full screen. (in target 'drinkpulse' from project 'drinkpulse')`, emitted by the `Validate ... builtin-validationUtility ... -validate-for-store -shallow-bundle` step that runs only in this Release device build (the Debug MCP build did not emit it). It is not a Swift, linker or clang diagnostic and not a deprecation, so the gate pattern and the deprecation count do not match it, but it is an app-owned project-configuration warning and the plain count includes it.

**Release simulator SDK limitation:** Release was verified on the iphoneos 27.2 SDK only. The simulator SDK Release build was not part of the approved runner set (D11-20); an earlier CLI Release simulator run happened before the override and is not evidence.

### Warning classification

| Warning line | Source | Class | Impact | Official source consulted | Follow-up |
|--------------|--------|-------|--------|---------------------------|-----------|
| `appintentsmetadataprocessor ... Metadata extraction skipped, no AppIntents.framework dependency found` (Debug 3, Release 1) | Xcode build tool `appintentsmetadataprocessor` | external tool note | none: the app has no App Intents dependency, so there is nothing to extract | Xcode MCP `DocumentationSearch` for the message text returned only unrelated AppIntents symbol pages; no Apple documentation entry for this tool note was found | none |
| `All interface orientations must be supported unless the app requires full screen.` (Release 1) | `builtin-validationUtility -validate-for-store` on `drinkpulse.app`; inputs `drinkpulse/Info.plist` (`UISupportedInterfaceOrientations~ipad` lists Portrait, LandscapeLeft, LandscapeRight, not PortraitUpsideDown) and `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone and iPad) | app-owned project configuration; not blocked externally | App Store validation notice for the iPad idiom. No build failure, no runtime effect on the iPhone-first scope | Xcode MCP `DocumentationSearch` returned the `UIViewController.supportedInterfaceOrientations` page: multitasking apps must support all orientations, and an app opts out with Requires full screen or by not declaring all orientations; all iPadOS devices support portraitUpsideDown and enabling it for the iPad idiom is best practice. It returned no page that quotes the validation message itself | fixed by plan 11-11 (D11-21): `UIInterfaceOrientationPortraitUpsideDown` added for the iPad idiom; the second Release device build no longer emits the line (see "Fix: iPad orientations (D11-21)") |

### MOD-04 outcome

MOD-04 outcome: app-owned deprecation warnings: 0; externally blocked warnings: none; app-owned warnings that are not deprecations: 0 after the D11-21 fix (the iPad interface orientations validation notice from the first Release device build is resolved, see "Fix: iPad orientations (D11-21)" below). The only remaining plain `warning:` lines are the `appintentsmetadataprocessor` external tool note (Debug 3, Release 1), which has no impact.

The orientation warning was open after plan 11-01 and was fixed by plan 11-11 with the owner-approved one-entry change to `drinkpulse/Info.plist`; the second Release device build log proves it is gone. The Phase 08 `@Entry` closure warning for `dismissSheet` is absent from every recorded log (0 lines each). No `-warnings-as-errors` or warning-suppression build setting is in use (see Build settings below). The source guard in the final section records the one production-file change.

### Fix: iPad orientations (D11-21)

Dated 2026-11-14, plan 11-11. Owner decision D11-21.

- **Change:** `drinkpulse/Info.plist`, `UISupportedInterfaceOrientations~ipad` gained `UIInterfaceOrientationPortraitUpsideDown` (array now LandscapeLeft, LandscapeRight, Portrait, PortraitUpsideDown). The iPhone key `UISupportedInterfaceOrientations` stays Portrait only. `UIRequiresFullScreen` is not added and `TARGETED_DEVICE_FAMILY` stays `1,2`.
- **Official source:** Xcode MCP `DocumentationSearch` (query "supportedInterfaceOrientations multitasking all orientations iPad") returned the UIKit page `supportedInterfaceOrientations` (`UIViewController`): all iPadOS devices support portraitUpsideDown and it is best practice to enable it for the iPad idiom; multitasking apps must support all orientations, and an app opts out with Requires full screen or by not declaring all orientations. Related page: "Multitasking on iPad, Mac, and Apple Vision Pro: Supporting different interface orientations". API availability: a plist array entry, no OS-version gate.

| Row | Runner and reason | Result | Success marker | Orientation warning line | All `warning:` lines | Log digest |
|-----|-------------------|--------|----------------|--------------------------|----------------------|------------|
| Debug (iphonesimulator 27.2), `elapsedTime` 16.975 s | Xcode MCP `BuildProject` (buildForTesting), Xcode DerivedData for this project removed first (0 `drinkpulse-*` folders left); `GetBuildLog` severity `warning` returned `totalFound` 0 | built successfully, error list empty | `** BUILD SUCCEEDED **` | not applicable (validation step runs only in the Release device build) | 3 (all `appintentsmetadataprocessor` tool notes) | `mcp-debug-build-2.log` sha256 `59f77a3955a6c1caf5c88cd69943c8280e63c6b1ac54ee69bbf5f60cdf143163` |
| Release (iphoneos 27.2) | CLI `xcodebuild clean build ... -configuration Release -destination "generic/platform=iOS" -derivedDataPath build/p11-release-device CODE_SIGNING_ALLOWED=NO`; reason: MCP cannot select Release; the single second CLI build approved in D11-21 | exit 0 (`release-device-build-2.exit` reads 0) | `** BUILD SUCCEEDED **` (1) | 0 lines of "All interface orientations must be supported" (the first build had 1); `validate-for-store` step present (1) | 1 (`appintentsmetadataprocessor` tool note) | `release-device-build-2.log` sha256 `bd6c20559f32a42b40c1fa69fee766553f736155e2efdf41637c33b0a171632c` |

Remaining plain `warning:` lines after the fix: 3 in Debug and 1 in Release, all the external `appintentsmetadataprocessor` "Metadata extraction skipped, no AppIntents.framework dependency found" note (class: external tool note, no impact, see the classification table). The name `dismissSheet` appears on 0 lines of the second Release log. Logs stay in the out-of-git stamp directory; no machine path is recorded here.

### Build settings (Xcode MCP `GetTargetBuildSettings`)

Read for the active Debug configuration of each target; the Release values are covered by the project-file check in the guards section.

| Target | `IPHONEOS_DEPLOYMENT_TARGET` | `SWIFT_VERSION` |
|--------|------------------------------|-----------------|
| `drinkpulse` | 27.0 | 6.0 |
| `drinkpulseTests` | 27.0 | 6.0 |
| `drinkpulseUITests` | 27.0 | 6.0 |

Warning-related settings observed: `SWIFT_TREAT_WARNINGS_AS_ERRORS` NO, `GCC_TREAT_WARNINGS_AS_ERRORS` NO, `SWIFT_SUPPRESS_WARNINGS` NO, `GCC_WARN_INHIBIT_ALL_WARNINGS` NO, `WARNING_CFLAGS` empty, `SWIFT_WARNINGS_AS_ERRORS_GROUPS` and `SWIFT_WARNINGS_AS_WARNINGS_GROUPS` empty, and `OTHER_SWIFT_FLAGS` empty for the app (the UI-test target carries only the standard `-module-alias Testing=_Testing_Unavailable` flag). No warning-suppression or warnings-as-errors setting is in use.

## Scoped runs (VER-02)

Filled by plans 11-04 and 11-10.

Destination note (dated 2026-11-14, plan 11-04): the iOS 27.2 runtime build 24B8117 (`com.apple.CoreSimulator.SimRuntime.iOS-27-2`) was unavailable on 2026-11-14 after a CoreSimulator volume change at about 17:26; at that time `xcrun simctl` listed the iPhone 18 Pro as "unavailable, runtime profile not found" and the Xcode MCP active destination had fallen back to iPhone Duo on the `iOS-27-2-iPhone19-4` runtime (build 24B91016s). No test run was made in that state. The owner reinstalled the 24B8117 runtime, the iPhone 18 Pro came back with the same device UDID as in the out-of-git `udid.txt`, and the MCP destination was switched back to iPhone 18 Pro (iOS 27.2). No Phase 11 run used another runtime; every row below ran on the iPhone 18 Pro, iOS 27.2, build 24B8117.

Runner for every row: Xcode MCP `RunSomeTests` (owner decision D11-20); no CLI fallback was needed. Each result file is the MCP full-summary file of the run (one entry per test, state per test); the counts in the row come from the tool result. The matching console log of each run is saved next to it as `<group>.console.txt` in the same out-of-git directory.

| Group | Classes | Runner | Counts | Failed | Skipped | Mapping | Result file |
|-------|---------|--------|--------|--------|---------|---------|-------------|
| G1 | OnboardingFlowUITests, OnboardingHealthStepUITests, OnboardingLocaleDefaultUITests, OnboardingWeeklySummaryUITests, OnboardingAuthorityUITests, LaunchHandoffUITests, StartupErrorUITests, WeeklySummaryTapUITests, ShellNavigationUITests, SheetDismissTabSwitchUITests | Xcode MCP RunSomeTests | total=21 passed=19 failed=0 skipped=2 | failed: none | skipped: SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_cycle_staysNavigable_recordsFrameDeltas(), SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_emptyStore_recordsFrameDeltas() | no failure to map; the two D1 harness tests (DL-T05, DL-T06) report Skipped by the `DP_RUN_FLASH_HARNESS` gate, as expected; no harness variable was set | `g1-ui.result.txt` sha256 `f06f96dc879c0f495f9fa7571a479000b18b4cab4226e889f17788c1d32866d4` |
| G2 | AddDrinkFlowUITests, AddDrinkPickerFilterUITests, CurrencyUITests, CustomNameAutocompleteUITests, HealthWriteHooksUITests, VolumeServingUITests, EditVolumeIntegrityUITests, DuplicateEditPersistenceUITests, EditDeleteConfirmationUITests, ContextMenuDeleteConfirmationUITests, WrongRowContextMenuTargetUITests | Xcode MCP RunSomeTests | total=26 passed=26 failed=0 skipped=0 | failed: none | skipped: none | no failure to map; none of the known-red tests is in this group | `g2-ui.result.txt` sha256 `84a31f3cc6a5fc099b513ffe787582ac5be8bc8520bc27f0edea53ba3e5c3dfc` |
| G3 | HistoryInteractionUITests (with its DirectionalTransition, HitTarget, LoadingState and Pagination extensions), HistoryUnitDisplayUITests, HistoryDynamicTypeUITests, DashboardUITests | Xcode MCP RunSomeTests | total=22 passed=20 failed=2 skipped=0 | failed: HistoryInteractionUITests/test_editCustomNameAndNotes_persist(), HistoryInteractionUITests/test_editCategoryChange_persists() | skipped: none | both failures are on the known list: DL-T02 (failure line 165, "After save the row should show the custom name") and DL-T03 (failure line 220, "After changing to Wine the row should show the 150 ml wine default"); the data-integrity risk in the edit flow stays undetermined; the watched flake DL-T07 (`test_segmentSwitch_alternatingDirection_endsInCorrectState`) passed | `g3-ui.result.txt` sha256 `87819f3d112732355fe56ba4d11152507b81645027bf07446c47ed26079a3368` |
| G4 | InsightsUITests, InsightsScrubUITests, InsightsStreakUITests, InsightsDrinkFreeDaysUITests, SettingsUITests, GuidelinePickerUITests, HealthSettingsUITests, ReminderSettingsUITests, WeeklySummarySettingsUITests, AppVersionUITests, ExportUITests | Xcode MCP RunSomeTests | total=28 passed=28 failed=0 skipped=0 | failed: none | skipped: none | no failure to map; two known-list tests unexpectedly passed in this run: InsightsUITests/test_heroCard_holdsHeight_whenSwitchingToAllTimeScope() (DL-T01) and ExportUITests/test_export_dismissWithoutSaving_showsNoFailureAlert() (DL-T04, an intermittent flake); both stay on the ledger and in their todo and open-questions entries (one green run does not clear a reproducible or intermittent failure) | `g4-ui.result.txt` sha256 `01dab1098a2a306483e738091a6eb104e1f8c5cb1da0dbc2d45e8986323adcfa` |

G1: 2026-11-14, destination iPhone 18 Pro, iOS 27.2. G2: 2026-11-14, destination iPhone 18 Pro, iOS 27.2.
G3: 2026-11-14, destination iPhone 18 Pro, iOS 27.2. G4: 2026-11-14, destination iPhone 18 Pro, iOS 27.2.

## Full suite (VER-01)

Filled by plan 11-05.

## Coverage

Filled by plan 11-05.

## Core flow proof (VER-02)

Filled by plan 11-04.

## Accessibility (VER-03)

Filled by plans 11-03, 11-04, 11-07 and 11-10.

Automated audit result (plan 11-03, owner decision D11-22): audit run: 16 methods red, 311 open findings. Details, counts and digests are in the next section. The audit class is skipped by default after the run (gated behind `DP_RUN_A11Y_AUDIT`), so plans 11-04, 11-05 and 11-10 treat it as skipped-by-gate, not as a failure. No finding is fixed or allow-listed.

Results are from the iOS 27.2 simulator and not a device. Automated and human results are kept in separate columns; the audit covers the visible viewport of each screen only. The Human column is filled by plan 11-07. Plan 11-03 recorded the audit as prose because of D11-22, so the table was first created by plan 11-04.

| Check | Automated (source, result) | Human (checklist item, result) |
|-------|----------------------------|--------------------------------|
| Accessibility audit, all tabs, Add Drink, Onboarding (performAccessibilityAudit) | `AccessibilityAuditUITests`, 16 methods, Xcode MCP: exploratory run 16 red with 311 open findings (D11-22); gated default run 16 skipped, 0 failed (`audit-gated.result.txt` sha256 `1c7fce146f1e62895d8f98a08e59a4d662126118daf2addb8a998a5c075a0f3d`); findings are open, not allow-listed (ledger A11Y-AUDIT-G01 to G09) | pending (plan 11-07) |
| Dynamic Type through AX5 | audit AX5 variants (Home, Insights, History, Settings, Add Drink, Onboarding) are inside the exploratory audit run above; existing test `HistoryDynamicTypeUITests/test_row_growsAndStaysHittable_atAX5()` passed in row G3 (1 test, plan 11-04, 2026-11-14) | pending (plan 11-07) |
| Light and dark appearance | audit dark variants (Home, Insights, History, Settings) are inside the exploratory audit run above; existing test `SettingsUITests/test_appearanceMode_reflectsSelectedOption()` passed in row G4 (plan 11-04, 2026-11-14) | pending (plan 11-07) |
| Increase Contrast | none: no automated route (see plan 11-06 for the human check) | pending (plan 11-07) |
| VoiceOver traversal | pending (plan 11-04) | pending (plan 11-07) |
| Chart Audio Graph content | pending (plan 11-04) | pending (plan 11-07) |
| Reduce Motion | none: no automated route (see plan 11-06 for the human check) | pending (plan 11-07) |

## Accessibility audit (exploratory run, D11-22)

Dated 2026-11-14, plan 11-03. Requirement VER-03 (automated column). CONTEXT decisions D11-12 (audit class) and D11-22 (owner: findings are recorded as open, not allow-listed and not fixed; this supersedes D11-12's "allow-list, green run" contract). Results are from the iOS 27.2 simulator (iPhone 18 Pro), not a device, and cover the automated audit only; the human results stay in their own column of the VER-03 table (plan 11-07).

### What was run

- **Class:** `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift`, 16 methods: Home, Insights, History and Settings at default size, AX5 and dark (12), Add Drink and Onboarding at default size and AX5 (4). Each launches the app with the existing in-memory test seed, reaches the screen, asserts it was reached, then calls `performAccessibilityAudit(for: .all)`; the issue handler records every reported issue as its own test failure.
- **Code state of the exploratory run:** commit `9aaf759` (empty allow-list, so every issue failed the test). The run also showed a test-code defect, fixed afterwards in `7bea6da`: the dark-variant teardown set `XCUIDevice.shared.appearance = .unspecified`, which the simulator rejects (`Failed to set appearance mode: Requested appearance value (0) is not valid`, 4 occurrences, one per dark method). The 4 teardown failures are not audit findings and are not counted below; the result file holds 389 issue lines = 385 audit reports + 4 teardown failures.
- **Runner:** Xcode MCP `RunSomeTests` (target `drinkpulseUITests`, identifier `AccessibilityAuditUITests`), the whole class once. Result: 16 tests, 16 failed. The MCP result carried every per-issue message, so no CLI fallback was needed. Build check of the class: MCP `BuildProject` with `buildForTesting` true built successfully, `XcodeRefreshCodeIssuesInFile` reported no issues (diagnosticsCount 0), and `GetBuildLog` at warning severity returned 0 entries (`audit-build.result.txt`).
- **Official source (read in this plan):** `XCUIApplication.h` in the Xcode 27.2 iPhoneOS SDK documents `performAccessibilityAuditWithAuditTypes:issueHandler:error:` (issue handler; returning YES marks an issue as handled; available iOS 17.0 and later, inside the iOS 27.0 deployment target). `XCUIAccessibilityAuditTypes.h` lists contrast, elementDetection, hitRegion, sufficientElementDescription, dynamicType, textClipped, trait and all. `XCUIDevice.h` documents `appearance` (unspecified, light, dark).
- **Limits:** the audit covers the visible viewport of each screen at its launch scroll position. It does not exercise Increase Contrast or Reduce Motion (human-only, plan 11-06). Issue keys use the element identifier, else its label; they never use the system-localized issue description (the simulator locale is Polish).

### Counts

385 audit reports collapse to 311 distinct keys (`screen=... variant=... type=... element=...`, one per line in `audit-exploratory.txt`; a key repeats when the same element is reported more than once in a run). Recomputed from the saved files on 2026-11-14: 311 distinct keys, 385 reports, by type contrast 144, dynamicType 73, textClipped 57, sufficientElementDescription 21, hitRegion 16. These match the numbers in D11-22 exactly; no mismatch.

Distinct keys by screen, variant and audit type:

| Screen | Variant | contrast | dynamicType | textClipped | sufficientElementDescription | hitRegion | Total |
|--------|---------|---------:|------------:|------------:|-----------------------------:|----------:|------:|
| Home | standard | 16 | 6 | 1 | 0 | 0 | 23 |
| Home | ax5 | 3 | 3 | 0 | 0 | 0 | 6 |
| Home | dark | 16 | 6 | 1 | 0 | 0 | 23 |
| Insights | standard | 13 | 12 | 5 | 7 | 0 | 37 |
| Insights | ax5 | 5 | 3 | 0 | 7 | 7 | 22 |
| Insights | dark | 13 | 12 | 5 | 7 | 7 | 44 |
| History | standard | 2 | 1 | 1 | 0 | 0 | 4 |
| History | ax5 | 2 | 1 | 0 | 0 | 0 | 3 |
| History | dark | 2 | 1 | 1 | 0 | 0 | 4 |
| Settings | standard | 7 | 1 | 0 | 0 | 0 | 8 |
| Settings | ax5 | 3 | 1 | 0 | 0 | 0 | 4 |
| Settings | dark | 7 | 1 | 0 | 0 | 0 | 8 |
| Add Drink | standard | 30 | 14 | 24 | 0 | 0 | 68 |
| Add Drink | ax5 | 21 | 9 | 17 | 0 | 0 | 47 |
| Onboarding | standard | 3 | 1 | 1 | 0 | 1 | 6 |
| Onboarding | ax5 | 1 | 1 | 1 | 0 | 1 | 4 |
| **All** | | 144 | 73 | 57 | 21 | 16 | 311 |

### Grouping by probable root cause

The grouping is by screen and audit type and is a hypothesis from the element names in the key list, not a diagnosis; no group has been reproduced or inspected in the UI. Group IDs are the ledger rows (`A11Y-AUDIT-Gnn` in `11-DEBT-LEDGER.md`).

| Group | Screen | Keys | Types (keys) | Probable root cause |
|-------|--------|-----:|--------------|---------------------|
| A11Y-AUDIT-G01 | Add Drink | 111 | contrast 49, dynamicType 21, textClipped 41 | Drink-type tiles (emoji plus type name, for example Beer, Wine, Whiskey, Tequila). Emoji and label are reported separately for text clipping and contrast at default size and at AX5; likely fixed-size or truncating tile layout and a tile foreground/background pairing below contrast. |
| A11Y-AUDIT-G02 | Add Drink | 4 | contrast 2, dynamicType 2 | Toolbar `Cancel` button: contrast and fixed text size at default size and AX5. |
| A11Y-AUDIT-G03 | Home | 49 | contrast 35, dynamicType 12, textClipped 2 | Dashboard card text: "TODAY'S INTAKE", "This Week", percentages, "std" values, the date and guideline line, Calories and Drinks labels. Likely secondary text styles on glass cards in light and dark, a few values with fixed font sizes, and "140 kcal" clipped. |
| A11Y-AUDIT-G04 | Insights | 65 | contrast 31, dynamicType 24, textClipped 10 | Summary cards (Alcohol Calories, Binge Episodes, Drink-Free Days, Longest Streak, Heaviest Day, Spend), "TOTAL", "NOW", the week range and comparison lines. Same causes as G03 plus card titles and "505 kcal" clipped. |
| A11Y-AUDIT-G05 | Insights | 35 | sufficientElementDescription 21, hitRegion 14 | Chart day marks: seven elements whose identifier or label is a raw timestamp (for example `815871600.0`), reported as having no sufficient description at all variants and as too-small hit regions at AX5 and dark. Likely missing per-mark accessibility labels and the chart's accessibility representation; note the existing chart descriptor requirement in AGENTS.md. |
| A11Y-AUDIT-G06 | Settings | 14 | contrast 14 | Section headers (PROFILE, GUIDELINE, PREFERENCES, REMINDERS, WEEKLY SUMMARY) and the reminder caption. Likely secondary header/caption foreground on the grouped background. |
| A11Y-AUDIT-G07 | Onboarding | 10 | contrast 4, dynamicType 2, hitRegion 2, textClipped 2 | Welcome step: "Get Started" and the subtitle at default size, the heart emoji at AX5 and default size, and the "Step 1 of 4" progress element (hit region). |
| A11Y-AUDIT-G08 | History, Home, Insights, Settings | 15 | contrast 3, dynamicType 12 | Element `dp_health_sample_count`: a 1 pt, clear, test-only text overlay in `RootShellView.swift` that exists only under `UITestSeed.isActive`. Probably an audit artifact of the test hook, not user-visible UI; to be confirmed when the fix brief is written. |
| A11Y-AUDIT-G09 | History, Settings | 8 | contrast 6, textClipped 2 | Element with neither identifier nor label (`element=none`). It is not identified from the record; the owner brief must first locate it. |

Group totals: 111 + 4 + 49 + 65 + 35 + 14 + 10 + 15 + 8 = 311.

### Out-of-git result files

Directory `~/Library/Logs/DrinkPulse/phase-11-ios27/20261114T121519Z/` (the stamp directory of this capture; raw files stay outside git).

| File | Content | SHA-256 |
|------|---------|---------|
| `audit-exploratory.result.txt` | Xcode MCP `RunSomeTests` result text of the exploratory run (ungated class, commit `9aaf759`): 16 methods, 16 failed, 389 issue lines | sha256 `be5c2bcdcf05f4b472bdbdd0d9ec5b8a87c7809d010c233346820eb66b1967a9` |
| `audit-exploratory.txt` | the 311 distinct issue keys, one per line, sorted | sha256 `6b69633e951ba7258f286bc672acb7a5c3af47771567845a4094c08dbd655e8f` |
| `audit-exploratory.console.txt` | console log of the exploratory run | sha256 `8f55be4be311664e6cf722e77b1ded475fd641a2e662a4fd35ce1da7cd4269bf` |
| `audit-build.result.txt` | MCP build, code-issue and build-log results for the class | sha256 `33593d35b08eb514b48c786f6632a69b15725d7a7c6ccb5f601a8cbd27ee746c` |
| `audit-build.log` | build-for-testing log for the class | sha256 `a8cc53c304f45a15206009323c2edd7cb46a017a2ed7f0dd22b5b3ad4e8b9054` |
| `audit-gated.result.txt` | MCP `RunSomeTests` after gating (commit `509fd4b`): 16 tests, 16 skipped, 0 failed | sha256 `1c7fce146f1e62895d8f98a08e59a4d662126118daf2addb8a998a5c075a0f3d` |

Hash-format lines for the integrity check: `audit-exploratory.result.txt` sha256 `be5c2bcdcf05f4b472bdbdd0d9ec5b8a87c7809d010c233346820eb66b1967a9`; `audit-exploratory.txt` sha256 `6b69633e951ba7258f286bc672acb7a5c3af47771567845a4094c08dbd655e8f`; `audit-gated.result.txt` sha256 `1c7fce146f1e62895d8f98a08e59a4d662126118daf2addb8a998a5c075a0f3d`.

### Gated state and how to rerun

After D11-22 the class skips every method unless `DP_RUN_A11Y_AUDIT=1` is set in the test runner environment (for xcodebuild: `TEST_RUNNER_DP_RUN_A11Y_AUDIT=1`), the same pattern as `DP_RUN_FLASH_HARNESS`. Gated verification (Xcode MCP `RunSomeTests`, class `AccessibilityAuditUITests`, commit `509fd4b`): 16 tests, 16 skipped, 0 failed, 0 passed (`audit-gated.result.txt`). The skip message names the todo `2026-11-14-fix-accessibility-audit-findings`. With the flag set the class fails on every reported issue; there is no allow-list.

### Outcome for VER-03 (automated column)

audit run: 16 methods red, 311 open findings. All 311 are recorded open and unfixed (D11-22). Each fix needs an owner D-09 brief (accessibility is a D-09 trigger) and is tracked in `.planning/todos/pending/2026-11-14-fix-accessibility-audit-findings.md` and the grouped ledger rows `A11Y-AUDIT-G01` to `A11Y-AUDIT-G09`. The negative control from plan 11-03 does not apply: there is no allow-list to remove an entry from.

## Limitations

Filled by plan 11-04.

## Debt ledger and discovery reconciliation

Filled by plan 11-08.

## File size and source guards

Dated 2026-11-14, plan 11-01 (extended by plans 11-05 and 11-09).

| Guard | Command | Result |
|-------|---------|--------|
| Source guard against the phase-start commit | `git diff --quiet 2aa9156 -- drinkpulse drinkpulse.xcodeproj` | exit 0 |
| Shipped-schema guard | `git diff --quiet fbd37fa -- drinkpulse/Domain/Persistence/Schemas drinkpulse/Domain/Persistence/MigrationPlan.swift` | exit 0 |
| File size | `find drinkpulse -name "*.swift" -not -path "*/Preview Content/*" \| xargs wc -l \| awk '$1 > 300 && $2 != "total" {print}'` | empty output |
| Source guard after the D11-21 fix | `git diff --stat 2aa9156 -- drinkpulse drinkpulse.xcodeproj` (plan 11-11) | expected non-empty: exactly one file, `drinkpulse/Info.plist`, 1 insertion (the owner-approved D11-21 change); the project file is unchanged |
| Deployment target | every `IPHONEOS_DEPLOYMENT_TARGET` value in `drinkpulse.xcodeproj/project.pbxproj` | 8 values, all 27.0 |

## Requirement outcome

Filled by plan 11-08.
