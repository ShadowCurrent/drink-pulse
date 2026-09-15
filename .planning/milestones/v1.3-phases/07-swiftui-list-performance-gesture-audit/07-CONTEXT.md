# Phase 7: SwiftUI List Performance & Gesture Audit - Context

**Gathered:** 2026-08-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Read-only audit of every SwiftUI view in this repo that contains a `List`, plus the SwiftData
models and `@Query` declarations feeding those views. Produce a findings report (severity-ranked,
file:line, concrete fix) and a PLAN.md for a follow-up execution phase. **No code changes happen
in this phase** — research and planning only. The plan requires explicit user approval before any
`/gsd-execute-phase` run against it.

</domain>

<decisions>
## Implementation Decisions

### Scope: what to audit
- Every SwiftUI view containing a `List` (not `ScrollView`/`LazyVStack` — those are out of scope
  unless a finding specifically recommends converting a `List` to one, or vice versa).
- Every SwiftData model and `@Query` declaration that feeds a `List`-containing view.
- Report format: grouped A (List performance) / B (sections) / C (gestures), each finding as
  `file:line` + severity (`blocker` / `worth-fixing` / `nit`) + the concrete fix. Do not fix
  anything yet — findings only in this phase.

### A. List performance — exact checks required
- **A1 Identity:** every `ForEach` keyed by a stable `Identifiable` ID? Flag `id: \.self` on
  mutable values and any use of `.indices` or `.enumerated()` as the identity source.
- **A2 Dynamic subview count:** any `ForEach` leaf whose body conditionally returns zero-or-one
  subviews, or unwraps an optional inline. Report each; propose moving the condition into a
  `#Predicate` on the `@Query`.
- **A3 `@Query` audit:** filters expressed as predicates, or applied in `body`/a computed property
  after fetching? Is the sort attribute covered by `#Index` on the model? Any view fetching the
  whole table where a bounded range would do?
- **A4 Row body cost:** formatters (`DateFormatter`, `NumberFormatter`, `MeasurementFormatter`)
  constructed inline, unit conversions, aggregations, sums over relationships, or any Swift Charts
  view rendered per row — all should move to `init` or a precomputed view model.
- **A5 `onAppear` misuse:** row setup in `onAppear` that mutates the row's size or content — that
  work belongs in the initializer; `onAppear` stays for genuinely appearance-bound work like
  paging.
- **A6 Invalidation:** `AnyView` in row hierarchies, `.id()` forcing rebuilds, `GeometryReader`
  inside rows, fast-changing values passed through `@Environment`.
- **A7 Extraction:** rows whose body is inlined in the parent instead of being its own `View`
  type — note where extracting one buys an independent invalidation boundary.

### B. Sections — exact checks required
- **B8:** how are sections built? Flag any `Dictionary(grouping:)` or sort running inside `body`
  on every render; propose computing it once.
- **B9 Header/footer consistency:** `listStyle`, pinned headers, `listRowInsets` /
  `listRowSeparator` / `listRowBackground` applied per-row where a single container-level modifier
  would do.
- **B10 Empty/loading states:** is `ContentUnavailableView` placed above the `List`, or leaking
  into partially-resolved rows?

### C. Gestures — exact checks required
- **C11 Inventory:** every gesture attached to rows or the `List` — `swipeActions`, `contextMenu`,
  `longPressGesture`, `onTapGesture`, `onMove`, drag/drop, `simultaneousGesture`,
  `highPriorityGesture`. Deliver as one table: gesture, where, what it does.
- **C12 Conflicts:** any custom gesture that can swallow the scroll or fight the swipe recognizer.
  Flag `longPressGesture` where `contextMenu` would be idiomatic, and `onTapGesture` on a row that
  also has a `NavigationLink` or `Button`.
- **C13 `swipeActions` review:** edge, `allowsFullSwipe`, and whether destructive actions carry
  `role: .destructive` and a confirmation path.
- **C14 Accessibility:** does every swipe/long-press action have an equivalent
  `accessibilityAction`? Are hit targets >= 44pt, does the row survive the largest Dynamic Type
  sizes (project rule: test up to AX5, per CLAUDE.md Accessibility section)?

### Deliverable shape
- Findings report (A/B/C grouped, ranked by impact) as `RESEARCH.md`.
- A `gsd-planner` PLAN.md whose `verification_criteria` are expressed as `xcodebuild test` cases
  or other measurable/automatable checks — not subjective language, per this project's own
  planner `<deep_work_rules>` contract (already enforced by `gsd-planner`/`gsd-plan-checker`).
- Anything that would require iOS 27 APIs to fix must be listed **separately**, under a "Later
  (needs iOS 27)" heading — do not raise the deployment target (CLAUDE.md: min deployment is
  iOS 26, non-negotiable) and do not fold iOS-27-only fixes into the actionable plan.

### Model / effort
- Research, planning, and plan-verification (plan-checker) phases of this cycle run on Opus 5
  (`model_overrides.gsd-phase-researcher` / `gsd-planner` / `gsd-plan-checker` set to `opus` for
  this cycle — orchestrator responsibility, not a planner/researcher concern).

### Claude's Discretion
- Exact severity thresholds between `blocker` / `worth-fixing` / `nit` for borderline findings.
- Whether to propose one combined follow-up phase or split into multiple phases if the finding
  count is large enough to blow the planner's context budget (the planner may return
  `## PHASE SPLIT RECOMMENDED` — that is expected and should be handled per the standard
  plan-phase workflow, not treated as a failure).
