---
phase: "08"
slug: "ios-27-baseline-api-inventory"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-16"
---

# Phase 08 — Validation Strategy

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | Swift Testing, XCTest, and XCUITest in Xcode 27 |
| Config file | `drinkpulse.xcodeproj/xcshareddata/xcschemes/drinkpulse.xcscheme` |
| Quick run | `xcodebuild -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -showBuildSettings -json` plus per-target effective-setting inspection |
| Full suite | `xcodebuild -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination 'platform=iOS Simulator,id=1D35E1B8-4141-4EFF-A493-52CB37B600A5' -resultBundlePath <outside-git-path>.xcresult test` |
| Estimated runtime | Full suite about 25 minutes; capture once for the baseline |

## Sampling Rate

- After deployment-setting edits, check effective iOS minimum and Swift language mode for app, unit tests, and UI tests in Debug and Release.
- Capture separate Debug and Release builds and one complete unit and UI suite run after target alignment.
- After each inventory batch, compare reviewed files and candidate locations with the source file list.
- Before phase verification, audit source citations, all no-candidate rows, diagnostic classifications, brief links, and raw-log hashes.
- Do not repeat the full suite solely for documentation edits; retain the original result and disclose its status.

## Per-Task Verification Map

| Requirement | Verification | Evidence |
|---|---|---|
| PLAT-01 | Six effective `IPHONEOS_DEPLOYMENT_TARGET` and `SWIFT_VERSION` settings | Recorded matrix and project diff |
| PLAT-02 | Debug and Release builds, full unit/UI suite, dependency resolution, active-doc audit | Result bundles, logs, counts, manifest, hashes |
| MOD-01 | File coverage matrix, exact candidate locations, official citations, explicit no-candidate rows | Dated inventory |
| MOD-05 | Every substantial candidate linked to a brief and owner outcome before downstream execution scope | Briefs and outcome ledger |

## Wave 0 Requirements

- Prepare an outside-Git evidence directory and a committed baseline manifest before long-running commands.
- Prepare an inventory coverage matrix and decision-brief template before the audit.
- Existing test infrastructure covers the phase; no new test framework is required.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|---|---|---|---|
| Candidate significance and disposition | MOD-01 | Requires official-source interpretation | Review every candidate against cited availability and current behavior. |
| Substantial rewrite scope | MOD-05 | Requires owner decision | Review each brief and record approve, retain, or defer with reason before Phase 09/10 scope is planned. |

## Validation Sign-Off

- [ ] All plans have automated checks or explicit human checkpoints where automation cannot establish the decision.
- [ ] Full baseline results and failures are reported without relabeling them as passing.
- [ ] No watch-mode flags; raw artifacts live outside Git and are linked by path and hash.
- [ ] `nyquist_compliant: true` is set only after execution evidence exists.

**Approval:** pending
