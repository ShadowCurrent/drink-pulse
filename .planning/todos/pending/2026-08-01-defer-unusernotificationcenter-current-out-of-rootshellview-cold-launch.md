---
created: 2026-08-01T12:52:26.114Z
title: Defer UNUserNotificationCenter.current() out of RootShellView cold-launch path
area: general
severity: major
files:
  - drinkpulse/Features/Shell/RootShellView.swift:18-19 (eager `let reminderService`/`let weeklySummaryService`)
  - drinkpulse/Services/ReminderService.swift:26-30 (`defaultCenter()` default-arg calls `.current()` eagerly)
  - drinkpulse/Services/WeeklySummaryService.swift:27-31 (same pattern)
  - drinkpulse/Diagnostics/ViewLoadLogger.swift (the instrumentation that surfaced this)
---

## Problem

Real-device cold launch (fresh Xcode install) measured via the new
`ViewLoadLogger` (quick task 260731-w4f):

```
Container load finished in 12 ms
View 'Dashboard' appeared in 3063 ms
```

Container/persistence load is fast (12ms, matches the already-closed
`slow-container-cold-start` debug session's finding of 9ms). The ~3-second
gap is entirely BETWEEN `containerState = .ready` and Dashboard's own
`.onAppear` — i.e. inside SwiftUI's view-construction/mount path, not in
container loading. This is new evidence the prior debug session never had
(it only instrumented `loadContainerIfNeeded()`, not the full path to first
view appear), so the previous "5-6s is external Xcode-Debug-install
overhead" conclusion for the DURATION component may have been measuring
the wrong thing — or this is a distinct, additional cause on top of it.

**Root cause (found by code read, corroborated by Apple Developer Forums
search):** `RootShellView.swift:18-19`:

```swift
private let reminderService = ReminderService()
private let weeklySummaryService = WeeklySummaryService()
```

Both are eager `let` stored properties, constructed synchronously the
moment `RootShellView` is built (i.e. before Dashboard's first frame can
appear). Both services' default init argument calls
`UNUserNotificationCenter.current()` (`ReminderService.defaultCenter()` /
`WeeklySummaryService.defaultCenter()`, evaluated eagerly since Swift
default arguments run at the call site). The first call to
`UNUserNotificationCenter.current()` in a process is a known, documented
main-thread blocker — it sets up an XPC connection to the `usernotificationsd`
daemon and can hang for a noticeable duration on real hardware. Confirmed
via Apple Developer Forums (thread 53390): "An app can hang randomly on app
launch after calling `UNUserNotificationCenter.current()`... the blocking
thread is identified with the topBlockingProcess as `usernotificationsd`."
Apple's own forum guidance: defer notification-center operations off the
launch path / off the main thread rather than calling them synchronously
during app launch.

This matches the measured 3063ms almost exactly and is consistent with the
earlier (much larger, 5-6s) real-device report in the closed debug session —
that session never isolated this because it had no per-view timing, only
container-load timing.

## Solution

TBD — approach sketch (not locked):

- `ReminderService` and `WeeklySummaryService` are only actually USED inside
  `RootShellView`'s `.onChange(of: scenePhase)` handler, already wrapped in
  `Task { await ... }` (async, not on the critical first-frame path). The
  fix should make the `UNUserNotificationCenter.current()` resolution happen
  lazily on first real use (inside that async `Task`), not eagerly at
  `RootShellView` construction time — e.g. store `center` as an optional
  resolved lazily inside each service, or move `reminderService`/
  `weeklySummaryService` construction into the async `.onChange(of:
  scenePhase)`/`.task` path instead of as eager `private let` view properties.
- Must preserve the existing DI/testability pattern (`NotificationScheduling`
  protocol injection for fakes in tests — do not regress `ReminderServiceTests`/
  `WeeklySummaryServiceTests` or whatever the current test files are called).
- Verify the fix actually works using `ViewLoadLogger`: re-measure
  "View 'Dashboard' appeared in N ms" on a real device after the change —
  should drop from ~3000ms to roughly the container-load figure (~10-50ms)
  plus normal SwiftUI mount time.
- Consider whether this fully explains the debug session's original 5-6s
  report or whether there's still a separate Xcode-Debug-install-overhead
  component on top — the closed debug session's conclusion about that
  external overhead may need revisiting once this fix lands and a fresh
  real-device measurement is taken.
- Touches Services layer (ReminderService, WeeklySummaryService) — CLAUDE.md
  requires ≥85% coverage there (happy path + error/denied paths through the
  injected protocol fake), so any restructuring needs matching test updates.

Size: moderate — touches 2 Services files + RootShellView wiring + tests;
likely `/gsd-quick`, not `/gsd-fast`.
</content>
