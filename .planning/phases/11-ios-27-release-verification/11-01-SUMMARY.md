---
phase: 11-ios-27-release-verification
plan: 01
subsystem: verification
tags: [xcode-mcp, xcodebuild, release-build, warning-inventory, evidence, ios27]

requires:
  - phase: 10-data-platform-integration-modernization
    provides: zero-warning gate pattern and evidence format
provides:
  - "11-EVIDENCE.md skeleton (twelve sections) with toolchain, toolchain-change table, Debug and Release build rows, warning classification and source guards"
  - "COVERAGE.md declaration for a verification-only phase"
  - "Finding: one open app-owned Release warning (iPad interface orientations validation notice)"
affects: [11-02, 11-04, 11-05, 11-08]

actuals:
  tokens: 14000
  tasks: 3
  commits: 4
plan_head_before: 4c04a2568d8d2c036d2f2e251ab2f0194ecf6e88
plan_head_after: f4ddc571149f38a141f69b9d28cba6f41a778cd4

tech-stack:
  added: []
  patterns:
    - "Runner policy D11-20: Xcode MCP for Debug, one approved CLI Release build"
    - "Raw logs out of git with SHA-256 digests in the evidence"

key-files:
  created:
    - .planning/phases/11-ios-27-release-verification/11-EVIDENCE.md
    - .planning/phases/11-ios-27-release-verification/COVERAGE.md
  modified: []

key-decisions:
  - "Release verified on the iphoneos 27.2 SDK only; the simulator SDK Release build is a stated limitation (D11-20)"
  - "The iPad orientation validation warning is recorded as an app-owned open finding, not fixed: a fix edits Info.plist or the project file, which this verification-only phase must not do"
  - "MOD-04 outcome line written in an honest extended form, not the plan's exact 'none' form"

requirements-completed: []

coverage:
  - id: D1
    description: "Full Xcode MCP Debug build-for-testing (DerivedData removed first) with 0 Swift, linker and clang warnings"
    requirement: MOD-04
    verification:
      - kind: other
        ref: "mcp-debug-build.log sha256 6d019bd4...a2fd; BuildProject built successfully; GetBuildLog totalFound 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "One clean Release device-SDK build with 0 Swift, linker and clang warnings and 0 deprecations"
    requirement: MOD-04
    verification:
      - kind: other
        ref: "release-device-build.log sha256 7076a947...c041; exit 0; ** BUILD SUCCEEDED **"
        status: pass
    human_judgment: false
  - id: D3
    description: "Release build is warning-free (zero warnings of any kind)"
    requirement: MOD-04
    verification:
      - kind: other
        ref: "release-device-build.log holds 1 app-owned validation warning (iPad interface orientations)"
        status: fail
    human_judgment: true
    rationale: "Owner must decide whether to fix Info.plist/project settings (new plan) or accept the notice; this phase may not edit production config."

duration: 90min
completed: 2026-11-14
status: complete
---

# Phase 11 Plan 01: Toolchain, Zero-Warning Builds and MOD-04 Outcome Summary

**Full Xcode MCP Debug build and one approved CLI Release device build record 0 Swift/linker/clang warnings and 0 deprecations, but the Release build surfaces one app-owned iPad interface-orientation validation warning that blocks an unqualified zero-warning claim.**

## Performance

- **Duration:** about 90 min across two executor sessions (checkpoint at the owner runner override D11-20)
- **Completed:** 2026-11-14
- **Tasks:** 3 of 3
- **Files modified:** 2 (both new, both under `.planning/`)

## Accomplishments

- `11-EVIDENCE.md` skeleton with the twelve required sections in order; toolchain (Xcode 27.2 27B52, Swift 6.4.2, SDK 27.2, iPhone 18 Pro iOS 27.2 build 24B8117) and toolchain-change table recorded, Phase 08 strings only in the historical column.
- Debug: full non-incremental Xcode MCP `BuildProject` (buildForTesting) after removing the project's DerivedData folders; app, unit-test and UI-test targets all compiled and linked; `GetBuildLog` severity warning returned 0 entries; the log holds 3 `appintentsmetadataprocessor` tool notes, 0 gate-pattern matches, 0 deprecations.
- Release: the single approved CLI build (`generic/platform=iOS`, `CODE_SIGNING_ALLOWED=NO`, iphoneos 27.2 SDK) exited 0 with `** BUILD SUCCEEDED **`, 0 gate-pattern matches, 0 deprecations, 2 plain `warning:` lines.
- Source guards pass: no production, project or shipped-schema change; deployment target 27.0 in all 8 project-file values; no file over 300 lines.

