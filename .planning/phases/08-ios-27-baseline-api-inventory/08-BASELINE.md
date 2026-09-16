# Phase 08 iOS 27 baseline

Primary evidence was captured on 2026-09-16 under
`/Users/fempter/Library/Logs/DrinkPulse/phase-08-ios27/20260916T200000Z` with
Xcode 27.0 (27A266a), Apple Swift 6.4 (`swiftlang-6.4.0.34.1`), and the iOS
27.0 SDK. The selected destination was iPhone 18 Pro
(`1D35E1B8-4141-4EFF-A493-52CB37B600A5`), iOS 27.0 build 24A434, arm64. Swift
6.4 is the compiler version; all app and test configurations retain
`SWIFT_VERSION = 6.0`.

## Settings matrix

The manifest records all six target/configuration pairs: `drinkpulse`,
`drinkpulseTests`, and `drinkpulseUITests`, each in Debug and Release. Every
pair has deployment target `27.0` and Swift language mode `6.0`. The app
inherits its deployment setting from the project configuration; test targets
declare the same setting.

## Captured commands and truthful results

| Invocation | Result | External evidence |
| --- | --- | --- |
| `xcodebuild -resolvePackageDependencies` | **passed** (exit 0); no resolved source packages reported | `dependency-resolution.stdout.log`, `dependency-resolution.stderr.log` |
| Debug `xcodebuild … build` | **failed** (exit 65) | `debug-build.stdout.log`, `debug-build.stderr.log`, `debug-build.xcresult` |
| Release `xcodebuild … build` | **failed** (exit 65) | `release-build.stdout.log`, `release-build.stderr.log`, `release-build.xcresult` |
| Full Debug `xcodebuild … test` | **failed** (exit 65) | `full-test.stdout.log`, `full-test.stderr.log`, `full-test.xcresult` |

The full test command had no `-only-testing` or `-skip-testing` filter. The
shared scheme enables both `drinkpulseTests` and `drinkpulseUITests`; however,
compilation stopped before either target began. Total, passed, failed, skipped,
unit-test, and UI-test counts are therefore unavailable, not zero and not a
pass.

## Diagnostics and remediation

The Debug, Release, and full test runs all hit the same app-owned compiler
error: `drinkpulse/DesignSystem/DPArcProgress.swift:33` reports that `ArcShape`
conformance to `Shape` crosses into main-actor-isolated code and can cause data
races. `drinkpulse/Features/AddDrink/AddDrinkView.swift:5` also emits the
`@Entry` closure warning that the stored `dismissSheet` closure may invalidate
dependents because closures are not comparable. The compiler error makes all
three nonzero commands failures. Remediation is assigned to Phase 09; no failed
run is represented as passing.

## Evidence, hashes, and history

[08-BASELINE.json](08-BASELINE.json) gives the exact commands, exit codes,
relative raw-stream paths, SHA-256 values, result-bundle paths, and failure
classification. The supplied capture contains no persisted `xcresulttool`
result-summary JSON; each affected run records that artifact limitation while
retaining its raw `.xcresult` directory and complete hashed logs. The
dependency-resolution command produced neither bundle nor summary, and records
its artifact limitation separately.

The earlier `/private/tmp` sandbox/time-boxed Debug attempt is historical Task
1 evidence only. This document and the manifest consistently describe the
primary `20260916T200000Z` capture. Raw logs remain outside Git and this summary
contains no health values, signing secrets, or raw build output.

## Runtime-state limits

Phase 08 does not test an existing device store, change a VersionedSchema
snapshot, reset SwiftData, activate CloudKit, or change HealthKit or
notification semantics. Those behavior and existing-data checks remain for
later phases.
