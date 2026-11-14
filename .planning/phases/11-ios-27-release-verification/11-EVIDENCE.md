# Phase 11 Evidence

Evidence for the iOS 27 release verification (MOD-04, VER-01, VER-02, VER-03). Capture started 2026-11-14 at base commit `4c04a25` (phase-start commit `2aa9156`; the working tree held no uncommitted change when capture began, `git status --short` empty). Xcode 27.2 (27B52), Apple Swift 6.4.2 (`swiftlang-6.4.2.1.9`), iphonesimulator 27.2 and iphoneos 27.2 SDKs. Primary destination: iPhone 18 Pro simulator, iOS 27.2 runtime build 24B8117. Raw logs stay outside git; every recorded log carries its SHA-256.

## Toolchain and destination

- **Xcode:** 27.2, build version 27B52 (`xcodebuild -version`). **Swift:** `Apple Swift version 6.4.2 (swiftlang-6.4.2.1.9 clang-2100.4.1.1)`, target `arm64-apple-macosx27.2.0` (`swift --version`); language mode `SWIFT_VERSION = 6.0` for the app and test targets. **SDKs:** `xcrun --sdk iphonesimulator --show-sdk-version` prints 27.2 and `xcrun --sdk iphoneos --show-sdk-version` prints 27.2. **Host:** `sw_vers` reports macOS ProductVersion 27.2.1, BuildVersion 26B131.
- **Destination (primary):** iPhone 18 Pro simulator on the iOS 27.2 runtime `com.apple.CoreSimulator.SimRuntime.iOS-27-2`, runtime build 24B8117 (`xcrun simctl list runtimes` prints `iOS 27.2 (27.2 - 24B8117)`). Exactly one device named "iPhone 18 Pro" exists under that runtime key; the `iOS-27-2-iPhone19-4` runtime (build 24B91016s) and the iOS 27.0 runtime were not used. The Xcode MCP active destination was the same device (Simulators group, osVersion 27.2). The simulator identifier is machine-specific and is deliberately not recorded; it is kept in the out-of-git `udid.txt` of the log directory.
- **Apple tooling route:** Xcode MCP first (workspace resolved at run time with `XcodeListWorkspaces`; the identifier is never written to a file). The CLI `xcodebuild` is used only for a named missing capability. In plan 11-01 the named missing capability is clean build and Release configuration: the MCP `BuildProject` tool accepts only `buildForTesting` and `workspaceIdentifier`, so it cannot run `clean` or select the Release configuration. Later plans name a further named missing capability, coverage collection, with its reason. Each evidence row records its runner and the reason.
- **Official source for the command-line flags:** the Xcode 27.2 `xcodebuild -help` output (lists `-configuration NAME`, `-destination DESTINATIONSPECIFIER`, `-derivedDataPath PATH`, `-resultBundlePath PATH`, `-enableCodeCoverage YES|NO`) and the Xcode 27.2 `xcrun xcresulttool help` output (Xcode Result Bundle Tool version 25407), cited as tool output. Apple online documentation was not needed for these flags.
- **Log directory:** `~/Library/Logs/DrinkPulse/phase-11-ios27/<UTC stamp>/`, outside git. Derived-data paths are `build/p11-*` (gitignored).

## Toolchain change vs Phase 08

Filled by plan 11-01 Task 3.

## Zero-warning build (MOD-04)

Warning gate pattern, applied to the raw log of every build: `(\.swift:[0-9]+:[0-9]+: |ld: |clang: )warning:` (Swift, linker and clang diagnostics) plus a plain count of every `warning:` line and a deprecation count `warning:.*deprecat|deprecat.*warning`. A build counts only when its exit file and its success marker both exist; each build has its own derived-data path and its own out-of-git log; builds never ran concurrently.

### Build rows

| Row | Date | HEAD | Runner and reason | Exit | Success marker | Gate-pattern count | All `warning:` lines | Deprecation count |
|-----|------|------|-------------------|------|----------------|--------------------|----------------------|-------------------|
| Debug | 2026-11-14 | `4c04a25` | CLI `xcodebuild`; reason: clean build is not offered by the MCP BuildProject tool (named missing capability) | 0 | `** TEST BUILD SUCCEEDED **` | 0 | 3 | 0 |

**Debug command:** `xcodebuild clean build-for-testing -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=<udid from udid.txt>" -derivedDataPath build/p11-debug`, stdout and stderr to `debug-build.log`, exit status to `debug-build.exit`, both in the out-of-git stamp directory. It builds the app, `drinkpulseTests` and `drinkpulseUITests` for testing on the primary destination. Log: `debug-build.log` sha256 `41875845286689226c417dc53c67bf9c22ead7fe37abac5175398e526c63c718`. The name `dismissSheet` appears on 0 lines of the Debug log.

**Debug warning lines (3, all one class):** each is `appintentsmetadataprocessor ... warning: Metadata extraction skipped, no AppIntents.framework dependency found`. They are external tool notes (see the classification table below), not Swift, linker or clang diagnostics, and the gate pattern does not match them.

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

Filled by plan 11-01 Task 3, extended by plans 11-05 and 11-09.

## Requirement outcome

Filled by plan 11-08.
