# 0008 — Services layer for platform capabilities

**Status**: Accepted  
**Date**: 2026-06-26  
**Related**: [ADR-0004](0004-data-access-query-stateless-vm.md) (data access)

## Context

Until now the codebase had three layers: `Domain/` (models + pure-Swift
domain types), `Features/` (SwiftUI views + `@Observable` view models),
and `DesignSystem/`. Data access is covered by ADR-0004 (views read via
`@Query`, view models are stateless w.r.t. persistence).

Plan-0016 (log-reminder local notifications) needs to talk to
`UNUserNotificationCenter` — a platform/system capability that is neither
a domain value type, a view model, nor a SwiftUI view. Calling the
framework directly from a view or view model would:

- couple presentation/business logic to a framework singleton,
- make the logic untestable without triggering real authorization prompts
  and scheduling real notifications,
- violate Swift 6 strict-concurrency expectations (the centre is a global
  the test cannot stub).

ADR-0004 already anticipated this and pointed at "the services-layer ADR";
this records it.

## Decision

Introduce a **`Services/` layer**. A *service* is a stateless or
app-lifecycle-scoped type that mediates a platform/system capability
(notifications, Health, file IO, …), exposed through a **protocol** so
view models and views depend on the abstraction, not the framework.

```
View / ViewModel ──depends on──▶  protocol (e.g. NotificationScheduling)
                                        ▲                    ▲
                              real adapter (framework)   FakeXXX (tests)
                                        │
                              Service (@MainActor) orchestrates calls
```

**Rules:**

- The framework type is wrapped behind a narrow protocol that exposes only
  the operations the app uses. The real conformance is a **thin adapter**
  (e.g. `extension UNUserNotificationCenter: NotificationScheduling`).
- The service itself (`@MainActor final class`) takes the protocol via
  initializer injection, defaulting to the real adapter. It owns the
  orchestration logic (build request, idempotent reschedule, read settings)
  — the part worth testing.
- Tests inject a fake conforming to the protocol; **no real platform
  prompt, file, or scheduled item is ever produced in a test**.
- Services do **not** own a `ModelContext` and are **not** data access —
  reading/writing app data stays with `@Query` + `@Environment(\.modelContext)`
  per ADR-0004.
- New files live in `drinkpulse/Services/`. The first member is
  `ReminderService` (+ `NotificationScheduling`).

## Consequences

### Positive
- Framework singletons become unit-testable through an injected fake;
  service logic meets the ≥85% Services-layer coverage target without
  triggering system UI.
- Presentation and domain code depend on a small, stable protocol, not on
  `UserNotifications` directly.
- Clear home for future platform work (Health, widgets, watch glance).

### Negative / trade-offs
- One more layer and a protocol per capability — slight boilerplate. Justified
  by testability and isolation of framework coupling.
- The thin adapter (the framework conformance) is itself excluded from unit
  coverage as framework glue; correctness of the adapter is covered by the
  feature's UI test and manual verification.

### Alternatives considered
- **Call `UNUserNotificationCenter.current()` directly from the view** —
  rejected: untestable, couples UI to the framework, risks real prompts in
  tests.
- **Put notification logic in a view model** — rejected: view models are
  stateless w.r.t. side-effecting platform capabilities (ADR-0004); a
  scheduling singleton is not "computation over injected data".
</content>