- UI-SPEC.md is NOT required for this phase — it is a read-only audit + fix-plan, not new UI
  design work. Skip the UI design-contract gate if it triggers.

</decisions>

<specifics>
## Specific Ideas

No specific visual/product references — this is a code-quality/performance audit, not a design
task. The 18 numbered checks under A/B/C above are the literal, complete spec; do not add checks
beyond them, and do not drop any of them.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before researching or planning.**

### Project conventions that bound every finding/fix
- `CLAUDE.md` §"Domain model (canonical)" — `DrinkTemplate`/`ConsumptionEvent`/`UserProfile` are
  the SwiftData `@Model` types most `List`s in this app will be querying; grams-of-pure-alcohol is
  the unit of truth, never store/derive in a row body.
- `CLAUDE.md` §"Architecture" — views query SwiftData directly via `@Query`; view models are
  `@Observable @MainActor` and stateless w.r.t. persistence (no repository layer). Any proposed
  fix must respect this — e.g. moving filtering into a `#Predicate` on `@Query`, not into a
  repository method that doesn't exist in this codebase.
- `CLAUDE.md` §"Accessibility (required, not optional)" — every interactive element needs a
  meaningful `accessibilityLabel`; Dynamic Type up to AX5; `reduceMotion` honored; contrast ratios.
  This directly bounds C14's findings.
- `CLAUDE.md` §"Conventions" — Swift 6 strict concurrency, no force-unwraps, 300-line file ceiling
  (a proposed fix that requires extracting a row into its own file, per A7, should say so).
- `CLAUDE.md` §"Testing (mandatory)" — 90% coverage target, UI tests mandatory for user-facing
  behavior changes; `verification_criteria` in the plan should lean on `xcodebuild test
  -only-testing:` scoped runs per the project's own documented default.
- `CLAUDE.md` §"Out of scope" / min deployment iOS 26 — any C13 `swipeActionsContainer()`-style
  fix that needs iOS 27 must be filed under "Later", never implemented now.

### Directly relevant recent history (same-day, same area — read before researching History's `List`)
- `.planning/debug/resolved/history-scrollview-bugs.md` — History's list was briefly migrated
  `List` → `ScrollView`+`LazyVStack` (plan-0038) to fix a confirmed row/contextMenu eager-eval cold
  start hitch, then reverted back to `List` (commit `3093b02`, same day) after the ScrollView path
  caused an unfixable Liquid Glass context-menu rendering glitch. **`HistoryListQueryView.swift`
  is a `List` again as of this phase's kickoff** — audit it as `List`, not `ScrollView`.
- `.planning/debug/resolved/contextmenu-zoom-glitch.md` — contains real, doc-cited research
  (Apple FB11280425: a `ForEach`-generating-`Section`s-with-nested-inner-`ForEach` structure
  defeats `List`'s laziness) directly relevant to A1/A2/A7/C11/C12 for `HistoryListQueryView.swift`
  specifically. Read this before re-deriving the same finding from scratch.
- `docs/plans/0038-history-list-lazy-scrollview/plan.md` — **STALE**: frozen `in-progress` plan
  still describes the List→ScrollView direction as current; the code has since reverted. Flag this
  discrepancy in RESEARCH.md if `HistoryListQueryView.swift` findings would otherwise contradict
  the frozen plan — do not silently plan around a doc that no longer matches shipped code.

### No other external specs
No ADRs or design docs constrain this phase's scope beyond the above — the 18-point A/B/C
checklist in `<decisions>` is the full requirements surface.

</canonical_refs>

<code_context>
## Existing Code Insights

### Known `List`-containing views (starting point — audit must verify this list is exhaustive)
- `drinkpulse/Features/History/HistoryListQueryView.swift` — `List { ForEach(dayGroups) {
  HistoryDaySectionCard } }`, feeds from `@Query` on `ConsumptionEvent` filtered by
  `consumptionDate >= windowStart`; `HistoryDaySectionCard` (`Components/`) renders one `List` row
  per day, internally `ForEach`-ing `events` with its own nested rows + `.eventContextMenu`.
  Directly relevant to A1/A2/A7/B8/C11/C12 per the debug-session findings above.
- Other `List` usages (Settings, onboarding, calendar day-detail, template pickers, etc.) are NOT
  yet inventoried — the researcher's first job is a repo-wide `grep`/`Glob` sweep for `List(` and
  `List {` to build the complete file inventory before applying the 18-point checklist to each.

### Established patterns relevant to fixes
- `HistoryDaySectionCard` (plan-0027-style `dpGlassCard` component) is the app's established
  "list section as a styled card" pattern — any B8/B9 fix proposal should stay consistent with it
  rather than inventing a new section styling approach.
- `.eventContextMenu` (`Features/History/Components/EventContextMenu.swift`) is the established
  gesture-modifier extraction pattern (a `View` extension wrapping `.contextMenu`) — C11/C12
  findings elsewhere in the app should be checked against whether they follow or diverge from this
  pattern.

</code_context>

<deferred>
## Deferred Ideas

- Actually implementing any fix — explicitly out of scope for this phase; belongs in the
  follow-up execution phase this plan proposes, pending user approval.
- Reconciling `docs/plans/0038-history-list-lazy-scrollview/`'s stale frozen plan.md against the
  List revert (belongs to whoever formally closes out plan-0038 — flag it, don't fix it here).

</deferred>

---

*Phase: 07-swiftui-list-performance-gesture-audit*
*Context gathered: 2026-08-03*
