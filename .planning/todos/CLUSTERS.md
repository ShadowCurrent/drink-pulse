# Todo clusters

Decided 2026-07-27. Groups the pending todos into work units so they are not
picked up one-by-one as disconnected quick tasks.

The `cluster:` frontmatter field on each todo mirrors this file. This file is
the rationale; the frontmatter is the label.

---

## Cluster A — Swift 6 language mode + app-target structure

**Shape:** own milestone. Must not run in parallel with cluster B.

| Todo | Severity | Size |
|------|----------|------|
| `2026-07-26-migrate-app-target-to-swift-6-language-mode.md` | major | plan |
| `2026-07-27-harden-onboarding-dual-source-of-truth.md` | major | plan |
| `2026-07-27-async-model-container-startup-and-error-state.md` | minor | plan |

**Why its own milestone, alone:**

- The app target is on `SWIFT_VERSION = 5.0` (pbxproj:433, :468) while the
  test targets are on 6.0. CLAUDE.md's claim that "strict concurrency checking
  is on" is currently **false for production code**.
- Flipping the language mode surfaces data-race errors across SwiftData
  `@Model` isolation, `@MainActor` boundaries, and `Sendable` gaps in
  `Domain/`. The scope is not knowable until the first build after the flip.
- It touches the whole app target, so any other in-flight work will conflict.

**Ordering inside the cluster:** language-mode flip **first**, then the
onboarding gate, then async container. Making container creation async is
itself a concurrency change — doing it under Swift 5 rules means redoing the
isolation reasoning once the target flips. Do it once, under the rules that
will be enforced.

**What the three have in common:** all touch app startup and view identity —
what is authoritative before the store has settled. The onboarding gate
(`drinkpulseApp.swift:79`) and the container bootstrap
(`drinkpulseApp.swift:47`) are the same file and the same question.

**Two decisions to resolve during planning, before any code:**

1. What replaces the two `fatalError` calls at `drinkpulseApp.swift:59,68`.
   A store-open failure can put user data at risk; that error state is a
   design decision, not an implementation detail.
2. Which source of truth wins for onboarding — the persisted
   `onboardingDone` flag or the live `profiles` query. Today they disagree by
   construction, and the live one can win on a single empty render.

**Cross-cluster link:** `UserProfileStore.swift:30` inserts a `UserProfile`
without saving, and `RootShellView`'s `@Query profiles` observes it. That is
the intersection between the onboarding-gate todo here and the unclustered
insert audit — look at them together even though they are filed separately.

---

## Cluster B — Native feel: motion, layout, chart interaction

**Shape:** own milestone. Run before or well after cluster A, never during.

| Todo | Severity | Size |
|------|----------|------|
| `2026-07-26-scrub-insights-charts-for-per-point-values.md` | minor | own phase (feature) |
| `2026-07-26-animate-history-list-row-insert-delete.md` | cosmetic | small |
| `2026-07-26-slide-transition-between-history-list-and-calendar.md` | cosmetic | small |
| `2026-07-26-reserve-vsprev-row-height-in-insights-all-time.md` | cosmetic | small |
| `2026-07-27-no-entrance-animation-on-first-render.md` | cosmetic | small |
| `2026-07-27-branded-static-launch-screen.md` | minor | small |

**Why grouped rather than six separate quick tasks:**

- **Shared infrastructure.** Every user-facing item here needs a
  `drinkpulseUITests` test (CLAUDE.md gate) and the `reduceMotion` pattern
  from `Features/Onboarding/OnboardingView.swift:80`. Six separate quick
  tasks means standing that scaffolding up six times.
- **Real cross-dependency.** The slide-transition todo explicitly states:
  *"if both are picked up together, keep the animation curves consistent"*
  (referring to the History row-diff todo). Done separately, the app ends up
  with several unrelated easings.
- **One product-visible outcome.** Together they read as "the app finally
  feels native"; separately they are individually invisible.

**Not polish — a feature.** `scrub-insights-charts` is a new interaction
(`chartXSelection`, callout annotation, `accessibilityChartDescriptor`, plus a
decision on whether the hero card follows the selection). It gets its own
phase inside this milestone, not a task slot.

---

## Unclustered

| Todo | Severity | Route |
|------|----------|-------|
| `2026-07-27-audit-context-insert-call-sites-for-missing-save.md` | minor | `/gsd-quick` (audit first) |
| `2026-07-26-rename-app-display-name-to-drinkpulse.md` | cosmetic | `/gsd-quick` |

**Insert audit** — unclustered because its outcome is unknown. It follows up
the `sheet-closes-reopens-loses-state` fix: that session only grepped the
insert sites, it did not audit them. A 2026-07-27 survey found that no
production insert site except the fixed one calls `save()`, but
insert-without-save is only a defect when the object's identity can reach a
SwiftUI presentation before the save — so this is an audit for that
combination, not a sweep. If it finds real matches, triage them then (likely
into cluster A, since `UserProfileStore` is already implicated there).

**Rename** — isolated, shares no infrastructure with either cluster. If the
`INFOPLIST_KEY_CFBundleDisplayName` option is chosen it is effectively one
build-settings line. A full Xcode target rename is a different, riskier task
(care needed around `PRODUCT_BUNDLE_IDENTIFIER` so TestFlight/App Store do not
see a new app) — that scope decision is still open.

---

## Note on sizes

None of these are `/gsd-fast` material. Every user-facing item carries the
CLAUDE.md UI-test requirement, which puts a floor under the smallest possible
task here.

## History

- 2026-07-27 — added two todos carried over from the closed
  `sheet-closes-reopens-loses-state` debug session: the `RootShellView`
  onboarding dual-source-of-truth hardening (→ cluster A, `major`) and the
  `context.insert` missing-save audit (→ unclustered, `minor`). Both were
  investigated during that session, neither was the cause of the bug that was
  fixed, and both were explicitly left open rather than dropped.
- 2026-07-27 — clusters defined. Split
  `2026-07-26-branded-launch-state-and-no-zero-animation-on-first-render.md`
  into three todos (branded static launch screen → B, async container +
  error state → A, no entrance animation → B); the original bundled three
  items of three different sizes and was removed.
