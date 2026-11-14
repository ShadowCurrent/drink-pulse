# Phase 11 Evidence

Evidence for the iOS 27 release verification (MOD-04, VER-01, VER-02, VER-03). Capture started 2026-11-14 at base commit `4c04a25` (phase-start commit `2aa9156`; the working tree held no uncommitted change when capture began, `git status --short` empty). Xcode 27.2 (27B52), Apple Swift 6.4.2 (`swiftlang-6.4.2.1.9`), iphonesimulator 27.2 and iphoneos 27.2 SDKs. Primary destination: iPhone 18 Pro simulator, iOS 27.2 runtime build 24B8117. Raw logs stay outside git; every recorded log carries its SHA-256.

## Toolchain and destination

- **Xcode:** 27.2, build version 27B52 (`xcodebuild -version`). **Swift:** `Apple Swift version 6.4.2 (swiftlang-6.4.2.1.9 clang-2100.4.1.1)`, target `arm64-apple-macosx27.2.0` (`swift --version`); language mode `SWIFT_VERSION = 6.0` for the app and test targets. **SDKs:** `xcrun --sdk iphonesimulator --show-sdk-version` prints 27.2 and `xcrun --sdk iphoneos --show-sdk-version` prints 27.2. **Host:** `sw_vers` reports macOS ProductVersion 27.2.1, BuildVersion 26B131.
- **Destination (primary):** iPhone 18 Pro simulator on the iOS 27.2 runtime `com.apple.CoreSimulator.SimRuntime.iOS-27-2`, runtime build 24B8117 (`xcrun simctl list runtimes` prints `iOS 27.2 (27.2 - 24B8117)`). Exactly one device named "iPhone 18 Pro" exists under that runtime key; the `iOS-27-2-iPhone19-4` runtime (build 24B91016s) and the iOS 27.0 runtime were not used. The Xcode MCP active destination was the same device (Simulators group, osVersion 27.2). The simulator identifier is machine-specific and is deliberately not recorded; it is kept in the out-of-git `udid.txt` of the log directory.
- **Apple tooling route:** Xcode MCP first (workspace resolved at run time with `XcodeListWorkspaces`; the identifier is never written to a file). The CLI `xcodebuild` is used only for a named missing capability. In plan 11-01 the named missing capability is clean build and Release configuration: the MCP `BuildProject` tool accepts only `buildForTesting` and `workspaceIdentifier`, so it cannot run `clean` or select the Release configuration. Later plans name a further named missing capability, coverage collection, with its reason. Each evidence row records its runner and the reason.
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

Warning gate pattern, applied to the raw log of every build: `(\.swift:[0-9]+:[0-9]+: |ld: |clang: )warning:` (Swift, linker and clang diagnostics) plus a plain count of every `warning:` line and a deprecation count `warning:.*deprecat|deprecat.*warning`. A build counts only when its exit file and its success marker both exist; each build has its own derived-data path and its own out-of-git log; builds never ran concurrently.

### Build rows

| Row | Date | HEAD | Runner and reason | Exit | Success marker | Gate-pattern count | All `warning:` lines | Deprecation count |
|-----|------|------|-------------------|------|----------------|--------------------|----------------------|-------------------|
| Debug | 2026-11-14 | `4c04a25` | CLI `xcodebuild`; reason: clean build is not offered by the MCP BuildProject tool (named missing capability) | 0 | `** TEST BUILD SUCCEEDED **` | 0 | 3 | 0 |

**Debug command:** `xcodebuild clean build-for-testing -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=<udid from udid.txt>" -derivedDataPath build/p11-debug`, stdout and stderr to `debug-build.log`, exit status to `debug-build.exit`, both in the out-of-git stamp directory. It builds the app, `drinkpulseTests` and `drinkpulseUITests` for testing on the primary destination. Log: `debug-build.log` sha256 `41875845286689226c417dc53c67bf9c22ead7fe37abac5175398e526c63c718`. The name `dismissSheet` appears on 0 lines of the Debug log.

**Debug warning lines (3, all one class):** each is `appintentsmetadataprocessor ... warning: Metadata extraction skipped, no AppIntents.framework dependency found`. They are external tool notes (see the classification table below), not Swift, linker or clang diagnostics, and the gate pattern does not match them.

### Release builds (BLOCKED, owner decision pending)

The two clean Release builds (iphonesimulator 27.2 and iphoneos 27.2 SDKs) are not recorded. Both need a named missing capability of the Xcode MCP server (clean build and Release configuration; the MCP `BuildProject` tool accepts only `buildForTesting` and `workspaceIdentifier`). An owner override during execution forbids the CLI fallback for these steps, so they are open and the `MOD-04 outcome:` line is deliberately not written. No Release warning count, classification or digest exists in this document.

### MCP cross-check (Xcode MCP)

- **Runner:** Xcode MCP (`BuildProject` with `buildForTesting` true on the active destination, iPhone 18 Pro, iOS 27.2, then `GetBuildLog` with severity warning). **Result:** the project built successfully; the error list is empty; 0 warning entries returned (`totalFound` 0).
- **Limit:** this is an incremental, destination-specific success check (the build finished in a few seconds because little was recompiled) and is not warning evidence. Only the clean CLI rows above are warning evidence.
- **Saved result:** `mcp-build.result.txt` sha256 `83fcbcd0a1212879606dd5e020d236698ab0ed8010ea66ca111e7c7bea836f37` (the two tool results, saved verbatim minus the temporary log path).

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
| Deployment target | every `IPHONEOS_DEPLOYMENT_TARGET` value in `drinkpulse.xcodeproj/project.pbxproj` | 8 values, all 27.0 |

## Requirement outcome

Filled by plan 11-08.
