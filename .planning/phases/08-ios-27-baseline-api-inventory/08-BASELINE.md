# Phase 08 iOS 27 baseline — Task 1 tracer

Captured 2026-09-16 with Xcode 27.0 (27A266a), Apple Swift 6.4
(`swiftlang-6.4.0.34.1`), and the iOS 27.0 SDK. Apple lists Xcode 27 as
requiring macOS Tahoe 26.6 or later and supplying a Swift 6.4 compiler with
Swift 6 language mode. The project deliberately remains in `SWIFT_VERSION =
6.0`; `6.4` identifies the compiler, not a language-mode setting.

The requested baseline destination was iPhone 18 Pro
(`1D35E1B8-4141-4EFF-A493-52CB37B600A5`) on iOS 27.0. It could not be
reselected: this sandbox's CoreSimulatorService was unavailable. The exact
probe and its full stderr are retained in the external artifact root.

## Settings matrix

All six app and test target/configuration entries resolve to deployment target
`27.0` and Swift language mode `6.0` in the manifest. The app inherits its
deployment setting from the project configuration; each test target declares
the same target/configuration setting. The target-level `xcodebuild
-showBuildSettings -json` captures for test targets encountered a sandbox PIF
cache access failure, so that failure is retained as evidence rather than
reported as an independent successful probe.

## Debug tracer result

The documented Debug command used `drinkpulse.xcodeproj`, the shared
`drinkpulse` scheme, Debug configuration, and the requested simulator UDID.
Its time-boxed execution exited **124** after 25 seconds because
CoreSimulatorService was unavailable; compilation and a completed `.xcresult`
never began. This is an environment-related baseline failure assigned to Phase
11, not a passing build. An earlier transport-interrupted attempt, including
its incomplete result-bundle directory, is preserved separately in the
manifest and was not replaced.

## Evidence and redaction

The committed manifest is [08-BASELINE.json](08-BASELINE.json). Every retained
raw stream is named by relative path and SHA-256 beneath its absolute
`artifact_root`. The intended location was
`~/Library/Logs/DrinkPulse/phase-08-ios27/<timestamp>`; sandbox permissions
denied its creation, so evidence was retained outside the worktree at the
permitted `/private/tmp/DrinkPulse-phase-08-ios27-20260916T194900Z` fallback.
Raw Xcode diagnostics can contain machine and signing information, so they are
not committed. This summary contains no health values, signing secrets, or raw
logs.

## Runtime-state limits

Phase 08 does not test an existing device store, change a VersionedSchema
snapshot, reset SwiftData, activate CloudKit, or change HealthKit or
notification semantics. Those behavior and existing-data checks remain for
later phases.
