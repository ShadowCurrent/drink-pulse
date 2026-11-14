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
| Debug (iphonesimulator 27.2) | 2026-11-14 | `8e29a84` | Xcode MCP `BuildProject` (buildForTesting), Xcode DerivedData for this project removed first | built successfully, error list empty, `elapsedTime` 17.789 s | `** BUILD SUCCEEDED **` | 0 | 3 | 0 |
| Release (iphoneos 27.2) | 2026-11-14 | `8e29a84` | CLI `xcodebuild`; reason: the MCP `BuildProject` tool cannot select the Release configuration (named missing capability, owner-approved in D11-20) | exit 0 | `** BUILD SUCCEEDED **` | 0 | 2 | 0 |
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

## Full suite (VER-01)

Filled by plan 11-05.

## Coverage

Filled by plan 11-05.

## Core flow proof (VER-02)

Filled by plan 11-04.

## Accessibility (VER-03)

Filled by plans 11-03, 11-04, 11-07 and 11-10.

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
