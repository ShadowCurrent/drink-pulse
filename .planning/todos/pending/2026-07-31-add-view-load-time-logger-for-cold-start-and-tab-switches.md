---
created: 2026-07-31T15:06:31.581Z
title: Add view-load-time logger for cold start and tab switches
area: general
severity: minor
files: []
---

## Problem

No visibility into how long individual views take to load when running the
app from Xcode on a physical device. Needed for two situations:
1. Cold start — time from launch to each top-level view appearing for the
   first time.
2. Every subsequent view load afterward, e.g. switching tabs in the main
   `TabView` — how long each destination view takes to become visible.

Right now there is no timing instrumentation at all, so regressions or slow
views can only be eyeballed, not measured.

## Solution

TBD — approach hints, not a locked design:
- Use `os.Logger` (`import OSLog`, subsystem `com.drinkpulse.app`, a
  dedicated category e.g. `performance`) per CLAUDE.md's logging rules — no
  `print(...)`, no PII/health-data values logged (only durations, view
  identifiers, counts).
- Likely hook points: `.onAppear`/`.task` on each top-level view (Dashboard,
  History, Insights, Settings) plus the `App`/root-scene cold-launch path
  (first frame after `ContainerLoadState` resolves) for the cold-start case.
  Tab switches are the same `.onAppear` hook firing again on an already-live
  view — same instrumentation should cover both cases if timestamps are
  captured relative to "tab selected" vs. "view body rendered."
- Consider `os_signpost` / `Signposter` (part of `OSLog`) in addition to plain
  `Logger` calls so Instruments' Points of Interest / os_signpost intervals
  can visualize load spans directly on a physical-device trace, not just text
  logs in Console.
- Should be easy to strip or gate (e.g. `#if DEBUG` or a launch-argument
  flag) since this is a dev-diagnostics feature, not a shipping feature —
  confirm with owner whether it should compile out of Release entirely.
- Whether this needs a plan (new dev-tooling capability) or is a quick task
  is TBD — decide when picked up.
