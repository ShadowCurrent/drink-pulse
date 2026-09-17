---
phase: 08-ios-27-baseline-api-inventory
reviewed: 2026-09-17T12:13:42Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - .claude/context/current-focus.md
  - CLAUDE.md
  - README.md
  - docs/architecture.md
  - drinkpulse.xcodeproj/project.pbxproj
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 08: Code Review Report

**Reviewed:** 2026-09-17T12:13:42Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The reviewed project settings are valid and all six target/configuration pairs resolve to iOS 27.0 and Swift 6.0. The documentation update leaves an authoritative persistence guide dangerously stale and publishes machine-specific simulator IDs as general developer commands.

## Narrative Findings (AI reviewer)

The findings below were verified against the current migration implementation, the captured baseline, and the resolved Xcode build settings.

## Critical Issues

### CR-01 [BLOCKER]: Persistence guide instructs an obsolete schema migration path

**File:** `docs/architecture.md:125-147`

**Issue:** The living architecture guide says the migration plan ends at `SchemaV3`, calls V3 the live shape, and directs the next divergence to freeze V3. The actual `MigrationPlan` includes `SchemaV4` and `v3ToV4`, while `SchemaV4` is the current live schema. Following the guide for the next stored-model change would make an engineer treat the already-frozen V3 snapshot as current instead of freezing V4 and adding V5, risking an incompatible schema hash and store recovery/data displacement.

**Fix:** Update this section to describe `schemas = [SchemaV1, SchemaV2, SchemaV3, SchemaV4]`, `stages = [v1ToV2, v2ToV3, v3ToV4]`, V1–V3 as frozen snapshots, and V4 as the live model shape. Change the next-divergence instruction to freeze V4 and introduce V5 with a new migration stage.

## Warnings

### WR-01 [WARNING]: General build instructions embed a capture-machine simulator UDID

**File:** `README.md:118-130`, `CLAUDE.md:426-429`, `CLAUDE.md:522-535`

**Issue:** Every runnable build, test, scoped-test, and coverage command uses the Phase 08 capture machine's fixed simulator UDID. That identifier only exists on the capture Mac; on another developer machine these copy-paste commands fail with an unavailable destination. The baseline documentation explicitly identifies the UDID as machine-local and requires local reselection, but neither public development instructions nor the agent instructions provide that step.

**Fix:** Keep the fixed UDID only in the immutable evidence record. Precede general commands with a local selection step, for example:

```bash
xcrun simctl list devices available | rg 'iPhone 18 Pro'
# Substitute the local iOS 27 simulator identifier below.
```

Use `<LOCAL_IOS_27_UDID>` in README/CLAUDE commands (or document an equivalent destination selector), and link to `08-BASELINE.md` for the exact captured command and result.

---

_Reviewed: 2026-09-17T12:13:42Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
