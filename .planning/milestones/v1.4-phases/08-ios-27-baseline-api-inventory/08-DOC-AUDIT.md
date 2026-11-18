# Phase 08 Active Documentation Audit

**Audited:** 2026-09-16  
**Scope:** Present-tense setup, build, test, platform, and current-focus guidance discovered with `rg --files --hidden -g '*.md'` and targeted searches for platform, Xcode, simulator, and `xcodebuild` claims. Frozen ADRs, plans, DEVLOG entries, archived milestones, and past phase reports were inspected only to classify old-version text as history; they were not rewritten.

## Selected baseline

The durable source of truth is [08-BASELINE.md](08-BASELINE.md), backed by
[`08-BASELINE.json`](08-BASELINE.json). It records Xcode 27.0 (27A266a), Apple
Swift 6.4 (`swiftlang-6.4.0.34.1`), iOS 27.0 SDK/runtime, and Swift 6 language
mode (`SWIFT_VERSION = 6.0`) for the app, unit-test, and UI-test targets in
Debug and Release.

The captured simulator was iPhone 18 Pro, iOS 27.0, arm64,
`1D35E1B8-4141-4EFF-A493-52CB37B600A5`. Its UDID is machine-local; do not copy
it blindly to another Mac. Reselect a local destination, then substitute its
UDID into the documented `xcodebuild -destination` argument:

```bash
xcrun simctl list devices available | rg 'iPhone 18 Pro'
xcodebuild -project drinkpulse.xcodeproj -scheme drinkpulse \
  -destination 'platform=iOS Simulator,id=<LOCAL_IOS_27_UDID>' test
```

The evidence result is deliberately not green: dependency resolution passed,
while Debug build, Release build, and the unfiltered full suite failed with exit
65 before tests began because of the app-owned `DPArcProgress.swift:33`
actor-isolation compiler error. Test counts are unavailable, not zero or passing.

## Active entry-point dispositions

| File | Lines reviewed | Prior claim / finding | Disposition |
| --- | --- | --- | --- |
| `README.md` | 6, 116-133 | Already updated by Plan 01: iOS 27.0 minimum; Xcode 27/Swift 6.4; recorded iOS 27 simulator commands. | Retained as current guidance; it directs evidence reproduction to `08-BASELINE.md`. |
| `CLAUDE.md` | 9-10, 519-536 | Already updated by Plan 01: iOS 27.0 minimum and UDID-based Debug/full/scoped commands. | Retained as current guidance; exact baseline outcome and evidence remain in `08-BASELINE.md`. |
| `.planning/PROJECT.md` | 5-10, 151-164, 325-338 | Present-tense iOS 26 minimum and “existing deployment target remains iOS 26” conflicted with the settings matrix. | Updated to iOS 27, all target/configuration coverage, Xcode 27/Swift 6.4, Swift 6 language mode, and a durable baseline link. |
| `.claude/context/current-focus.md` | 1-49 | Stated Phase 07 was active/awaiting a new milestone and presented the iPhone 17 Pro result without active-baseline context. | Updated to active Phase 08, linked baseline evidence, and recorded the truthful failed build/test outcome. Phase 07 evidence is explicitly retained as dated history. |
| `docs/architecture.md` | 3-10, 86-92 | Omitted the present platform baseline; “on iOS 26” beside the Liquid Glass tab bar could be misread as the current minimum. | Updated with iOS 27 baseline/link; retained iOS 26 only as the historical introduction context. |
| `docs/domain.md` | 1-220 | No setup, build, test, simulator, Xcode, or deployment-target claim. | No change; active domain rules are unrelated to toolchain selection. |
| `.planning/ROADMAP.md` | 1-91 | Current Phase 08 goal and success criteria require iOS 27 documentation/evidence but contain no runnable command or stale selected destination. | No change; remains the active milestone scope, with `08-BASELINE.md` as its implementation evidence. |
| `.planning/REQUIREMENTS.md` | 1-67 | PLAT-02 requires the selected toolchain and living documentation to agree but contains no stale command. | No change; remains current requirements traceability. |
| `.planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md` | 1-47 | Primary evidence entry point. | Retained as the canonical toolchain, simulator, command, result, and raw-artifact reference. |
| `.claude/context/open-questions.md` | whole file | No setup/build/test/platform selection claim. | No change. |
| `.planning/todos/pending/2026-09-15-migrate-project-to-ios-27-and-modernize-codebase.md` | whole file | Originating request, not a developer setup guide. | Retained as dated task provenance; no command guidance. |

## Old-version text disposition

| Match | Location | Status and reason |
| --- | --- | --- |
| “iOS 26” deployment target | `.planning/PROJECT.md` historical v1.3/state notes | Retained only as dated milestone history. The present-tense product and constraint statements now say iOS 27. |
| “iOS 26” Liquid Glass tab-bar introduction | `docs/architecture.md` navigation section | Retained and explicitly labeled historical; it describes when that implementation was introduced, not the current minimum. |
| iPhone 17 Pro / 93 of 93 green result | `.claude/context/current-focus.md` historical Phase 07 paragraph | Retained and explicitly labeled Phase 07 historical verification, not the iOS 27 baseline. |
| iOS 26, older Xcode, and iPhone 17 Pro claims in `docs/DEVLOG.md`, `docs/plans/`, `docs/decisions/`, archived milestones, and earlier phase artifacts | Frozen historical records | Not rewritten under D-12/D-13. They are dated evidence, not active setup/build/test instructions. |
| iPhone 17 Pro command example in `08-PATTERNS.md` | Phase 08 planning-pattern snapshot | Retained as a pre-baseline planning excerpt; current commands in README/CLAUDE use the named iOS 27 baseline or a locally reselected UDID. |

## Audit conclusion

All active developer entry points now agree on iOS 27.0, Xcode 27.0, the Swift
6.4 compiler, and Swift 6 language mode. They link or defer to
`08-BASELINE.md` for exact commands and the non-passing captured result. No
active instruction selects an older Xcode, iOS 26 target, or iPhone 17 Pro as
the iOS 27 evidence environment.