## Task Commits

1. **Task 1: Tracer (toolchain facts, Debug row, skeleton)** - `fb081d1` (docs)
2. **Task 3: MCP check, build settings, toolchain change, guards** - `c62f833` (docs)
3. **Task 2: Release build, MCP Debug row replacement, classification, MOD-04 outcome** - `f4ddc57` (docs)

`ee67fd1` (owner amendment D11-20 to CONTEXT) was committed by the orchestrator inside this plan's range and is counted in `commits: 4`.

## Files Created/Modified

- `.planning/phases/11-ios-27-release-verification/11-EVIDENCE.md` - phase evidence document; later plans fill the remaining sections.
- `.planning/phases/11-ios-27-release-verification/COVERAGE.md` - verification-only API coverage declaration.

## Decisions Made

- Release is verified on the iphoneos 27.2 SDK only. The simulator-SDK Release build is recorded as "not used (pre-override CLI run)" and listed as a limitation.
- The MOD-04 outcome line was extended rather than copied verbatim, because the plan's exact line ("externally blocked warnings: none; no source change made") would hide an app-owned warning.

## Deviations from Plan

### Owner-directed runner change (D11-20)

The plan assumed CLI `xcodebuild` for the clean Debug build, both Release builds and the evidence digests. Owner decision D11-20 restricted the CLI to one Release device build. Adaptations:

1. **Debug row** replaced with the Xcode MCP full build (DerivedData removed first); the earlier CLI Debug row and the incremental MCP check were removed as superseded (not evidence). Its digest and the `mcp-build.result.txt` digest were replaced by `mcp-debug-build.log` and `mcp-debug-build.result.txt` digests.
2. **Release simulator build** not run and not recorded; stated as a limitation.
3. **Verify scripts** were adapted minimally: no `debug-build.exit`, `release-sim-build.*` or `** TEST BUILD SUCCEEDED **` assertions; the digest check covers the three files that exist; the section-order check anchors on line-start `## ` headings (prose in the Consequences list mentions `## Limitations`, which broke the substring-based check). No file was faked.

### Auto-fixed Issues

None. No production or project file was edited.

### Plan stop rule applied (Task 2 step 5)

The Release build log contains an app-owned warning: `All interface orientations must be supported unless the app requires full screen.` It comes from `builtin-validationUtility -validate-for-store` (Release device build only). Cause: `drinkpulse/Info.plist` `UISupportedInterfaceOrientations~ipad` omits PortraitUpsideDown while `TARGETED_DEVICE_FAMILY = "1,2"`. Apple documentation (`UIViewController.supportedInterfaceOrientations`, via Xcode MCP `DocumentationSearch`) states that multitasking apps must support all orientations, that an app opts out with Requires full screen, and that enabling portraitUpsideDown for the iPad idiom is best practice. It is not a Swift, linker or clang diagnostic or a deprecation, so the plan's gate regex and deprecation count are 0, but the plain count and AGENTS.md "zero warnings" are not met. Not fixed here (verification-only phase, source guard).

## Issues Encountered

- `GetBuildLog` severity warning returned 0 entries while the raw log holds 3 tool-note `warning:` lines: the tool reports compiler issues, not tool console output. The evidence records both.
- `DocumentationSearch` found no Apple page for the `appintentsmetadataprocessor` note; recorded as such.

## Next Phase Readiness

Blocked decision for the owner before MOD-04 can be marked complete: fix the iPad orientation configuration in a new source-touching plan (add PortraitUpsideDown to the iPad orientations, or set Requires full screen, or drop iPad from the device family, each a product choice), or accept the notice with a recorded rationale. MOD-04 and VER-01 are NOT marked complete by this plan (`requirements-completed` is empty); plans 11-04, 11-05 and 11-08 consume the evidence file.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or schema change. The workspace identifier and simulator identifier stay out of the repository; no `.log` or `.xcresult` is tracked.

## Self-Check: PASSED

- `11-EVIDENCE.md`, `COVERAGE.md`: present.
- Commits `fb081d1`, `c62f833`, `f4ddc57`: ancestors of HEAD.
- Recorded digests equal `shasum -a 256` of `mcp-debug-build.log`, `mcp-debug-build.result.txt`, `release-device-build.log`.
- `git diff --quiet 2aa9156 -- drinkpulse drinkpulse.xcodeproj` exits 0; shipped-schema guard exits 0.
