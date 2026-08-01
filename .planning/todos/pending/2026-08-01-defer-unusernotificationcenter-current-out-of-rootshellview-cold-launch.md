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

## Update 2026-08-01 (post-fix real-device re-measurement — root cause revised)

Quick task 260801-l5j shipped the `ReminderService`/`WeeklySummaryService` lazy-`center`
fix described above (commits `64a0a29`, `1b54cd9`, `3d84bab`). Real-device re-measurement
after that fix: **`View 'Dashboard' appeared in 5007 ms`**, then a second run: **`5199 ms`**
— no improvement, if anything slightly worse (within noise, but certainly not the expected
drop to ~10-50ms).

A second candidate was found and fixed inline (not yet a separate todo/plan — small,
same-session follow-up): `drinkpulseApp.swift:53`'s `init()` called
`UNUserNotificationCenter.current().delegate = notificationHandler` directly and
synchronously — an earlier, more direct hit on the same documented XPC-blocking call than
the RootShellView eager-`let` pattern, and outside this todo's original file list entirely.
Fixed by resolving `.current()` off the main thread via `Task.detached` (delegate
assignment itself hops back to `MainActor.run`, since `NotificationActionHandler`'s
`UNUserNotificationCenterDelegate` conformance is MainActor-isolated under this module's
default isolation); `NotificationActionHandler` marked `@unchecked Sendable` to support the
cross-actor capture (documented: zero stored properties, thread-safe method bodies).
**Real-device re-measurement after this second fix: still ~5000ms range — no improvement.**

**This citation in the "Root cause" section above is wrong and should not be trusted**:
Apple Developer Forums thread 53390, cited as "An app can hang randomly on app launch after
calling `UNUserNotificationCenter.current()`..." — verified by fetching the actual thread
content: it is an unrelated 2016 watchOS notification-delivery bug (notifications only
firing once per reboot), contains no mention of app-launch blocking, and has no Apple
engineer response. The citation does not support the claim it was attached to. (The
underlying claim — that `UNUserNotificationCenter.current()`'s first call in a process can
block main-thread-adjacent work via XPC setup to `usernotificationsd` — is still plausible
in principle and is documented elsewhere on the forums, e.g. thread 67939 and others found
in the 2026-08-01 re-research below; it just isn't proven by thread 53390, and empirically,
fixing both call sites moved the measured number by ~0%.)

**New leading hypothesis, found via `WebSearch`/`WebFetch` against
developer.apple.com/forums on 2026-08-01**: [Xcode 26 debugger-attached app-launch
overhead](https://developer.apple.com/forums/thread/800067) — a documented, severe
regression matching this project's exact target (iOS 26 / Xcode 26). Per an Apple DTS
engineer (Ed Ford) on that thread: each dylib load costs ~0.10-0.15s with the debugger
attached under Xcode 26.x vs ~0.02-0.03s under Xcode 16.4 — 200 dylibs → ~30s vs ~4s. A
modern SwiftUI + SwiftData + HealthKit + UserNotifications app easily has 50-150 dylibs, so
this alone plausibly accounts for multiple seconds of "gap," entirely unrelated to any app
code path. Confirmed workaround on that thread: Xcode Scheme → Run → uncheck "Debug
Executable" → launch time drops to <1s. Partial official fix landed in Xcode 26.2 beta 2+
(server + client component); thread indicates the issue was still not fully resolved as of
April 2026.

This is also consistent with — and now looks like a correction to — the original
`slow-container-cold-start` debug session's dismissed conclusion that the 5-6s figure was
"external Xcode-Debug-install overhead." This todo's Problem section (line ~29-31) called
that conclusion into question based on the ViewLoadLogger evidence that the gap sits between
`containerState = .ready` and Dashboard's `.onAppear` — that framing is still accurate (the
gap IS in that window), but "which external-to-our-code mechanism eats that window" now
looks like the debugger-attach dylib overhead, not (or not only) `UNUserNotificationCenter`.

**Verification requested, not yet performed**: relaunch the app with "Debug Executable"
unchecked in the scheme (or install + launch directly from the home-screen icon, fully
detached from Xcode/LLDB) and re-check the `ViewLoadLogger` "Dashboard appeared" number. If
it drops to roughly the container-load figure, this confirms the debugger-attach hypothesis
and this todo should close as "not an app-code bug" (the two service-layer/notification-
delegate fixes already shipped are still worth keeping — legitimate defensive improvements,
just not the dominant cause of the measured number).

A third, still-unverified candidate was also instrumented (not yet measured): `drinkpulseApp.swift`'s
`RootShellView().onAppear { RecordDeduplicator.sweep(in: container.mainContext) }` — a
synchronous, unbatched `context.fetch(FetchDescriptor<T>())` over every `ConsumptionEvent`/
`DrinkTemplate` row, MainActor, directly on this path. Diagnostic timing log added around it
(`RecordDeduplicator.sweep finished in N ms`, `startupLog`) — not yet confirmed as
significant or negligible pending a real-device run with the debugger-detached test above.
</content>
