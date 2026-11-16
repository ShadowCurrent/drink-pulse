# Phase 11 Evidence

Evidence for the iOS 27 release verification (MOD-04, VER-01, VER-02, VER-03). Capture started 2026-11-14 at base commit `4c04a25` (phase-start commit `2aa9156`; the working tree held no uncommitted change when capture began, `git status --short` empty). Xcode 27.2 (27B52), Apple Swift 6.4.2 (`swiftlang-6.4.2.1.9`), iphonesimulator 27.2 and iphoneos 27.2 SDKs. Primary destination: iPhone 18 Pro simulator, iOS 27.2 runtime build 24B8117. Raw logs stay outside git; every recorded log carries its SHA-256.

## Toolchain and destination

- **Xcode:** 27.2, build version 27B52 (`xcodebuild -version`). **Swift:** `Apple Swift version 6.4.2 (swiftlang-6.4.2.1.9 clang-2100.4.1.1)`, target `arm64-apple-macosx27.2.0` (`swift --version`); language mode `SWIFT_VERSION = 6.0` for the app and test targets. **SDKs:** `xcrun --sdk iphonesimulator --show-sdk-version` prints 27.2 and `xcrun --sdk iphoneos --show-sdk-version` prints 27.2. **Host:** `sw_vers` reports macOS ProductVersion 27.2.1, BuildVersion 26B131.
- **Destination (primary):** iPhone 18 Pro simulator on the iOS 27.2 runtime `com.apple.CoreSimulator.SimRuntime.iOS-27-2`, runtime build 24B8117 (`xcrun simctl list runtimes` prints `iOS 27.2 (27.2 - 24B8117)`). Exactly one device named "iPhone 18 Pro" exists under that runtime key; the `iOS-27-2-iPhone19-4` runtime (build 24B91016s) and the iOS 27.0 runtime were not used. The Xcode MCP active destination was the same device (Simulators group, osVersion 27.2). The simulator identifier is machine-specific and is deliberately not recorded; it is kept in the out-of-git `udid.txt` of the log directory.
- **Destination (secondary), plan 11-10 (2026-11-15):** iPhone 18 Pro Max simulator on the iOS 27.2 runtime `com.apple.CoreSimulator.SimRuntime.iOS-27-2`, runtime build 24B8117 (same runtime build as the primary; the result bundles of both runs report device name iPhone 18 Pro Max, osVersion 27.2, osBuildNumber 24B8117). It was selected in Xcode MCP as `iPhone 18 Pro Max (27.2)`; the iOS 27.0 variant, iPhone Duo and the 24B91016s runtime were not used. The simulator identifier is deliberately not recorded. The secondary run is a smoke cross-check on a larger screen (the audit class, skipped by its gate, and a short core-flow group of five classes), not a second full suite. After the runs the Xcode MCP active run destination was switched back to the primary `iPhone 18 Pro` and confirmed with `XcodeListRunDestinations` (isActive true): active destination restored.
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
- The iOS 27.0 runtime exists on this Mac but was not run in this phase; this is a limitation, recorded again as L-05 in the Limitations section by plan 11-04.
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

Rows G1 to G4 and U1 ran on the primary destination (plan 11-04, 2026-11-14); rows S1 and S2 ran on the secondary destination (plan 11-10, 2026-11-15). All runs are on the iOS 27.2 simulator, not a device.

Destination note (dated 2026-11-14, plan 11-04): the iOS 27.2 runtime build 24B8117 (`com.apple.CoreSimulator.SimRuntime.iOS-27-2`) was unavailable on 2026-11-14 after a CoreSimulator volume change at about 17:26; at that time `xcrun simctl` listed the iPhone 18 Pro as "unavailable, runtime profile not found" and the Xcode MCP active destination had fallen back to iPhone Duo on the `iOS-27-2-iPhone19-4` runtime (build 24B91016s). No test run was made in that state. The owner reinstalled the 24B8117 runtime, the iPhone 18 Pro came back with the same device UDID as in the out-of-git `udid.txt`, and the MCP destination was switched back to iPhone 18 Pro (iOS 27.2). No Phase 11 run used another runtime; every row below ran on the iPhone 18 Pro, iOS 27.2, build 24B8117.

Runner for every row: Xcode MCP `RunSomeTests` (owner decision D11-20); no CLI fallback was needed. Each result file is the MCP full-summary file of the run (one entry per test, state per test); the counts in the row come from the tool result. The matching console log of each run is saved next to it as `<group>.console.txt` in the same out-of-git directory.

| Group | Classes | Runner | Counts | Failed | Skipped | Mapping | Result file |
|-------|---------|--------|--------|--------|---------|---------|-------------|
| G1 | OnboardingFlowUITests, OnboardingHealthStepUITests, OnboardingLocaleDefaultUITests, OnboardingWeeklySummaryUITests, OnboardingAuthorityUITests, LaunchHandoffUITests, StartupErrorUITests, WeeklySummaryTapUITests, ShellNavigationUITests, SheetDismissTabSwitchUITests | Xcode MCP RunSomeTests | total=21 passed=19 failed=0 skipped=2 | failed: none | skipped: SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_cycle_staysNavigable_recordsFrameDeltas(), SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_emptyStore_recordsFrameDeltas() | no failure to map; the two D1 harness tests (DL-T05, DL-T06) report Skipped by the `DP_RUN_FLASH_HARNESS` gate, as expected; no harness variable was set | `g1-ui.result.txt` sha256 `f06f96dc879c0f495f9fa7571a479000b18b4cab4226e889f17788c1d32866d4` |
| G2 | AddDrinkFlowUITests, AddDrinkPickerFilterUITests, CurrencyUITests, CustomNameAutocompleteUITests, HealthWriteHooksUITests, VolumeServingUITests, EditVolumeIntegrityUITests, DuplicateEditPersistenceUITests, EditDeleteConfirmationUITests, ContextMenuDeleteConfirmationUITests, WrongRowContextMenuTargetUITests | Xcode MCP RunSomeTests | total=26 passed=26 failed=0 skipped=0 | failed: none | skipped: none | no failure to map; none of the known-red tests is in this group | `g2-ui.result.txt` sha256 `84a31f3cc6a5fc099b513ffe787582ac5be8bc8520bc27f0edea53ba3e5c3dfc` |
| G3 | HistoryInteractionUITests (with its DirectionalTransition, HitTarget, LoadingState and Pagination extensions), HistoryUnitDisplayUITests, HistoryDynamicTypeUITests, DashboardUITests | Xcode MCP RunSomeTests | total=22 passed=20 failed=2 skipped=0 | failed: HistoryInteractionUITests/test_editCustomNameAndNotes_persist(), HistoryInteractionUITests/test_editCategoryChange_persists() | skipped: none | both failures are on the known list: DL-T02 (failure line 165, "After save the row should show the custom name") and DL-T03 (failure line 220, "After changing to Wine the row should show the 150 ml wine default"); the data-integrity risk in the edit flow stays undetermined; the watched flake DL-T07 (`test_segmentSwitch_alternatingDirection_endsInCorrectState`) passed | `g3-ui.result.txt` sha256 `87819f3d112732355fe56ba4d11152507b81645027bf07446c47ed26079a3368` |
| G4 | InsightsUITests, InsightsScrubUITests, InsightsStreakUITests, InsightsDrinkFreeDaysUITests, SettingsUITests, GuidelinePickerUITests, HealthSettingsUITests, ReminderSettingsUITests, WeeklySummarySettingsUITests, AppVersionUITests, ExportUITests | Xcode MCP RunSomeTests | total=28 passed=28 failed=0 skipped=0 | failed: none | skipped: none | no failure to map; two known-list tests unexpectedly passed in this run: InsightsUITests/test_heroCard_holdsHeight_whenSwitchingToAllTimeScope() (DL-T01) and ExportUITests/test_export_dismissWithoutSaving_showsNoFailureAlert() (DL-T04, an intermittent flake); both stay on the ledger and in their todo and open-questions entries (one green run does not clear a reproducible or intermittent failure) | `g4-ui.result.txt` sha256 `01dab1098a2a306483e738091a6eb104e1f8c5cb1da0dbc2d45e8986323adcfa` |
| U1 | MigrationChainV1Tests, MigrationChainV2V3Tests, MigrationSweepTests, MigrationTests, StoreBootstrapTests, StartupErrorTests, RecordDeduplicatorTests, UserProfileStoreTests, DataImporterRoundTripTests, DataImporterUpsertTests, DataImporterEdgeCaseTests, ComprehensiveRoundTripTests, SanitizedBackupFixtureTests, DrinkControlImporterTests, DataBackupExportTests, AlcoholAreaChartAXDescriptorTests, WeekdayBarChartAXDescriptorTests, WeeklySummaryCompletedWeekTests, HealthServiceTests, HealthServiceOrderingTests, HealthServiceRemoveSampleTests, HealthServiceConcurrencyTests, HealthWriteHooksTests, NotificationActionHandlerTests (target drinkpulseTests; every name confirmed present in `GetTestList`, no correction needed) | Xcode MCP RunSomeTests | total=167 passed=167 failed=0 skipped=0 | failed: none | skipped: none | no failure to map; there is no known unit exception and none occurred; the run reports 167 tests while `GetTestList` enumerated 165 for these suites (the runner counts two more, probably expanded Swift Testing cases; the counts in this row are the runner's) | `u1-unit.result.txt` sha256 `0647811f905f013f1f914f402b64e169aa95998d9fd2b509e8bce1b368d9f702` |
| S1 | AccessibilityAuditUITests on iPhone 18 Pro Max, iOS 27.2 (secondary destination) | Xcode MCP RunSomeTests | total=16 passed=0 failed=0 skipped=16 | failed: none | skipped: all 16 `AccessibilityAuditUITests` methods (home, insights, history and settings at standard, AX5 and dark; addDrink and onboarding at standard and AX5) | no failure to map; the class is skipped-by-gate under owner decision D11-22 (`DP_RUN_A11Y_AUDIT` not set), which counts as a pass for this row; the audit was not run on the secondary destination, so larger-screen audit findings are not assessed in Phase 11 | `s1-audit-secondary.result.txt` sha256 `15e4fc704c17b839c31bfbd5dd3363764c326ee42e091fc4a1a5305a482d6a97` |
| S2 | OnboardingFlowUITests, ShellNavigationUITests, AddDrinkFlowUITests, DashboardUITests, SettingsUITests on iPhone 18 Pro Max, iOS 27.2 (secondary destination) | Xcode MCP RunSomeTests | total=23 passed=23 failed=0 skipped=0 | failed: none | skipped: none | no failure to map; none of the known-list tests is in these classes and none failed, so no isolated re-run and no flake entry | `s2-flows-secondary.result.txt` sha256 `1d3d3cd0522236f98a075b68531f1d2ae998864bc34d676dd79f2c230032fe20` |

G1: 2026-11-14, destination iPhone 18 Pro, iOS 27.2. G2: 2026-11-14, destination iPhone 18 Pro, iOS 27.2.
G3: 2026-11-14, destination iPhone 18 Pro, iOS 27.2. G4: 2026-11-14, destination iPhone 18 Pro, iOS 27.2.
S1 and S2: 2026-11-15, destination iPhone 18 Pro Max, iOS 27.2 (secondary), plan 11-10; the matching console logs are `s1-audit-secondary.console.txt` sha256 `cc9d7e95f63f588358cf8acfb4eab5d557914e2cb0b8f35c3d7a7c07454df787` and `s2-flows-secondary.console.txt` sha256 `9d70ad2dc916e86a4c899255f251e8d73d97023f6ec170a4d7191e21b8e5c423`.
U1: 2026-11-14 (finished just before midnight local time), destination iPhone 18 Pro, iOS 27.2. The MCP tool result listed only the first 100 of 167 tests; `u1-unit.result.txt` is the tool's full summary file and holds all 167 entries, each Passed.

## Full suite (VER-01)

Dated 2026-11-15 (run 2026-11-14 23:03 to 23:35 UTC, which is 00:04 to 00:35 local time on 2026-11-15), plan 11-05. Requirement VER-01. HEAD `6c437bc` (clean working tree at the start of the run). One unfiltered full-suite run with code coverage, destination iPhone 18 Pro, iOS 27.2 (runtime build 24B8117, `com.apple.CoreSimulator.SimRuntime.iOS-27-2`), Debug configuration, Xcode 27.2 (27B52). The device name and runtime were checked against `xcrun simctl list devices available` and the Xcode MCP `XcodeListRunDestinations` (active destination iPhone 18 Pro, osVersion 27.2) immediately before the run; the iPhone Duo and the 24B91016s runtime were not used.

- **Runner:** CLI `xcodebuild` (the second of the two CLI steps approved in owner decision D11-20). Named missing capability: code coverage collection (the shared scheme has no coverage setting and the MCP RunAllTests tool takes no coverage parameter). Run as one detached background job; nothing else built or tested while it ran.
- **Command:** `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=<udid>" -derivedDataPath build/p11-full -resultBundlePath build/p11-full.xcresult -enableCodeCoverage YES -collect-test-diagnostics never` (the simulator identifier is kept in the out-of-git `udid.txt` and is not recorded here), stdout and stderr to `full.log`, exit status to `full.exit`, both in the out-of-git stamp directory.
- **Exit status:** 0 (`full.exit` reads 0; the log ends with `** TEST SUCCEEDED **`).
- **Totals from `xcrun xcresulttool get test-results summary`:** total 834, passed 816, failed 0, skipped 18, expected failures 0, result Passed. By bundle (from `get test-results tests`): `drinkpulseTests` 721 passed; `drinkpulseUITests` 95 passed and 18 skipped.
- **Unit result line:** `Test run with 714 tests in 62 suites passed after 3.688 seconds.` (Swift Testing), plus the XCTest unit bundle line `Executed 7 tests, with 0 failures (0 unexpected) in 6.972 (6.978) seconds` (714 + 7 = 721, the bundle count).
- **UI result line:** `Executed 113 tests, with 18 tests skipped and 0 failures (0 unexpected) in 1855.692 (1855.828) seconds` for `drinkpulseUITests.xctest`.
- **Skipped (18):** the two D1 harness tests (`SheetDismissTabSwitchUITests`, gated by `DP_RUN_FLASH_HARNESS`) and the 16 `AccessibilityAuditUITests` methods (gated by `DP_RUN_A11Y_AUDIT`, owner decision D11-22). Both skip classes are expected and are skipped by their gate, not failures.
- `TEST_RUNNER_DP_RUN_FLASH_HARNESS was not set`; `TEST_RUNNER_DP_RUN_A11Y_AUDIT` and `DP_RUN_A11Y_AUDIT` were not set either (the shell environment held no `DP_RUN` or `TEST_RUNNER` variable).
- **Comparison:** historical (Phase 10, 2026-11-09): 678 unit tests in 59 suites, 93 UI tests in 1714 seconds, 94.61 percent overall coverage. Phase 11 (this run): 714 Swift Testing tests in 62 suites plus 7 XCTest unit tests, 113 UI tests (95 passed, 18 skipped) in 1855.692 seconds. Counts have grown since Phase 10 (the new audit class adds 16 gated UI methods); equality was not required.
- **Log:** `full.log` sha256 `79ae2971fa791aa2ed00aa248d71cedea67e0768d5c8696c17211652905dbdbc`.

### Failure mapping

The mapping was read from the result bundle itself (`xcrun xcresulttool get test-results tests`, 834 test cases), not from the log text. Failed test cases in the bundle: 0. There is therefore no failure to map, no test outside the known list failed, and no isolated re-run was needed.

| Test identifier | Result | Mapped to | Ledger row |
|-----------------|--------|-----------|------------|
| (none) | no test failed | no failure to map | n/a |
| SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_cycle_staysNavigable_recordsFrameDeltas() | Skipped | expected: D1 harness test gated by `DP_RUN_FLASH_HARNESS`, variable not set | DL-T05 |
| SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_emptyStore_recordsFrameDeltas() | Skipped | expected: D1 harness test, same gate | DL-T06 |
| AccessibilityAuditUITests (16 methods) | Skipped | expected: skipped by the `DP_RUN_A11Y_AUDIT` gate (owner decision D11-22), not a failure and not an exception; findings stay open in the accessibility audit section | DL-O01, A11Y-AUDIT-G01 to G09 |

Known tests that passed unexpectedly (all four known-list tests, plus the watched flake; every one stays on the ledger and its todo and open-questions entry is not touched):

- `InsightsUITests/test_heroCard_holdsHeight_whenSwitchingToAllTimeScope()` passed (DL-T01); it also passed in scoped row G4.
- `HistoryInteractionUITests/test_editCustomNameAndNotes_persist()` passed (DL-T02); it failed in scoped row G3 (plan 11-04).
- `HistoryInteractionUITests/test_editCategoryChange_persists()` passed (DL-T03); it failed in scoped row G3 (plan 11-04).
- `ExportUITests/test_export_dismissWithoutSaving_showsNoFailureAlert()` passed (DL-T04, intermittent); it also passed in G4.
- `HistoryInteractionUITests/test_segmentSwitch_alternatingDirection_endsInCorrectState()` passed (DL-T07, watched, not on the CONTEXT list).

The two History edit tests passed in the full run and failed in the scoped G3 run with the same code state. This is recorded as an observation only: it shows the failure depends on how the tests are run (full suite or class group), it does not establish whether the app or the test is wrong, and the data-integrity risk of the edit flow stays undetermined (L-02). No test, tolerance or todo was changed.

Newly observed flakes: none, so there is no `### Newly observed flakes` entry and no new todo.

Both D1 harness tests were Skipped in this full run: this closes the open item from plan 09-10 and ledger row DL-D08 (the first full run that confirms end to end that they stay skipped, with no simulator crash). Known-list tests: 0 failed, 0 skipped, 4 passed (DL-T01 to DL-T04).

## Coverage

Dated 2026-11-15, plan 11-05. Source: the result bundle of the full run in `## Full suite (VER-01)` (`build/p11-full.xcresult`, gitignored), read with `xcrun xccov view --report --json` (`coverage.json`) and the AGENTS.md command `xcrun xccov view --report --only-targets` (`coverage.txt`), both in the out-of-git stamp directory. Per-file figures are covered over executable lines from the JSON report; aggregates are sums of covered over sums of executable lines. Targets from AGENTS.md: overall at least 90 percent, Services at least 85 percent (thin framework adapters excluded), view models at least 90 percent, Domain 100 percent.

Overall line coverage: 94.65 percent (`drinkpulse.app`, 10554 of 11151 executable lines, 127 files). Requirement at least 90: met. The test targets for information: `drinkpulseTests.xctest` 99.11 percent (8248/8322), `drinkpulseUITests.xctest` 83.31 percent (3929/4716), not part of the gate. Comparison: historical (Phase 10, 2026-11-09): 94.61 percent overall.

Services aggregate (adapters excluded): 97.15 percent (443 of 456 executable lines; the files under `drinkpulse/Services` except `HealthKitAdapter.swift` and `NotificationScheduling.swift`, the AGENTS.md thin-adapter exclusion for framework wrappers). Requirement at least 85: met. Files in the aggregate: `HealthService.swift` 100.00 percent, `ReminderService.swift` 100.00, `HealthWriteHooks.swift` 100.00, `UITestHealthStore.swift` 100.00, `WeeklySummaryService.swift` 97.06 (132/136), `UITestNotificationCenter.swift` 93.75 (15/16), `NotificationActionHandler.swift` 75.00 (24/32). The two excluded adapters, listed and not gated: `HealthKitAdapter.swift` 20.41 percent (10/49) and `NotificationScheduling.swift` 0.00 percent (0/7).

Domain aggregate (non-Persistence): 90.06 percent (743 of 825 executable lines, 23 files, 15 at 100 percent). Against the Domain target of 100 percent: not met. Non-Persistence Domain files below 100 percent:

| File | Line coverage | Covered / executable |
|------|--------------:|---------------------:|
| `DrinkTemplate.swift` | 46.00 percent | 23 / 50 |
| `TemplateRecord.swift` | 64.10 percent | 25 / 39 |
| `BackupDocument.swift` | 66.67 percent | 6 / 9 |
| `BackupExport.swift` | 72.22 percent | 26 / 36 |
| `ConsumptionEvent.swift` | 82.76 percent | 72 / 87 |
| `Currency.swift` | 92.31 percent | 12 / 13 |
| `DataImporter.swift` | 94.84 percent | 147 / 155 |
| `DrinkControlImporter.swift` | 95.70 percent | 89 / 93 |

For information, `Domain/Persistence` (9 files, `SchemaV1` to `SchemaV4` and `MigrationPlan.swift` at 100 percent) is 96.77 percent (360/372); with it included the whole Domain folder is 92.15 percent (1103/1197). The Persistence files below 100 percent: `StoreBootstrap.swift`, `RecordDeduplicator.swift` 94.74 percent (36/38), `UserProfileStore.swift` 96.15 percent (25/26).

`StoreBootstrap.swift`: 93.02 percent (120 of 129 executable lines). It grew by 117 lines after the Phase 10 measurement of 96.1 percent, which is quoted as historical (Phase 10, 2026-11-09); the figure is recorded, not gated, and not explained further here.

View-model files aggregate, for information: 98.11 percent (676 of 689 executable lines, 7 files: `DashboardViewModel`, `HistoryViewModel`, `OnboardingViewModel`, `InsightsViewModel` and its three extension files); the target is at least 90 percent: met.

The Domain gap is the one tracked in WINDOWS.md rows 1 and 7 and in ledger rows DL-W01 and DL-W07 (also DL-Q14): it is listed, not closed and not waived. The figures above are newer than the numbers in those rows (Phase 07, 89.39 percent with 15 of 32 files below 100 percent, historical, 2026-08-04; the row 1 per-file values were recorded in phase 02); the rows stay open and only the owner changes them. No test was added in this phase (D11-02).

Integrity (out-of-git files): `coverage.json` sha256 `63efa07199243a14ecb8827d96905a1705aabac6194767581959371e212cb154`; `coverage.txt` sha256 `801a5c1913b859f082c53dbdbb2c9a582fed87f920341d8574888e4e70401f4c`.

## Core flow proof (VER-02)

Dated 2026-11-14, plan 11-04. Requirement VER-02. Every class named is in one of the rows G1 to G4 or U1 under `## Scoped runs (VER-02)`; results are taken from those rows. All runs are on the iPhone 18 Pro simulator, iOS 27.2, Debug configuration, against the in-memory seeded store (limitation L-04).

| Flow | Automated proof (class: result) | Result | Gap or limitation |
|------|---------------------------------|--------|-------------------|
| Onboarding | G1: OnboardingFlowUITests 3 passed, OnboardingHealthStepUITests 1 passed, OnboardingLocaleDefaultUITests 2 passed, OnboardingWeeklySummaryUITests 1 passed, OnboardingAuthorityUITests 1 passed | pass (8 of 8) | none beyond L-04 |
| Startup and retry | G1: LaunchHandoffUITests 2 passed, StartupErrorUITests 2 passed (error screen, retry), WeeklySummaryTapUITests 2 passed; U1: StartupErrorTests 4 passed, StoreBootstrapTests 14 passed | pass | interrupted migration is not re-tested (L-09, DL-R01) |
| Add | G2: AddDrinkFlowUITests 6 passed, AddDrinkPickerFilterUITests 1 passed, CurrencyUITests 2 passed, CustomNameAutocompleteUITests 1 passed, VolumeServingUITests 2 passed, HealthWriteHooksUITests 4 passed; G3: DashboardUITests 5 passed (logging a drink updates the visible count) | pass | Health write is proven through the UI hook and the Health unit suites in U1, not against real HealthKit |
| Edit | green: G2 EditVolumeIntegrityUITests 1 passed, DuplicateEditPersistenceUITests 2 passed. known red: G3 HistoryInteractionUITests/test_editCustomNameAndNotes_persist() (DL-T02, failed at line 165) and HistoryInteractionUITests/test_editCategoryChange_persists() (DL-T03, failed at line 220) | partial: 3 green, 2 known red | data-integrity risk undetermined: it is not established whether the app or the test is wrong (L-02) |
| Delete | G2: EditDeleteConfirmationUITests 2 passed, ContextMenuDeleteConfirmationUITests 3 passed, WrongRowContextMenuTargetUITests 2 passed, HealthWriteHooksUITests delete tests passed; G3: HistoryInteractionUITests context-menu delete and duplicate passed | pass | none beyond L-04 |
| History list | G3: HistoryInteractionUITests 10 passed (segment switch, hit target, loading state, pagination, context menu; the 3 calendar tests are counted in the next row), HistoryUnitDisplayUITests 1 passed, HistoryDynamicTypeUITests 1 passed (AX5 row) | pass (12 of 12 outside the two known-red edit tests) | the two edit tests are in the same class (L-02) |
| History calendar | G3: HistoryInteractionUITests test_segmentSwitch_togglesListAndCalendar, test_tapCalendarDay_revealsDayDetail, test_calendar_selectsTodayInitially_andNeverDeselects passed | pass (3 of 3) | none beyond L-04 |
| Insights | G4: InsightsUITests 7 passed, InsightsScrubUITests 2 passed, InsightsStreakUITests 1 passed, InsightsDrinkFreeDaysUITests 1 passed; U1: AlcoholAreaChartAXDescriptorTests 4 passed, WeekdayBarChartAXDescriptorTests 4 passed, WeeklySummaryCompletedWeekTests 8 passed | pass | `InsightsUITests/test_heroCard_holdsHeight_whenSwitchingToAllTimeScope()` (DL-T01) is on the known list and passed in this run (unexpectedly passed); it stays on the ledger |
| Settings | G4: SettingsUITests 5 passed, GuidelinePickerUITests 3 passed, HealthSettingsUITests 2 passed, ReminderSettingsUITests 2 passed, WeeklySummarySettingsUITests 2 passed, AppVersionUITests 1 passed; G1: ShellNavigationUITests 4 passed | pass | none beyond L-04 |
| Backup export | G4: ExportUITests 2 passed; U1: DataBackupExportTests 5 passed, ComprehensiveRoundTripTests 2 passed | pass | `ExportUITests/test_export_dismissWithoutSaving_showsNoFailureAlert()` (DL-T04, known intermittent flake) passed in this run (unexpectedly passed); it stays on the ledger |
| Backup import | none: no UI test. U1 unit suites: DataImporterRoundTripTests 11 passed, DataImporterUpsertTests 5 passed, DataImporterEdgeCaseTests 8 passed, SanitizedBackupFixtureTests 8 passed, DrinkControlImporterTests 14 passed | unit pass; UI flow unproven | see L-01: the import runs through the system file importer, which no UI test drives |
| Existing data preserved | U1: MigrationChainV1Tests 4, MigrationChainV2V3Tests 4, MigrationSweepTests 5, MigrationTests 4, StoreBootstrapTests 14, RecordDeduplicatorTests 5, UserProfileStoreTests 6 and the importer suites above, all passed. Historical, dated 2026-11-09: `10-DEVICE-SESSION.md` (Phase 10 owner device session): in-place upgrade of the existing install, 214 events before and after with counts equal, import round trip with all existing records skipped and no duplicates, edit and delete leaving the expected Health sample counts | pass for the unit suites (current run); the device proof is historical and not current | the device session predates ten changed production files (L-03); the UI tests run on an in-memory seeded store and cannot prove stored-data preservation (L-04) |

The device session figures are quoted as counts only, taken from `10-DEVICE-SESSION.md` as written on 2026-11-09; it also recorded one FAIL (a killed-app reminder tap) that its own follow-up of 2026-11-10 (`10-DEVICE-RETEST.md`) addresses. Nothing in this table repeats it as a Phase 11 result.

### Edge notes

- Adjacency: an import of records that already exist skips them without a duplicate, proven by `import_skipsExistingDuplicates` in `DataImporterEdgeCaseTests` (inside the passing U1 run; the name exists in the source file).
- Idempotency: importing the same backup twice inserts nothing twice, proven by `importTwice_noDoubleInsert` in `DataImporterEdgeCaseTests` (same run), with `reimportingSameBackup_isIdempotent` in `DataImporterUpsertTests` and `sanitized_reimportIsNoOp` in `SanitizedBackupFixtureTests`.
- Empty input: a fresh install completes onboarding to Home through `OnboardingFlowUITests` (G1); an import of a backup with zero events is not covered by a dedicated test, none was identified.
- Ordering: events that share the same day keep a stable order and the context menu targets the correct row (`WrongRowContextMenuTargetUITests` with the sameday dataset, G2); no separate equal-timestamp ordering test was identified.
- Concurrency and interruption: interrupted migration and interrupted Health write are acknowledged residuals DL-R01 and DL-R02 and are not re-tested here; store recovery on failure is covered by the `StoreBootstrapTests` rollback tests (U1) and `StartupErrorUITests` (G1).

## Accessibility (VER-03)

Sources: the automated audit (plan 11-03), the automated mapping to existing tests (plan 11-04), the owner checklist (plan 11-07, `11-A11Y-CHECKLIST.md`) and the secondary-destination smoke rows (plan 11-10). Checklist totals (11 items, CHK-00 to CHK-10): 3 pass (CHK-03, CHK-08, CHK-09), 3 fail (CHK-05, CHK-06, CHK-07), 5 open (CHK-00, CHK-01, CHK-02, CHK-04, CHK-10).

Automated audit result (plan 11-03, owner decision D11-22): audit run: 16 methods red, 385 reports, 311 byte-wise distinct keys (exploratory record, corrected 2026-11-16; 9 of the 16 rows are unreliable, see Record integrity). Details, counts and digests are in the next section. The audit class is skipped by default after the run (gated behind `DP_RUN_A11Y_AUDIT`), so plans 11-04, 11-05 and 11-10 treat it as skipped-by-gate, not as a failure. No finding is fixed or allow-listed.

Secondary destination (plan 11-10, 2026-11-15): row S1 ran `AccessibilityAuditUITests` on the iPhone 18 Pro Max, iOS 27.2 (secondary destination) without the gate variable: 16 skipped, 0 failed, skipped-by-gate (D11-22), a pass for the row. The audit was not run ungated there, so audit findings on the larger screen are not assessed in Phase 11. No ledger row and no allow-list entry was added. They are routed to the pending todo `2026-11-14-fix-accessibility-audit-findings`, whose rerun on the secondary destination is part of that work. The core-flow smoke group S2 passed 23 of 23 on the same destination (no layout break surfaced in the five flow classes).

Results are from the iOS 27.2 simulator and not a device. Automated and human results are kept in separate columns; the audit covers the visible viewport of each screen only. The Human column holds the owner results of plan 11-07. Plan 11-03 recorded the audit as prose because of D11-22, so the table was first created by plan 11-04.

| Check | Automated (source, result) | Human (checklist item, result) |
|-------|----------------------------|--------------------------------|
| Accessibility audit, all tabs, Add Drink, Onboarding (performAccessibilityAudit) | `AccessibilityAuditUITests`, 16 methods, Xcode MCP: exploratory run 16 red with 385 reports, 311 byte-wise distinct keys (exploratory record, corrected; 9 rows unreliable) (D11-22); gated default run 16 skipped, 0 failed (`audit-gated.result.txt` sha256 `1c7fce146f1e62895d8f98a08e59a4d662126118daf2addb8a998a5c075a0f3d`); findings are open, not allow-listed (ledger A11Y-AUDIT-G01 to G09) | n/a (CHK-07 and CHK-08 observe the same screens) |
| Dynamic Type through AX5 | audit AX5 variants (Home, Insights, History, Settings, Add Drink, Onboarding) are inside the exploratory audit run above; existing test `HistoryDynamicTypeUITests/test_row_growsAndStaysHittable_atAX5()` passed in row G3 (1 test, plan 11-04, 2026-11-14) | CHK-07 fail: truncated, clipped or overlapping text at AX5 on Home, Insights, Add Drink, Settings Preferences and Onboarding; guideline picker and History fine (brief C016) |
| Light and dark appearance | audit dark variants (Home, Insights, History, Settings) are inside the exploratory audit run above; existing test `SettingsUITests/test_appearanceMode_reflectsSelectedOption()` passed in row G4 (plan 11-04, 2026-11-14) | CHK-08 pass: light and dark fine on all tabs and the Add Drink sheet |
| Increase Contrast | none: no automated route (see plan 11-06 for the human check) | CHK-09 pass: Increase Contrast in both appearances, everything very readable |
| VoiceOver traversal | `ShellNavigationUITests/test_withVoiceOverRunning_focusCancelThenActivate_dismissesAddDrinkToOriginatingHistoryTab()` passed in row G1 (plan 11-04, 2026-11-14); it covers the Add Drink dismissal under VoiceOver, not a full traversal; no automated full VoiceOver traversal exists | CHK-00 open: VoiceOver switches on but the rotor cannot be opened on the simulator, requires device; CHK-10 open: reason CHK-00 |
| Chart Audio Graph content | `AlcoholAreaChartAXDescriptorTests` (4) and `WeekdayBarChartAXDescriptorTests` (4) passed in row U1 (plan 11-04, 2026-11-14); they check the descriptor data, not what VoiceOver speaks | CHK-01 open: reason CHK-00; CHK-02 open: reason CHK-00 (owner observation OBS-A on chart points, brief OBS-A) |
| Reduce Motion | none: no automated route (see plan 11-06 for the human check) | CHK-03 pass (caveat: no callout animation visible with Reduce Motion on or off); CHK-04 open (arc covered by the sheet when it refreshes); CHK-05 fail (brief C014); CHK-06 fail (brief C015) |

The human results above are from the iOS 27.2 simulator and not a device (owner session of plan 11-07, 2026-11-16). Automated results are unchanged in the middle column. Three owner observations are outside the checklist items: OBS-A (VoiceOver reads a very large number for an Insights chart point; likely defect, owner brief `11-DECISION-OBS-A.md`, cause is an unverified hypothesis), OBS-B (VoiceOver speaks some elements in English and some in Polish; probable cause: English-only app on a Polish simulator; observation only) and OBS-C (Settings tab shows an endless progress indicator when the store has no profile; edge-case defect, owner brief `11-DECISION-OBS-C.md`). Session integrity: settings were switched with the Xcode 27 Device Hub app, and part of the early CHK-07 walk ran from an icon launch without the seeded arguments; layout and Reduce Motion observations do not depend on the dataset. Items CHK-04 and the three Audio Graph and VoiceOver items remain open and are carried in the debt ledger (DL-O04 onward). The clone simulator was deleted after the session.

## Accessibility audit (exploratory run, D11-22)

Dated 2026-11-14, plan 11-03. Requirement VER-03 (automated column). CONTEXT decisions D11-12 (audit class) and D11-22 (owner: findings are recorded as open, not allow-listed and not fixed; this supersedes D11-12's "allow-list, green run" contract). Results are from the iOS 27.2 simulator (iPhone 18 Pro), not a device, and cover the automated audit only; the human results stay in their own column of the VER-03 table (plan 11-07).

### What was run

- **Class:** `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift`, 16 methods: Home, Insights, History and Settings at default size, AX5 and dark (12), Add Drink and Onboarding at default size and AX5 (4). Each launches the app with the existing in-memory test seed, reaches the screen, asserts it was reached, then calls `performAccessibilityAudit(for: .all)`; the issue handler records every reported issue as its own test failure.
- **Code state of the exploratory run:** commit `9aaf759` (empty allow-list, so every issue failed the test). The run also showed a test-code defect, fixed afterwards in `7bea6da`: the dark-variant teardown set `XCUIDevice.shared.appearance = .unspecified`, which the simulator rejects (`Failed to set appearance mode: Requested appearance value (0) is not valid`, 4 occurrences, one per dark method). The 4 teardown failures are not audit findings and are not counted below; the result file holds 389 issue lines = 385 audit reports + 4 teardown failures.
- **Runner:** Xcode MCP `RunSomeTests` (target `drinkpulseUITests`, identifier `AccessibilityAuditUITests`), the whole class once. Result: 16 tests, 16 failed. The MCP result carried every per-issue message, so no CLI fallback was needed. Build check of the class: MCP `BuildProject` with `buildForTesting` true built successfully, `XcodeRefreshCodeIssuesInFile` reported no issues (diagnosticsCount 0), and `GetBuildLog` at warning severity returned 0 entries (`audit-build.result.txt`).
- **Official source (read in this plan):** `XCUIApplication.h` in the Xcode 27.2 iPhoneOS SDK documents `performAccessibilityAuditWithAuditTypes:issueHandler:error:` (issue handler; returning YES marks an issue as handled; available iOS 17.0 and later, inside the iOS 27.0 deployment target). `XCUIAccessibilityAuditTypes.h` lists contrast, elementDetection, hitRegion, sufficientElementDescription, dynamicType, textClipped, trait and all. `XCUIDevice.h` documents `appearance` (unspecified, light, dark).
- **Limits:** the audit covers the visible viewport of each screen at its launch scroll position. It does not exercise Increase Contrast or Reduce Motion (human-only, plan 11-06). Issue keys use the element identifier, else its label; they never use the system-localized issue description (the simulator locale is Polish).

### Counts

Correction of 2026-11-16 (plan 11-12). 385 audit reports collapse to 311 byte-wise distinct keys (`screen=... variant=... type=... element=...`). 311 is also the line count of `audit-exploratory.txt`, and every one of its 311 lines is different. Earlier text in this file presented 311 as the count of open findings; the accurate wording is "385 reports, 311 byte-wise distinct keys", of which 9 of the 16 method rows are unreliable (see Record integrity). By type (distinct keys): contrast 144, dynamicType 73, textClipped 57, sufficientElementDescription 21, hitRegion 16.

Count correction note: 11-VERIFICATION.md (truth T18) reported "254 distinct keys" and "57 repeats" in the 311 lines. Recomputation shows that 254 is not a count of distinct keys. `sort -u` under the simulator host locale (pl_PL.UTF-8) collates different emoji element names as equal (for example the cactus and the coffee cup, both a drink-type tile name), so it prints 254 lines; the same command with `LC_ALL=C` (byte-wise comparison) prints 311. The file has no repeated line. The figure 254 must not be used as a distinct-key count.

Recomputation commands (run 2026-11-16 in the stamp directory named under Out-of-git result files; results are outputs of the commands as run):

| Command | Output |
|---------|--------|
| `wc -l < audit-exploratory.txt` | 311 |
| `LC_ALL=C sort -u audit-exploratory.txt \| wc -l` | 311 |
| `sort -u audit-exploratory.txt \| wc -l` (pl_PL.UTF-8) | 254 (locale artifact: emoji collate equal) |
| `grep -c 'screen=' audit-exploratory.result.txt` | 385 |
| `grep 'screen=' audit-exploratory.result.txt \| sed 's/.*Accessibility audit issue: //' \| LC_ALL=C sort -u \| wc -l` | 311 |

The per-type, per-screen and group figures below were recomputed with a byte-wise distinct pass over `audit-exploratory.txt` and agree with the earlier tables; no figure in them changes.

### Record integrity (correction of 2026-11-16)

Cause: the dark-variant teardown set `XCUIDevice.shared.appearance = .unspecified`, which the simulator rejects (see What was run). The failed restore left the simulator in dark appearance, and the standard and AX5 variants never set light, so every method that ran after the first dark method (`test_audit_history_dark`, console line order) ran in dark appearance. Methods run alphabetically: `addDrink_ax5`, `addDrink_standard`, `history_ax5`, `history_dark`, `history_standard`, `home_ax5`, `home_dark`, `home_standard`, `insights_ax5`, `insights_dark`, `insights_standard`, `onboarding_ax5`, `onboarding_standard`, `settings_ax5`, `settings_dark`, `settings_standard` (confirmed against the `Test Case ... started` lines and the four `Setting appearance mode to Dark` lines of `audit-exploratory.console.txt`).

Unreliable rows (ran in dark appearance but labelled standard or AX5): `history_standard`, `home_ax5`, `home_standard`, `insights_ax5`, `insights_standard`, `onboarding_ax5`, `onboarding_standard`, `settings_ax5` and `settings_standard` (9 rows). Valid rows: `addDrink_ax5`, `addDrink_standard` and `history_ax5` (ran before the leak) and the four `*_dark` rows (dark by design). The symptom is that the standard and dark key sets are identical for Home, History and Settings in the table below (Home 16/6/1 for both, History 2/1/1, Settings 7/1/0). The contrast, dynamic type and clipping figures of the unreliable rows are therefore not reliable for the appearance and size their labels claim.

The refreshed baseline of plan 11-13 (harness fixed in plan 11-12: appearance pinned for every variant, navigation failure stops the audit) supersedes this exploratory record for planning fixes. This section stays as history; it is superseded, not deleted, and digests and dates are unchanged. Group assignments in `11-DEBT-LEDGER.md` for the unreliable rows are provisional until plan 11-13.

Distinct keys by screen, variant and audit type:

| Screen | Variant | contrast | dynamicType | textClipped | sufficientElementDescription | hitRegion | Total | Record |
|--------|---------|---------:|------------:|------------:|-----------------------------:|----------:|------:|--------|
| Home | standard | 16 | 6 | 1 | 0 | 0 | 23 | unreliable (ran in dark) |
| Home | ax5 | 3 | 3 | 0 | 0 | 0 | 6 | unreliable (ran in dark) |
| Home | dark | 16 | 6 | 1 | 0 | 0 | 23 | valid |
| Insights | standard | 13 | 12 | 5 | 7 | 0 | 37 | unreliable (ran in dark) |
| Insights | ax5 | 5 | 3 | 0 | 7 | 7 | 22 | unreliable (ran in dark) |
| Insights | dark | 13 | 12 | 5 | 7 | 7 | 44 | valid |
| History | standard | 2 | 1 | 1 | 0 | 0 | 4 | unreliable (ran in dark) |
| History | ax5 | 2 | 1 | 0 | 0 | 0 | 3 | valid |
| History | dark | 2 | 1 | 1 | 0 | 0 | 4 | valid |
| Settings | standard | 7 | 1 | 0 | 0 | 0 | 8 | unreliable (ran in dark) |
| Settings | ax5 | 3 | 1 | 0 | 0 | 0 | 4 | unreliable (ran in dark) |
| Settings | dark | 7 | 1 | 0 | 0 | 0 | 8 | valid |
| Add Drink | standard | 30 | 14 | 24 | 0 | 0 | 68 | valid |
| Add Drink | ax5 | 21 | 9 | 17 | 0 | 0 | 47 | valid |
| Onboarding | standard | 3 | 1 | 1 | 0 | 1 | 6 | unreliable (ran in dark) |
| Onboarding | ax5 | 1 | 1 | 1 | 0 | 1 | 4 | unreliable (ran in dark) |
| **All** | | 144 | 73 | 57 | 21 | 16 | 311 | |

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

Group totals (distinct keys, byte-wise): 111 + 4 + 49 + 65 + 35 + 14 + 10 + 15 + 8 = 311. Group assignment for the unreliable rows is provisional until plan 11-13.

### Out-of-git result files

Directory `~/Library/Logs/DrinkPulse/phase-11-ios27/20261114T121519Z/` (the stamp directory of this capture; raw files stay outside git).

| File | Content | SHA-256 |
|------|---------|---------|
| `audit-exploratory.result.txt` | Xcode MCP `RunSomeTests` result text of the exploratory run (ungated class, commit `9aaf759`): 16 methods, 16 failed, 389 issue lines | sha256 `be5c2bcdcf05f4b472bdbdd0d9ec5b8a87c7809d010c233346820eb66b1967a9` |
| `audit-exploratory.txt` | the 311 byte-wise distinct issue keys (a key per line), sorted | sha256 `6b69633e951ba7258f286bc672acb7a5c3af47771567845a4094c08dbd655e8f` |
| `audit-exploratory.console.txt` | console log of the exploratory run | sha256 `8f55be4be311664e6cf722e77b1ded475fd641a2e662a4fd35ce1da7cd4269bf` |
| `audit-build.result.txt` | MCP build, code-issue and build-log results for the class | sha256 `33593d35b08eb514b48c786f6632a69b15725d7a7c6ccb5f601a8cbd27ee746c` |
| `audit-build.log` | build-for-testing log for the class | sha256 `a8cc53c304f45a15206009323c2edd7cb46a017a2ed7f0dd22b5b3ad4e8b9054` |
| `audit-gated.result.txt` | MCP `RunSomeTests` after gating (commit `509fd4b`): 16 tests, 16 skipped, 0 failed | sha256 `1c7fce146f1e62895d8f98a08e59a4d662126118daf2addb8a998a5c075a0f3d` |

Hash-format lines for the integrity check: `audit-exploratory.result.txt` sha256 `be5c2bcdcf05f4b472bdbdd0d9ec5b8a87c7809d010c233346820eb66b1967a9`; `audit-exploratory.txt` sha256 `6b69633e951ba7258f286bc672acb7a5c3af47771567845a4094c08dbd655e8f`; `audit-gated.result.txt` sha256 `1c7fce146f1e62895d8f98a08e59a4d662126118daf2addb8a998a5c075a0f3d`.

### Gated state and how to rerun

After D11-22 the class skips every method unless `DP_RUN_A11Y_AUDIT=1` is set in the test runner environment (for xcodebuild: `TEST_RUNNER_DP_RUN_A11Y_AUDIT=1`), the same pattern as `DP_RUN_FLASH_HARNESS`. Gated verification (Xcode MCP `RunSomeTests`, class `AccessibilityAuditUITests`, commit `509fd4b`): 16 tests, 16 skipped, 0 failed, 0 passed (`audit-gated.result.txt`). The skip message names the todo `2026-11-14-fix-accessibility-audit-findings`. With the flag set the class fails on every reported issue; there is no allow-list.

### Outcome for VER-03 (automated column)

audit run: 16 methods red, 385 reports, 311 byte-wise distinct keys (exploratory record, corrected 2026-11-16; 9 rows unreliable, superseded by the refreshed baseline of plan 11-13). All are recorded open and unfixed (D11-22). Each fix needs an owner D-09 brief (accessibility is a D-09 trigger) and is tracked in `.planning/todos/pending/2026-11-14-fix-accessibility-audit-findings.md` and the grouped ledger rows `A11Y-AUDIT-G01` to `A11Y-AUDIT-G09`. The negative control from plan 11-03 does not apply: there is no allow-list to remove an entry from.

## Accessibility audit (refreshed baseline, plan 11-13)

Dated 2026-11-16, plan 11-13, requirements VER-03 and VER-01. HEAD `a1ee818` (the owner's scheme change was the only uncommitted file; no source or test file changed). This baseline supersedes the exploratory record of 2026-11-14 for planning fixes. CONTEXT decisions: D11-22 (findings stay recorded, none allow-listed), D11-25 (all groups are to be fixed; this run fixes the scope), D11-26 (audit runner and gate mechanism).

### What was run

- **Runner:** Xcode MCP `RunSomeTests`, target `drinkpulseUITests`, identifier `AccessibilityAuditUITests`, the whole class once, on the active destination iPhone 18 Pro (iOS 27.2 simulator). No CLI `xcodebuild` run was made and no second run of the class was made to see whether it changes.
- **Gate mechanism (D11-26, as realized):** the owner added the environment variable `DP_RUN_A11Y_AUDIT=1` to the drinkpulse scheme under the Run (Debug) action, because the Test action showed no Arguments tab in the owner's Xcode. The Test action has `shouldUseLaunchSchemeArgsEnv = "YES"`, so it inherits the Run action's environment. Arrival at the test runner was observed, not assumed: the counts show 0 skipped (the ungated class skips 16 of 16). The scheme change was never committed by this plan.
- **Harness:** the hardened harness of plan 11-12 (appearance pinned for every variant, a navigation failure stops the screen).

### Counts

Gate check: total 16, skipped 0, passed 0, failed 16 (each method fails by design, one failure per audit report). Report count 385 (issue lines in `audit-baseline.result.txt`, summed per method: 25, 6, 25, 44, 15, 44, 26, 5, 26, 8, 4, 8, 80, 59, 6, 4). Distinct key count 311 (`LC_ALL=C sort -u`, byte-wise; `wc -l` of `audit-baseline.txt` is 311 and every line is different). The MCP response itself truncates each method to 5 messages; the full per-method list is in the saved result file.

| Audit type | Reports | Distinct keys |
|------------|--------:|--------------:|
| contrast | 200 | 144 |
| dynamicType | 83 | 73 |
| textClipped | 65 | 57 |
| sufficientElementDescription | 21 | 21 |
| hitRegion | 16 | 16 |
| **All** | 385 | 311 |

Distinct keys by screen, variant and audit type (the Reports column is the number of issue lines of that method):

| Screen | Variant | contrast | dynamicType | textClipped | sufficientElementDescription | hitRegion | Total | Reports |
|--------|---------|---------:|------------:|------------:|-----------------------------:|----------:|------:|--------:|
| Home | standard | 16 | 6 | 1 | 0 | 0 | 23 | 25 |
| Home | ax5 | 3 | 3 | 0 | 0 | 0 | 6 | 6 |
| Home | dark | 16 | 6 | 1 | 0 | 0 | 23 | 25 |
| Insights | standard | 13 | 12 | 5 | 7 | 7 | 44 | 44 |
| Insights | ax5 | 5 | 3 | 0 | 7 | 0 | 15 | 15 |
| Insights | dark | 13 | 12 | 5 | 7 | 7 | 44 | 44 |
| History | standard | 2 | 1 | 1 | 0 | 0 | 4 | 26 |
| History | ax5 | 2 | 1 | 0 | 0 | 0 | 3 | 5 |
| History | dark | 2 | 1 | 1 | 0 | 0 | 4 | 26 |
| Settings | standard | 7 | 1 | 0 | 0 | 0 | 8 | 8 |
| Settings | ax5 | 3 | 1 | 0 | 0 | 0 | 4 | 4 |
| Settings | dark | 7 | 1 | 0 | 0 | 0 | 8 | 8 |
| Add Drink | standard | 30 | 14 | 24 | 0 | 0 | 68 | 80 |
| Add Drink | ax5 | 21 | 9 | 17 | 0 | 0 | 47 | 59 |
| Onboarding | standard | 3 | 1 | 1 | 0 | 1 | 6 | 6 |
| Onboarding | ax5 | 1 | 1 | 1 | 0 | 1 | 4 | 4 |
| **All** | | 144 | 73 | 57 | 21 | 16 | 311 | 385 |

Comparison with the superseded exploratory record (385 reports, 311 byte-wise distinct keys, 2026-11-14, nine rows unreliable): the report count and the distinct key count are the same, and per screen, variant and type every cell is the same except Insights hitRegion (exploratory: ax5 7, standard 0; refreshed: ax5 0, standard 7; dark 7 in both). The exploratory dark leak therefore did not change any other count. 68 keys differ as text only, because they carry values that move with the date of the run (the chart mark timestamps, the date line "16. Nov" against "14. Nov", the week range and the comparison figures), and the History unlabeled key is now written `element=none#type=nil` instead of `element=none`.

### Validity checks

| Check | Result |
|-------|--------|
| Navigation-failure messages of the harness (`should exist`, `should be shown`) in `audit-baseline.result.txt` | 0 |
| `Failed to set appearance mode` in `audit-baseline.console.txt` | 0 |
| Failures in the result file that are not audit reports | 0 (every failure line is the audit record at `AccessibilityAuditUITests.swift:129`) |
| Order of the 16 methods in the console | `addDrink_ax5`, `addDrink_standard`, `history_ax5`, `history_dark`, `history_standard`, `home_ax5`, `home_dark`, `home_standard`, `insights_ax5`, `insights_dark`, `insights_standard`, `onboarding_ax5`, `onboarding_standard`, `settings_ax5`, `settings_dark`, `settings_standard` |
| Appearance pin | `Setting appearance mode to Dark` appears 4 times, once at the start of each `*_dark` method; `Setting appearance mode to Light` appears 28 times (12 at the start of the other methods and 16 restores, one at the end of every method). No method after a dark one ran in dark. |

Every variant label is valid by these checks. Two observations qualify that and are open, not blockers: (1) the light and dark key sets are identical on Home, Insights, History and Settings (0 differing keys on each), so the keys alone cannot show that the appearance reached the app; the console pin lines are the only proof, and the cause (the audit reports the same elements in both appearances, or the appearance does not reach the audited window) is not established; (2) the Insights hitRegion keys moved between variants between the two runs, so that finding is not stable per variant (the total of 14 across standard and dark plus 0 at ax5 against 14 across ax5 and dark is the same size but not the same cells). A fix plan that proves a hitRegion fix must compare the sum for the screen, not a single variant, until the cause is known.

### Group mapping

Every distinct key is assigned with the ledger's group definitions (screen, audit type, and the element names named there): Add Drink with element `Cancel` is G02 and the other Add Drink keys are G01; Home is G03; Insights timestamp elements (identifier is a raw number such as `816476400.0`) are G05 and the other Insights keys are G04; Settings is G06; Onboarding is G07; the element `dp_health_sample_count` on any screen is G08; a key `none#type=...` is G09. No key fits no group, so there is no group G10 or higher.

| Group | Screen | Distinct keys | Types (keys) |
|-------|--------|--------------:|--------------|
| A11Y-AUDIT-G01 | Add Drink | 111 | contrast 49, dynamicType 21, textClipped 41 |
| A11Y-AUDIT-G02 | Add Drink | 4 | contrast 2, dynamicType 2 |
| A11Y-AUDIT-G03 | Home | 49 | contrast 35, dynamicType 12, textClipped 2 |
| A11Y-AUDIT-G04 | Insights | 65 | contrast 31, dynamicType 24, textClipped 10 |
| A11Y-AUDIT-G05 | Insights | 35 | sufficientElementDescription 21, hitRegion 14 |
| A11Y-AUDIT-G06 | Settings | 14 | contrast 14 |
| A11Y-AUDIT-G07 | Onboarding | 10 | contrast 4, dynamicType 2, hitRegion 2, textClipped 2 |
| A11Y-AUDIT-G08 | History, Home, Insights, Settings | 15 | contrast 3, dynamicType 12 |
| A11Y-AUDIT-G09 | History, Settings | 8 | contrast 6, textClipped 2 |

Total: 111 + 4 + 49 + 65 + 35 + 14 + 10 + 15 + 8 = 311. The group totals are the same as the exploratory grouping.

**Group G09 (element with neither identifier nor label):** all 8 keys are `none#type=nil`, not a located key. The harness records `none#type=<element type>@<frame>` only when the audit issue carries an element; here the issue carries no element object at all, so no element type and no frame class can be taken from the record. The keys are History (standard, ax5, dark: contrast; standard and dark: textClipped) and Settings (standard, ax5, dark: contrast). By reports this is not small: History has 23 contrast reports at standard and at dark and 3 at ax5, each folded into one key, plus 1 textClipped at standard and at dark; Settings has 1 contrast report per variant. Locating the element needs another method than the key (for example the audit issue's own description or a screenshot at the time of the issue); that is a step for the fix plan of the History and Settings screens.

**Group G08:** the probe overlay `dp_health_sample_count` is expected to be removed by plan 11-15; the baseline keys of G08 should then drop out of the next audit run.

**Scope rule:** the screen fix plans 11-16 to 11-21 fix every baseline finding on their screen, whichever group ID it carries.

### Out-of-git result files

Directory `~/Library/Logs/DrinkPulse/phase-11-ios27/20261114T121519Z/` (the stamp directory of this capture; raw files stay outside git; the full-result text of the MCP call was copied unchanged into `audit-baseline.result.txt`).

| File | Content | SHA-256 |
|------|---------|---------|
| `audit-baseline.counts.txt` | the MCP counts line (total 16, skipped 0, failed 16) | sha256 `c52329f2dc63b9ce8e4869cd14391feac0c538c9c2b27f850d6c97d65921b3bb` |
| `audit-baseline.result.txt` | MCP `RunSomeTests` full per-test summary: 16 methods, 385 issue lines | sha256 `7c65da67a36e9d3b2397e18340eaaefa46771a412d7fe5a37d61c918669f4a91` |
| `audit-baseline.console.txt` | MCP `GetConsoleOutput` (all output types, 1822 entries) of the run | sha256 `dce26e8e68976f6488c0b2a07e4a805ae8dd021fe2503a87dbf83c4673fa3d48` |
| `audit-baseline.txt` | the 311 byte-wise distinct issue keys (a key per line), `LC_ALL=C sort -u` | sha256 `bbdd7958188f41ba5ef0e8f38b0b1a54b7fca5410c3e3590094c71fddb402f66` |

The `audit-baseline.counts.txt` line was reconstructed from the MCP JSON counts of the call (expectedFailures 0, failed 16, notRun 0, passed 0, skipped 0, total 16); the raw tool response is not stored.

## Limitations

Dated 2026-11-14, plan 11-04. Limitations that qualify the VER-01 and VER-02 results above. Cause and ledger links are recorded; none is fixed in Phase 11.

| ID | Limitation | Cause or evidence | Where recorded |
|----|------------|-------------------|----------------|
| L-01 | Backup import has no UI test. | `DataSection` shows the import through the system file importer (`fileImporter`) and the export through the system file exporter (`fileExporter`). The simulator system locale is Polish, so a system picker must not be matched by its label; the export dismiss test is already a known flake (DL-T04). Backed by the importer unit suites in row U1 (DataImporterRoundTripTests, DataImporterUpsertTests, DataImporterEdgeCaseTests, SanitizedBackupFixtureTests, DrinkControlImporterTests) and the Phase 10 device import round trip (historical, 2026-11-09). No new UI test that drives the system picker was added. | Core flow proof row Backup import; ledger DL-T04 |
| L-02 | Edit coverage is partial. | `HistoryInteractionUITests/test_editCustomNameAndNotes_persist()` and `test_editCategoryChange_persists()` fail (DL-T02, DL-T03, todo `2026-11-13-history-edit-uitests-failing`). It is not established whether the app or the test is wrong, so the data-integrity risk in the edit flow is undetermined. The green edit proof is `EditVolumeIntegrityUITests` and `DuplicateEditPersistenceUITests`. | Core flow proof row Edit; ledger DL-T02, DL-T03 |
| L-03 | The Phase 10 device proof predates ten changed production files and is historical. | The device session ran on 2026-11-09 against commit `a38a75f`. `git diff --stat a38a75f HEAD -- drinkpulse` on 2026-11-14 lists ten files (nine expected plus the owner-approved D11-21 change), named one by one with lines added and removed: `drinkpulse/Domain/GuidelineLimits.swift` (1 added, 3 removed); `drinkpulse/Domain/Persistence/StoreBootstrap.swift` (98 added, 19 removed); `drinkpulse/Features/Dashboard/DashboardView.swift` (11 added, 13 removed; the container revert, commit `5b95ab7`); `drinkpulse/Features/Settings/AppVersionInfo.swift` (121 added); `drinkpulse/Features/Settings/Components/AppVersionFooter.swift` (44 added); `drinkpulse/Features/Settings/SettingsView.swift` (2 added); `drinkpulse/Localizable.xcstrings` (55 added); `drinkpulse/Services/HealthService.swift` (14 added, 5 removed); `drinkpulse/Services/WeeklySummaryService.swift` (29 added, 13 removed); `drinkpulse/Info.plist` (1 added, the D11-21 iPad orientation entry, plan 11-11). The live list differs from the expected nine only by `drinkpulse/Info.plist`. The test-file gating of the two D1 harness tests (commit `7631c4d`, 2026-11-13) also came after `a38a75f`; it is a test-file change, not a production file. Substitute evidence in this phase: `StoreBootstrapTests` (rollback, recovery), `WeeklySummaryCompletedWeekTests` and the Health suites (`HealthServiceTests`, `HealthServiceOrderingTests`, `HealthServiceRemoveSampleTests`, `HealthServiceConcurrencyTests`, `HealthWriteHooksTests`), all in row U1 and all passed. No new device session is planned (CONTEXT). | Core flow proof row Existing data preserved; `10-DEVICE-SESSION.md` |
| L-04 | UI tests run on an in-memory seeded store. | The `dp_uitest` launch hook seeds an in-memory store, so UI tests cannot prove that stored user data survives an upgrade. The migration unit suites (row U1) and the Phase 10 device session (historical) are the proof for that. | Core flow proof |
| L-05 | The iOS 27.0 runtime was not run. | The build used SDK 27.2 with deployment target 27.0 and every run was on the iOS 27.2 runtime (build 24B8117); the iOS 27.0 runtime exists on this Mac but was not used. | Toolchain change vs Phase 08 |
| L-06 | No physical device was used in Phase 11. | Flows and accessibility were checked on the simulator only; device checks are deferred by CONTEXT. | Scoped runs; Accessibility (VER-03) |
| L-07 | The Release device-SDK build is compile and link only. | The Release build used `generic/platform=iOS` with `CODE_SIGNING_ALLOWED=NO`; it is not a signed archive. | Build rows |
| L-08 | Tests ran in the Debug configuration only. | Project norm; there was no Release test run. | Scoped runs |
| L-09 | Interrupted migration and interrupted Health write remain acknowledged residuals. | DL-R01 and DL-R02 from `10-DEVICE-SESSION.md`: a process kill during a real migration, or between the HealthKit save and the local cache write, cannot be reproduced on demand. Not re-tested in Phase 11; store recovery on failure is exercised by `StoreBootstrapTests` rollback tests and `StartupErrorUITests`. | ledger DL-R01, DL-R02 |

## Debt ledger and discovery reconciliation

Dated 2026-11-16, plan 11-08. Requirement VER-03 (outstanding debt clause), roadmap success criterion SC5. Sources: [`11-DEBT-LEDGER.md`](11-DEBT-LEDGER.md) and [`11-DISCOVERIES.md`](11-DISCOVERIES.md). Read-only reconciliation by the executor of plan 11-08; no runner was involved and nothing here was run on a simulator or a device.

- **Ledger rows:** 88 rows in 12 sections, counted from the file: known non-green tests 7 (DL-T01 to DL-T07), D1 flash and crash 8 (DL-D01 to DL-D08), WINDOWS.md rows 12 (DL-W01 to DL-W12), open questions 14 (DL-Q01 to DL-Q14), pending todos 8 (DL-P01 to DL-P08), verification record states 3 (DL-V01 to DL-V03), Phase 10 residuals 4 (DL-R01 to DL-R04), project-level debt 2 (DL-H01, DL-H02), record-state contradictions 4 (DL-C01 to DL-C04), privacy manifest 1 (DL-M01), accessibility audit groups 9 (A11Y-AUDIT-G01 to G09), Phase 11 observations 16 (DL-O01 to DL-O16).
- **Audit allow-list entries:** 0. There is no allow-list: owner decision D11-22 superseded the allow-list contract, and the audit findings (385 reports, 311 byte-wise distinct keys, exploratory record corrected) are open, grouped in 9 ledger rows and not fixed.
- **Phase 11 observation rows:** 16 (DL-O01 to DL-O16), filled by plans 11-04, 11-05 and 11-07.
- **Discovery reconciliation:** 26 rows verified against their cited file; 0 rows flagged GAP; 8 rows flagged OPEN (outcome recorded, later verification or decision pending): C004, C005, C006, C013, the Device finding, D1, WR-04, and the privacy manifest and build date. Six Phase 11 new findings are listed (C014, C015, C016, OBS-A, OBS-B, OBS-C); five have owner D-09 briefs (`11-DECISION-C014.md`, `11-DECISION-C015.md`, `11-DECISION-C016.md`, `11-DECISION-OBS-A.md`, `11-DECISION-OBS-C.md`), all decisions pending, and OBS-B is an observation without a brief.
- **Phase 05 skipped checks:** reconciled in the discoveries document: 05-UAT test 4 is CHK-03 (pass, with a caveat), tests 5 and 6 are CHK-01 and CHK-02 (both open, reason CHK-00: the rotor Audio Graph action is not reachable on the simulator; requires a device).

Phase 11 lists these items and closes none. A ledger status changes only when the owner acts and evidence exists. One ledger row is stale against a later record: DL-W12 reads "open; owner decision pending" because it quotes `.planning/WINDOWS.md` row 12 as read on 2026-11-14 before plan 11-11; row 12 now reads fixed (resolved 2026-11-14T12:29:37Z by the D11-21 fix, see "Fix: iPad orientations (D11-21)"). The ledger row is a dated quotation and is not rewritten. The pending todo `2026-11-14-fix-accessibility-audit-findings.md` was added during the phase and is the fix tracker for A11Y-AUDIT-G01 to G09; the ledger todo rows DL-P01 to DL-P08 cover the 8 todos that existed at plan start.

**Record states of prior phases (listed, not rewritten; CONTEXT D11-01):** Phase 08 verification passed, read as written (DL-V01: 23/23, verified 2026-11-12). Phase 09 verification is gaps_found 12/14, written before plan 09-10, which closed the phase with D1 deferred (DL-V02). Phase 10 verification passed, read as written (DL-V03: 10/10, verified 2026-11-10). The phase verifier was not re-run for 08, 09 or 10: CONTEXT defers it. None of the three VERIFICATION files was edited.

**Record-state contradiction DL-C01:** `.planning/STATE.md` frontmatter reads current_phase 11, status executing, completed_phases 1 of 4, total_plans 10 and completed_plans 3, while ROADMAP.md marks every Phase 08, 09 and 10 plan checked and REQUIREMENTS.md marks the Phase 08, 09 and 10 requirements complete. The frontmatter is owned by the state tooling and is left untouched by this plan; the contradiction is recorded here, not rewritten. DL-C02 (the current-focus file still names the Phase 09 re-verification as the next step) is reconciled by plan 11-09. DL-H02 (the STATE.md blocker line that the accessibility audit is not yet started) is reconciled by this plan from the evidence above.

## File size and source guards

Dated 2026-11-14, plan 11-01 (extended by plans 11-05 and 11-09).

| Guard | Command | Result |
|-------|---------|--------|
| Source guard against the phase-start commit | `git diff --quiet 2aa9156 -- drinkpulse drinkpulse.xcodeproj` | exit 0 |
| Shipped-schema guard | `git diff --quiet fbd37fa -- drinkpulse/Domain/Persistence/Schemas drinkpulse/Domain/Persistence/MigrationPlan.swift` | exit 0 |
| File size | `find drinkpulse -name "*.swift" -not -path "*/Preview Content/*" \| xargs wc -l \| awk '$1 > 300 && $2 != "total" {print}'` | empty output |
| Source guard after the D11-21 fix | `git diff --stat 2aa9156 -- drinkpulse drinkpulse.xcodeproj` (plan 11-11) | expected non-empty: exactly one file, `drinkpulse/Info.plist`, 1 insertion (the owner-approved D11-21 change); the project file is unchanged |
| File size, re-run 2026-11-15 (plan 11-05) | same `find ... \| awk` command as above | empty output (no Swift file under `drinkpulse` over 300 lines) |
| New test file size, 2026-11-15 | `wc -l drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift` | 180 lines (limit 300) |
| Source guard, re-run 2026-11-15 | `git diff --quiet 2aa9156 -- drinkpulse drinkpulse.xcodeproj` | exit 1, as expected after the owner-approved D11-21 change: `git diff --name-only 2aa9156 -- drinkpulse drinkpulse.xcodeproj` lists exactly `drinkpulse/Info.plist` and `--numstat` reads 1 added, 0 removed; no other production or project file changed |
| Test-tree change since the phase start, 2026-11-15 | `git diff --name-status 2aa9156 HEAD -- drinkpulseUITests drinkpulseTests` | one line: `A drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift` (the only code file added in the phase) |
| Shipped-schema guard, re-run 2026-11-15 | `git diff --quiet fbd37fa -- drinkpulse/Domain/Persistence/Schemas drinkpulse/Domain/Persistence/MigrationPlan.swift` | exit 0 |
| Deployment target | every `IPHONEOS_DEPLOYMENT_TARGET` value in `drinkpulse.xcodeproj/project.pbxproj` | 8 values, all 27.0 |
| Final gate (a), 2026-11-16 (plan 11-09): paths changed since the phase start | `git diff --name-only 2aa9156`, then every path outside `.planning/`, `docs/`, `.claude/` and `README.md` | two paths: `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift` (the only code file added in the phase) and `drinkpulse/Info.plist` (the owner-approved D11-21 line, plan 11-11). The plan text expected the test file alone and predates D11-21; the second path is the known, approved change, not a new one. No other path changed |
| Final gate (b), 2026-11-16: source guard | `git diff --quiet 2aa9156 -- drinkpulse drinkpulse.xcodeproj` and `git diff --numstat 2aa9156 -- drinkpulse drinkpulse.xcodeproj` | exit 1, as expected after D11-21; `--numstat` reads one line, `1 0 drinkpulse/Info.plist` (one added line, `UIInterfaceOrientationPortraitUpsideDown`); the project file is unchanged |
| Final gate (b), 2026-11-16: shipped-schema guard | `git diff --quiet fbd37fa -- drinkpulse/Domain/Persistence/Schemas drinkpulse/Domain/Persistence/MigrationPlan.swift` | exit 0 |
| Final gate (b), 2026-11-16: deployment target | every `IPHONEOS_DEPLOYMENT_TARGET` value in `drinkpulse.xcodeproj/project.pbxproj` | 8 values, all 27.0 |
| Final gate (c), 2026-11-16: file size | `find drinkpulse -name "*.swift" -not -path "*/Preview Content/*" \| xargs wc -l \| awk '$1 > 300 && $2 != "total" {print}'` | empty output (no Swift file under `drinkpulse` over 300 lines); `AccessibilityAuditUITests.swift` 180 lines |
| Final gate (d), 2026-11-16: privacy scan | UUID-shaped string search over the 36 Phase 11 documents (`11-*.md` and `COVERAGE.md`) and over the 5285 lines added to `docs`, `README.md`, `.claude` and `.planning` since `2aa9156`; `git ls-files` filtered for `.log` and `.xcresult` | 0 hits in the documents, 0 in the added lines; no log or result bundle is tracked |
| Final gate (e), 2026-11-16: cloned simulator | `xcrun simctl list devices` filtered for the clone name `dp-phase11-a11y` | 0 matches (the clone was deleted in plan 11-07 and no device with that name remains) |
| Final gate (f), 2026-11-16: DEVLOG prefix | the `2aa9156` version of `docs/DEVLOG.md` compared with the start of the current file | byte-identical prefix; one entry appended (plan 11-09) |
| Final gate, 2026-11-16: protected records | `git diff --name-status --diff-filter=MD 2aa9156`, excluding the Phase 11 folder and the living documents | only `.planning/WINDOWS.md` (row 12 added and fixed by plans 11-01 and 11-11, with the counters and the tool-regenerated header note; no earlier row changed) and `drinkpulse/Info.plist` (D11-21). No existing todo and no Phase 08, 09 or 10 record was modified or deleted |

## Requirement outcome

Dated 2026-11-16, plan 11-08. Outcomes are derived from the recorded evidence by the rules in the plan, not by preference. The Outcome cell starts with one of `complete`, `complete with named exceptions`, `complete with named limitations`, `complete with open items` or `not complete`. All results are from the iOS 27.2 simulator (iPhone 18 Pro primary, iPhone 18 Pro Max secondary), not a device, except the two Release builds, which are compile and link only against the iphoneos 27.2 SDK.

| Requirement | Outcome | Basis (evidence section) | Exceptions, limitations and open items |
|-------------|---------|--------------------------|----------------------------------------|
| MOD-04 | complete | `## Zero-warning build (MOD-04)`: Debug (Xcode MCP) 0 gate-pattern warnings, Release iphoneos 27.2 (CLI) 0, second Release device build after the D11-21 fix 0; deprecation count 0 in every log; the `MOD-04 outcome` line reads app-owned deprecation warnings 0 | Rule applied: Debug and both Release rows show 0 Swift, linker and clang warnings and app-owned deprecation warnings 0. Remaining plain `warning:` lines are the external `appintentsmetadataprocessor` tool note (Debug 3, Release 1), no impact. The Release row for the iphonesimulator SDK was not run (owner runner policy D11-20); Release is verified on the iphoneos 27.2 SDK only (L-07). The iPad orientation validation notice was app-owned and is fixed by plan 11-11 (D11-21); WINDOWS.md row 12 reads fixed. |
| VER-01 | complete with named exceptions | `## Zero-warning build (MOD-04)` build rows (Debug and Release both succeeded); `## Full suite (VER-01)`: 834 tests, 816 passed, 0 failed, 18 skipped by gate, exit 0; `## Coverage`: overall 94.65 percent; `## Scoped runs (VER-02)` rows S1 and S2 (secondary destination) | Rule applied: both builds succeeded, no full-suite failure exists to map, overall coverage met 90 percent, rows S1 and S2 recorded with 0 failures. Named exceptions: (1) per-layer coverage: Domain coverage is 90.06 percent against the AGENTS.md Domain target of 100 percent, NOT met; recorded as debt in ledger rows DL-W01, DL-W07 and DL-Q14 and WINDOWS.md row 7, listed and not closed. Services 97.15 percent (target 85) and view models 98.11 percent (target 90) met. (2) Known-failure ledger rows as they occurred: DL-T02 and DL-T03 (the two History edit tests) failed in scoped row G3 and passed in the full run; DL-T01 and DL-T04 passed unexpectedly in both G4 and the full run; DL-T05 and DL-T06 (D1 harness tests) were Skipped by their gate in G1 and the full run, as expected; DL-T07 (watched) passed. (3) The 16 audit-class methods were Skipped by the `DP_RUN_A11Y_AUDIT` gate (D11-22), not a failure. Flake records: none; no new FLAKE-ID and no new todo. |
| VER-02 | complete with named limitations | `## Scoped runs (VER-02)` rows G1 to G4 and U1; `## Core flow proof (VER-02)`; `## Limitations` | Rule applied: every scoped-run failure maps to the known list (the two failures in row G3 are DL-T02 and DL-T03; no other failure occurred). Named limitations: L-01 backup import has no UI test (system file importer; unit suites and the historical Phase 10 device import round trip back it); L-02 edit coverage is partial and the data-integrity risk of the edit flow stays undetermined (DL-T02, DL-T03); L-03 the Phase 10 device proof of 2026-11-09 predates ten changed production files and is historical; L-04 UI tests run on an in-memory seeded store; L-09 interrupted migration and interrupted Health write remain acknowledged residuals (DL-R01, DL-R02). L-05 to L-08 (iOS 27.0 runtime not run, no device, Release compile and link only, Debug-only tests) also apply. |
| VER-03 | not complete | `## Accessibility (VER-03)` table and the checklist `11-A11Y-CHECKLIST.md`; `## Accessibility audit (exploratory run, D11-22)` | Rule applied: the audit class is not green and the checklist holds failed items, so VER-03 stays Pending and the requirement and traceability rows are not ticked. Blocking items: (1) CHK-05 fail, the Home overview card progress bar always animates with Reduce Motion on (ledger DL-O08, brief `11-DECISION-C014.md`); (2) CHK-06 fail, the History calendar detail area always animates when a day changes (DL-O09, brief `11-DECISION-C015.md`); (3) CHK-07 fail, truncated, clipped or overlapping text at AX5 on Home, Insights, Add Drink, Settings Preferences and Onboarding (DL-O10, brief `11-DECISION-C016.md`); (4) the automated audit: 16 methods red, 385 reports, 311 byte-wise distinct keys (exploratory record, corrected) under D11-22, 0 allow-list entries, ledger A11Y-AUDIT-G01 to G09, todo `2026-11-14-fix-accessibility-audit-findings`. Open items: CHK-00 (VoiceOver rotor not reachable on the simulator; DL-O04), CHK-01 and CHK-02 (both chart Audio Graphs, reason CHK-00; DL-O05, DL-O06), CHK-04 (Home arc covered by the sheet; DL-O07), CHK-10 (History row VoiceOver actions, reason CHK-00; DL-O11). Passed: CHK-03 (with a caveat, DL-O15), CHK-08, CHK-09. Owner observations: OBS-A (very large number read for an Insights chart point; DL-O12, brief `11-DECISION-OBS-A.md`), OBS-B (English and Polish speech mix; DL-O13), OBS-C (endless progress indicator in Settings without a profile; DL-O14, brief `11-DECISION-OBS-C.md`). All five owner briefs are decisions pending; Phase 11 makes no fix. |

### Roadmap success criteria

| SC | Criterion | Evidenced in | Status from the evidence |
|----|-----------|--------------|--------------------------|
| SC1 | App-owned deprecation warnings resolved without suppression; external warnings documented | `## Zero-warning build (MOD-04)` (build rows, Warning classification, MOD-04 outcome, Fix: iPad orientations, Build settings) | met: app-owned deprecation warnings 0; no suppression or warnings-as-errors setting in use; the one external tool note is classified |
| SC2 | Debug and Release builds and scoped then integrated suites pass; evidence records compiler, SDK, destination and limitations | the build rows; `## Scoped runs (VER-02)` (rows G1 to G4, U1, and secondary-destination rows S1 and S2); `## Full suite (VER-01)`; `## Toolchain and destination` (primary and secondary destinations); `## Limitations` | met with named exceptions: builds succeeded, full run 0 failures; Domain coverage 90.06 percent against its 100 percent target is not met and is listed as debt; the two History edit tests failed in the scoped run (known list) |
| SC3 | Core flows complete with existing data preserved | `## Core flow proof (VER-02)` and `## Limitations` | met with limitations: every flow has automated proof except the backup import UI flow (L-01); edit proof is partial (L-02); the device proof of data preservation is historical (L-03); UI tests use an in-memory store (L-04) |
| SC4 | VoiceOver chart Audio Graphs, Reduce Motion, Dynamic Type through AX5, light and dark, Increase Contrast recorded as passed or explicitly open; automated and human results distinguished | `## Accessibility (VER-03)` (separate Automated and Human columns) and `11-A11Y-CHECKLIST.md`; `## Accessibility audit (exploratory run, D11-22)` | recorded, not all passed: 3 pass, 3 fail (CHK-05, CHK-06, CHK-07), 5 open (CHK-00, CHK-01, CHK-02, CHK-04, CHK-10); the automated audit is red (385 reports, 311 byte-wise distinct keys, exploratory record corrected); human results are from a simulator, not a device |
| SC5 | Phase 05 skipped chart checks reconciled; unrelated debt not silently closed; all substantial discoveries have a recorded outcome | [`11-DISCOVERIES.md`](11-DISCOVERIES.md) (26 rows, 0 GAP, 8 OPEN) including its Phase 05 section (CHK-03 pass, CHK-01 and CHK-02 open); `## Debt ledger and discovery reconciliation`; [`11-DEBT-LEDGER.md`](11-DEBT-LEDGER.md) (88 rows) | met: Phase 11 lists these items and closes none; six new findings are recorded with owner briefs pending |

Inherited figures: the Phase 10 numbers (94.61 percent coverage, 214 events before and after, 678 unit tests in 59 suites, 93 UI tests) are quoted in this document only as Phase 10 historical figures dated 2026-11-09. The Phase 11 numbers replace them: 94.65 percent overall coverage, 714 Swift Testing tests in 62 suites plus 7 XCTest unit tests, and 113 UI tests (95 passed, 18 skipped by gate) in the full run of 2026-11-15. The Phase 10 device session figures remain historical and are not a Phase 11 result.
