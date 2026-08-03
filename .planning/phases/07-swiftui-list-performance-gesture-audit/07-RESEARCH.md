# Phase 7: SwiftUI List Performance & Gesture Audit — Research

**Researched:** 2026-08-03
**Domain:** SwiftUI `List` performance, SwiftData `@Query` shaping, gesture/accessibility semantics (iOS 26)
**Confidence:** HIGH for the inventory and code-level findings (all read first-hand this session); MEDIUM for framework-mechanism attributions (Apple doc pages could not be fetched directly — see Sources); LOW for the two items in the Assumptions Log.
**Mode:** READ-ONLY AUDIT. No source file was modified.

---

## Summary

A repo-wide sweep found **three production SwiftUI views containing a `List`** (plus one preview-only `List`) — materially fewer than the CONTEXT's starting point implied, and the two non-History ones (`GuidelinePickerSheet`, `GuidelineStep`) are near-duplicates of each other. Applying all 18 checks produced **31 findings: 2 blockers, 14 worth-fixing, 15 nits**, plus one item deferred to "Later (needs iOS 27)".

The History list is in good structural shape. The `List { ForEach(dayGroups) { HistoryDaySectionCard } }` arrangement that landed via the `contextmenu-zoom-glitch` re-scope is genuinely the correct, lazy, unary-row shape, and it correctly avoids the `ForEach`-generating-`Section`s defect the debug session identified. The remaining A-group cost is not structural — it is **per-row work done twice** (`EventRow` formats every string once for display and again for its accessibility label) and **per-body-pass work that should be per-data-change** (`groupedByDay` runs a `Dictionary(grouping:)` plus two sorts inside `body`).

The two genuine blockers are not performance issues at all. **A1-1**: every History row is keyed by SwiftData's `PersistentIdentifier`, which is documented to change when a freshly-inserted object is saved — this repo has already burned one debug session (`sheet-closes-reopens-loses-state`) on an adjacent symptom of that exact mechanism, and the model carries a purpose-built stable `uuid` (plan-0023) that is going unused. **C13-1**: the context-menu Delete destroys a logged health record with no confirmation and no undo, while the *other* delete path in the same feature (the Edit sheet's trash button) has a confirmation popover pinned by a dedicated UI test. Same operation, same data, two different safety levels — the easier path is the unguarded one.

Two documentation discrepancies surfaced and are flagged rather than fixed (per CONTEXT `<deferred>`): `docs/plans/0038-*/plan.md` is stale, and `.planning/debug/resolved/history-scrollview-bugs.md` is archived as *resolved* describing a fix (`onScrollVisibilityChange`) that no longer exists in the code.

**Primary recommendation:** Fix the two blockers first (both are small, self-contained, and independently testable). Then take the A7 extraction findings, because a single shared `EventRowButton` component simultaneously resolves A7-1, C12-1, C14-1, and C14-2 — and a single shared `GuidelineChoiceRow` resolves A7-2, A1-2, and C14-4. Extraction is the highest-leverage move in this audit. Treat A3-1 (`#Index`) as a separate, gated work item: it is a real fetch-path win but it changes the SwiftData schema and therefore requires a new `SchemaV5` + `MigrationStage` under CLAUDE.md's non-negotiable rule.

---

<user_constraints>
## User Constraints (from 07-CONTEXT.md)

### Locked Decisions

**Scope: what to audit**
- Every SwiftUI view containing a `List` (not `ScrollView`/`LazyVStack` — those are out of scope unless a finding specifically recommends converting a `List` to one, or vice versa).
- Every SwiftData model and `@Query` declaration that feeds a `List`-containing view.
- Report format: grouped A (List performance) / B (sections) / C (gestures), each finding as `file:line` + severity (`blocker` / `worth-fixing` / `nit`) + the concrete fix. Do not fix anything yet — findings only in this phase.

**A. List performance — exact checks required**
- **A1 Identity:** every `ForEach` keyed by a stable `Identifiable` ID? Flag `id: \.self` on mutable values and any use of `.indices` or `.enumerated()` as the identity source.
- **A2 Dynamic subview count:** any `ForEach` leaf whose body conditionally returns zero-or-one subviews, or unwraps an optional inline. Report each; propose moving the condition into a `#Predicate` on the `@Query`.
- **A3 `@Query` audit:** filters expressed as predicates, or applied in `body`/a computed property after fetching? Is the sort attribute covered by `#Index` on the model? Any view fetching the whole table where a bounded range would do?
- **A4 Row body cost:** formatters (`DateFormatter`, `NumberFormatter`, `MeasurementFormatter`) constructed inline, unit conversions, aggregations, sums over relationships, or any Swift Charts view rendered per row — all should move to `init` or a precomputed view model.
- **A5 `onAppear` misuse:** row setup in `onAppear` that mutates the row's size or content — that work belongs in the initializer; `onAppear` stays for genuinely appearance-bound work like paging.
- **A6 Invalidation:** `AnyView` in row hierarchies, `.id()` forcing rebuilds, `GeometryReader` inside rows, fast-changing values passed through `@Environment`.
- **A7 Extraction:** rows whose body is inlined in the parent instead of being its own `View` type — note where extracting one buys an independent invalidation boundary.

**B. Sections — exact checks required**
- **B8:** how are sections built? Flag any `Dictionary(grouping:)` or sort running inside `body` on every render; propose computing it once.
- **B9 Header/footer consistency:** `listStyle`, pinned headers, `listRowInsets` / `listRowSeparator` / `listRowBackground` applied per-row where a single container-level modifier would do.
- **B10 Empty/loading states:** is `ContentUnavailableView` placed above the `List`, or leaking into partially-resolved rows?

**C. Gestures — exact checks required**
- **C11 Inventory:** every gesture attached to rows or the `List` — `swipeActions`, `contextMenu`, `longPressGesture`, `onTapGesture`, `onMove`, drag/drop, `simultaneousGesture`, `highPriorityGesture`. Deliver as one table: gesture, where, what it does.
- **C12 Conflicts:** any custom gesture that can swallow the scroll or fight the swipe recognizer. Flag `longPressGesture` where `contextMenu` would be idiomatic, and `onTapGesture` on a row that also has a `NavigationLink` or `Button`.
- **C13 `swipeActions` review:** edge, `allowsFullSwipe`, and whether destructive actions carry `role: .destructive` and a confirmation path.
- **C14 Accessibility:** does every swipe/long-press action have an equivalent `accessibilityAction`? Are hit targets >= 44pt, does the row survive the largest Dynamic Type sizes (project rule: test up to AX5, per CLAUDE.md Accessibility section)?

**Deliverable shape**
- Findings report (A/B/C grouped, ranked by impact) as `RESEARCH.md`.
- A `gsd-planner` PLAN.md whose `verification_criteria` are expressed as `xcodebuild test` cases or other measurable/automatable checks — not subjective language.
- Anything that would require iOS 27 APIs to fix must be listed **separately**, under a "Later (needs iOS 27)" heading — do not raise the deployment target (CLAUDE.md: min deployment is iOS 26, non-negotiable) and do not fold iOS-27-only fixes into the actionable plan.

### Claude's Discretion
- Exact severity thresholds between `blocker` / `worth-fixing` / `nit` for borderline findings.
- Whether to propose one combined follow-up phase or split into multiple phases if the finding count is large enough to blow the planner's context budget (the planner may return `## PHASE SPLIT RECOMMENDED` — that is expected and should be handled per the standard plan-phase workflow, not treated as a failure).
- UI-SPEC.md is NOT required for this phase — it is a read-only audit + fix-plan, not new UI design work. Skip the UI design-contract gate if it triggers.

### Deferred Ideas (OUT OF SCOPE)
- Actually implementing any fix — explicitly out of scope for this phase; belongs in the follow-up execution phase this plan proposes, pending user approval.
- Reconciling `docs/plans/0038-history-list-lazy-scrollview/`'s stale frozen plan.md against the List revert (belongs to whoever formally closes out plan-0038 — flag it, don't fix it here).
</user_constraints>

---

## Project Constraints (from CLAUDE.md)

Every proposed fix below was checked against these. Where a fix collides with one, the collision is stated inline.

| Constraint | Effect on this audit |
|------------|---------------------|
| **Min deployment iOS 26** — non-negotiable | `#Index` (iOS 18+) and `ContentUnavailableView` (iOS 17+) are both available. Any iOS-27-only fix goes under "Later". |
| **SwiftUI only; `@Observable`, never `ObservableObject`** | `HistoryViewModel` is already `@Observable @MainActor`. B8's memoization fix must not introduce `@Published`. |
| **No repository layer (ADR-0004 supersedes ADR-0003)** | A3's filtering fixes must land as `#Predicate` on `@Query`, never as a fetch method on a new type. B8's caching must live in the view's `@State` or in the existing `@Observable` VM — not a new data-access layer. |
| **View models are stateless w.r.t. persistence; receive plain values** | B8's precomputed `DaySection` must be produced by a pure `HistoryViewModel` function and *held* by the view, not owned as VM mutable state tied to a `ModelContext`. |
| **NEVER edit a shipped `VersionedSchema` in place — new version + `MigrationStage`, no exceptions** | **Hard gate on A3-1.** Adding `#Index` to `ConsumptionEvent` changes the schema hash; it requires a new `SchemaV5` + `MigrationStage`. Amending `SchemaV4` would trigger "Cannot use staged migration with an unknown model version" and store recovery. |
| **CloudKit- and HealthKit-forward-compatible model shape** | A1-1's fix uses the *existing* `uuid` property — purely additive at the view layer, zero schema change, and it is the same identity CloudKit LWW already relies on. No conflict. |
| **300-line file ceiling (aim ~200)** | Every file in scope is currently well under (largest: `HistoryListQueryView.swift` at 139). The A7 extractions *reduce* sizes. No fix in this report pushes a file over. |
| **Accessibility: labels required, Dynamic Type to AX5, `reduceMotion`, 4.5:1 contrast** | Directly bounds C14. `reduceMotion` is already correctly honored (`animatedHistoryChange`). AX5 is not currently survivable in `EventRow` (C14-3). |
| **Swift 6 strict concurrency; no force-unwraps; `try!` only in previews/tests** | All findings' fixes are concurrency-neutral. No new force-unwraps proposed. |
| **Testing: ≥90% coverage; Domain 100%; UI test mandatory for any user-facing change** | C13-1, C14-1, C14-3, C14-4 and B10-1 are user-visible → each needs a `drinkpulseUITests` test. `verification_criteria` should lean on scoped `-only-testing:` runs. |
| **BAC / guidelines / sync conflict resolution: propose, do NOT implement without confirmation** | No finding here touches BAC or guideline math. A1-1 touches record *identity*, which is adjacent to sync conflict resolution — the plan should treat it as propose-then-confirm. |
| **All strings via `String(localized:)`; English only** | C13-1's confirmation copy and B10-1's loading-state copy need new String Catalog keys. |

---

## Step 1 — View Inventory

**Method:** `grep -rn --include="*.swift" -E "\bList\s*[\{\(]" drinkpulse/`, then a widened `\bList\b` sweep to catch modifier-chained and aliased uses, then a `\bForm\s*[\{\(]` sweep to identify List-backed containers deliberately left out of scope. Every hit was opened and read.

### Production `List`-containing views: **3**

| # | File | Line | Shape | Fed by |
|---|------|------|-------|--------|
| 1 | `drinkpulse/Features/History/HistoryListQueryView.swift` | 34 | `List { ForEach(dayGroups, id: \.day) { HistoryDaySectionCard } ; if hasMore { LoadMoreSentinel } else if !events.isEmpty { EndOfListFooter } }` | `@Query` on `ConsumptionEvent`, `#Predicate` `consumptionDate >= windowStart`, sort `consumptionDate` desc (`:21-25`) |
| 2 | `drinkpulse/Features/Settings/Components/GuidelinePickerSheet.swift` | 10 | `List { ForEach(GuidelineChoice.allCases.filter{...}, id: \.self) { Button } }` | In-memory `enum` cases. No `@Query`. |
| 3 | `drinkpulse/Features/Onboarding/Components/GuidelineStep.swift` | 26 | `List(choices, id: \.self) { Button }` | In-memory `let choices: [GuidelineChoice]`. No `@Query`. |

### Preview-only `List`: 1 (not audited as production)
- `drinkpulse/Features/History/Components/EventRow.swift:72` — `#Preview { List { EventRow×3 } }`. Correct usage; previews are mandatory per CLAUDE.md.

### Deliberately out of scope (documented, not audited)
- **`Form` containers (7 sites)** — `DrinkDetailInputView.swift:54`, `EditEventView.swift:123`, and 5 preview wrappers. `Form` renders as a grouped list on iOS, but CONTEXT scopes this phase to `List` and forbids adding checks beyond the 18. Noted for a future phase; the one with a real `@Query` shape worth a look later is `CustomNameSuggestionSection.swift:11` (`@Query(filter: #Predicate<ConsumptionEvent> { $0.customName != nil })` — an unbounded whole-table fetch inside a `Form`).
- **`ScrollView` + card containers** — `SettingsView`/`SettingsForm`, `DashboardView`, `InsightsView`, `HistoryCalendarQueryView` → `HistoryCalendarView`. Confirmed non-`List`. `HistoryCalendarDayDetail` is referenced repeatedly below only because it contains a **verbatim duplicate** of the History `List` row's body.

### SwiftData models and `@Query` declarations feeding a `List` view

**Models (`@Model`):** `ConsumptionEvent` (`Domain/ConsumptionEvent.swift`), `UserProfile`, `DrinkTemplate`. Versioned snapshots live in `Domain/Persistence/Schemas/SchemaV1…V4.swift`; **`SchemaV4` is current** (`SchemaV4.swift:15-16`, `Schema.Version(4, 0, 0)`).

**`@Query` declarations in the History `List`'s dependency chain:**

| Declaration | File:line | Predicate? | Sort | Bounded? |
|-------------|-----------|-----------|------|----------|
| `events` (the list contents) | `HistoryListQueryView.swift:5, 21-25` | ✅ `#Predicate` `consumptionDate >= windowStart` | `consumptionDate` desc | ✅ by rolling date window |
| `earliestEvents` (drives `hasMore` + empty state) | `HistoryView.swift:11, 32-36` | — (whole table) | `consumptionDate` asc | ✅ `fetchLimit = 1` |
| `profiles` (row unit context) | `HistoryView.swift:10` | — | — | ⚠️ unbounded, but the table holds one row by design |

**`#Index` coverage: NONE.** `grep -rn "#Index" drinkpulse/` returns zero hits across the whole repo. See A3-1.

---

# A. List Performance

*Ranked by impact within the group.*

### A1 — Identity

#### A1-1 · `blocker` · `HistoryDaySectionCard.swift:27`

`ForEach(Array(events.enumerated()), id: \.element.id)` keys every History row by `ConsumptionEvent.id`, which for a SwiftData `@Model` is the synthesized `PersistentIdentifier` — **not** the model's own `uuid`.

A freshly `insert()`-ed SwiftData object carries a **temporary** `PersistentIdentifier` that is replaced with the permanent one when the context saves. This repo already documents the mechanism first-hand:

> "a freshly `insert()`-ed SwiftData object carries a TEMPORARY `PersistentIdentifier` that only becomes permanent once the context saves. If the user opens this duplicate's Edit sheet before that save happens, SwiftData's own autosave can flip the identifier out from under `HistoryView`'s `.sheet(item:)` mid-edit, which SwiftUI reads as 'a different item,' tearing down and reconstructing the sheet — silently discarding every unsaved field"
> — `EventContextMenu.swift:39-50` `[VERIFIED: drinkpulse/Features/History/Components/EventContextMenu.swift:39-50]`, tracing to `.planning/debug/resolved/sheet-closes-reopens-loses-state.md`

The `.sheet(item:)` case was patched by saving inside the same transaction (`EventContextMenu.swift:51`, `:64`). The **`ForEach` identity case was never patched** — the row still keys on the volatile identifier. When the temp→permanent flip happens, SwiftUI reads it as *remove + insert* rather than *update*: per-row state and the in-flight transition are discarded. That is the most plausible remaining explanation for the class of animation glitches this feature has repeatedly needed hand-patching for (see STATE.md, 2026-07-31 "context-menu Duplicate and swipe/context-menu Delete actually animate via a `context.save()`-inside-`withAnimation` fix").

`ConsumptionEvent` already carries the correct identity, created for exactly this purpose:

> `/// Stable record identity (plan-0023). NOT @Attribute(.unique) — CloudKit cannot enforce uniqueness…`
> `var uuid: UUID = UUID()`
> — `[VERIFIED: drinkpulse/Domain/ConsumptionEvent.swift:6-10]`

**Why blocker:** it is a correctness defect in the identity of every row in the app's main list; the repo has a documented data-loss incident from the same mechanism; there is an open STATE.md todo ("Audit every `context.insert` call site for the missing-save identity race"); and the fix is one keypath.

**Concrete fix:** change the identity source to the model's own stable UUID in both copies of this `ForEach`:

```swift
// HistoryDaySectionCard.swift:27  and  HistoryCalendarDayDetail.swift:61
ForEach(Array(events.enumerated()), id: \.element.uuid) { index, event in
```

Preferred combined form (also resolves A1-3, A7-1, and the B8 restructure): introduce `struct DaySection: Identifiable { let id: Date; let title: String; let events: [ConsumptionEvent] }` and an `EventRowButton` view taking `event` + a precomputed index flag, so the outer `ForEach(dayGroups)` and inner `ForEach(section.events, id: \.uuid)` both key on stable values.

**Note for the planner:** identity is adjacent to sync conflict resolution, which CLAUDE.md gates behind "propose, do NOT implement until I confirm." Surface this fix for approval rather than executing it silently.

---

#### A1-2 · `nit` · `GuidelinePickerSheet.swift:11`

`ForEach(GuidelineChoice.allCases.filter { $0 != .custom }, id: \.self)` filters inline in `body`. The skill's rule — "Avoid inline filtering… prefilter and cache instead" `[CITED: swiftui-expert-skill references/list-patterns.md:63-81]` — applies: a fresh `Array` is allocated on every body pass.

`id: \.self` itself is **fine here** and is *not* the flagged anti-pattern: `GuidelineChoice` is an immutable `String`-raw-valued enum (`GuidelineChoice.swift:3-5` `[VERIFIED: drinkpulse/Domain/GuidelineChoice.swift:3-5]` — `enum GuidelineChoice: String, Codable, CaseIterable, Sendable { case who, de, uk, us, au, ca, custom }`), so `\.self` is stable, unique, and cheap to hash. A1's "flag `id: \.self` on mutable values" does not bite.

**Concrete fix:** hoist to a stored constant, and share it with `GuidelineStep` (which hard-codes the same set — see below):

```swift
// Domain/GuidelineChoice.swift
extension GuidelineChoice {
    /// Every guideline a user can pick. `.custom` is derived, never chosen directly.
    static let selectable: [GuidelineChoice] = allCases.filter { $0 != .custom }
}
// GuidelinePickerSheet.swift:11
ForEach(GuidelineChoice.selectable, id: \.self) { choice in
```

**Latent divergence worth fixing at the same time:** `GuidelineStep.swift:9` hard-codes `[.who, .de, .uk, .us, .au, .ca]` while `GuidelinePickerSheet.swift:11` derives it from `allCases`. Identical today; silently divergent the day a seventh guideline is added — the onboarding picker would omit it while Settings offered it. `GuidelineChoice.selectable` collapses both.

---

#### A1-3 · `nit` · `HistoryDaySectionCard.swift:27`, `HistoryCalendarDayDetail.swift:61`

`Array(events.enumerated())` wraps the enumerated sequence in an eager `Array` copy on every body evaluation. Per the skill: "No `Array(...)` wrapper is needed on Swift 6.1+. As of Swift 6.1, the sequence returned by `.enumerated()` conditionally conforms to `RandomAccessCollection`… Favor the direct form in new code — it avoids an eager copy on every body evaluation." `[CITED: swiftui-expert-skill references/list-patterns.md:170]`

The project sets `SWIFT_VERSION = 6.0` `[VERIFIED: drinkpulse.xcodeproj/project.pbxproj:287]`, but that is the *language mode*, not the toolchain; the conditional conformance is a stdlib feature of the Xcode 26 toolchain and iOS 26 runtime.

**Concrete fix:** drop the wrapper — `ForEach(events.enumerated(), id: \.element.uuid)`. Verify it compiles under the project's actual toolchain before committing; if it does not, leave the wrapper and close this nit as not-applicable.

**Better still:** the index is used only to decide whether to draw a trailing `Divider` (`:42`). Dropping `.enumerated()` entirely in favour of comparing against `events.last?.uuid`, or moving the divider to a `.overlay(alignment: .bottom)` on all-but-last, removes the index dependency and the copy together.

---

### A2 — Dynamic subview count

**Result: no violations.** Every `ForEach` leaf in all three `List` views returns exactly one top-level view.

- `HistoryListQueryView.swift:44-59` — the leaf is a single `HistoryDaySectionCard`. **Unary. Compliant.** This is the documented, deliberate shape from the `contextmenu-zoom-glitch` re-scope, and the code says so at `:35-43`.
- `HistoryDaySectionCard.swift:27-46` — the leaf branches (`if index < events.count - 1 { Divider() }`) but is wrapped in `VStack(spacing: 0)` at `:28`, so the leaf is one top-level view. **Compliant**, and it is the exact remedy the skill prescribes: "wrap branching content in any single-root container… so the row is always exactly one top-level view." `[CITED: swiftui-expert-skill references/list-patterns.md:120]` The inner `VStack` is not a lazy container, so the variable child count inside it costs nothing structurally.
- `HistoryCalendarDayDetail.swift:61-72` — same shape, same verdict (not a `List`, listed for completeness).
- `GuidelinePickerSheet.swift:12-34` — leaf is one `Button`. **Unary.**
- `GuidelineStep.swift:27-48` — leaf is one `Button`. **Unary.**

**No optional is unwrapped inline in any `ForEach` leaf.** Nothing here needs moving into a `#Predicate`.

#### A2-1 · `nit` · `HistoryListQueryView.swift:60-70`

The `List` *content builder* — not a `ForEach` leaf — ends with `if hasMore { LoadMoreSentinel } else if !events.isEmpty { EndOfListFooter }`, an `if / else if` with no final `else`, i.e. a 0-or-1-view slot.

**This is not the A2 defect.** The eager-iteration cost documented at WWDC23 applies to *`ForEach` row builders* inside a lazy container: "SwiftUI needs to know the total number of rows in the List upfront… If conditionals or other constructs like AnyView make this number dynamic, it requires SwiftUI to eagerly iterate over all elements, create those views and compute how many rows the `ForEach` actually produces" `[CITED: developer.apple.com/videos/play/wwdc2023/10160/ — "Demystify SwiftUI performance", WWDC23 session 10160]`. Here the conditional occupies a fixed structural position in the builder, not a per-element one, so it costs at most one extra view-count resolution per body pass — O(1), not O(rows).

**Concrete fix (optional):** for symmetry and to make the "no third state" assumption explicit, give it a terminal `else { EmptyView() }`, or fold both trailing rows into one `HistoryListFooter` view that switches internally. Purely stylistic; take it only if the row is being touched for B10-1 anyway.

---

### A3 — `@Query` audit

#### A3-1 · `worth-fixing` · `Domain/ConsumptionEvent.swift` (whole model) — gated on a schema version bump

**Filters:** correctly expressed as `#Predicate` on the `@Query`, not applied post-fetch in `body`.

> ```swift
> _events = Query(
>     filter: #Predicate<ConsumptionEvent> { $0.consumptionDate >= windowStart },
>     sort: \ConsumptionEvent.consumptionDate,
>     order: .reverse
> )
> ```
> — `[VERIFIED: drinkpulse/Features/History/HistoryListQueryView.swift:21-25]`

Same for the calendar path (`HistoryCalendarQueryView.swift:22-28`, a bounded `>= monthStart && < monthEnd` range). **Compliant** — nothing to move into a predicate.

**Bounded ranges:** the History list fetches a rolling 7-day window (`HistoryViewModel.listPageDays = 7` `[VERIFIED: drinkpulse/Features/History/HistoryViewModel.swift:14-15]`), extended one page at a time with empty-page collapsing. `earliestEvents` fetches the whole table but caps it: `descriptor.fetchLimit = 1` `[VERIFIED: drinkpulse/Features/History/HistoryView.swift:32-36]`. **Compliant.** No view fetches the whole `ConsumptionEvent` table unbounded.

**`#Index`: the gap.** `grep -rn "#Index" drinkpulse/` returns **zero hits**. Every query above sorts and range-filters on `consumptionDate` with no binary index behind it. Apple introduced `#Index` in iOS 18 precisely for this: "The new `#Index` macro adds the ability to create a single or compound index on your model… This metadata makes queries for specified key paths faster and more efficient. For a large data set, this makes filtering and sorting substantially faster." `[CITED: developer.apple.com/videos/play/wwdc2024/10137/ — "What's new in SwiftData", WWDC24 session 10137; developer.apple.com/documentation/swiftdata/index(_:)-74ia2]` The project's iOS 26 floor means it is available today.

`consumptionDate` is the single hottest key path in the app: it is the predicate *and* the sort for the History list, the calendar month query, and the `earliestEvents` probe, and it is `@Attribute(originalName: "timestamp")`-mapped `[VERIFIED: drinkpulse/Domain/ConsumptionEvent.swift:15-16]`.

**Concrete fix:**

```swift
// Domain/ConsumptionEvent.swift, inside the @Model
#Index<ConsumptionEvent>([\.consumptionDate])
```

**⚠️ HARD GATE — do not skip.** Adding `#Index` changes the model's schema shape and therefore its schema hash. CLAUDE.md: *"NEVER edit a shipped/committed `VersionedSchema` in place… Amending an existing version keeps its version number but changes its schema hash, so any device already on that version reports 'Cannot use staged migration with an unknown model version' and falls into store recovery (data moved aside). This is forbidden even for local/physical-device testing."* This fix therefore requires:
1. Freezing the current shape as `SchemaV4` (already done — `SchemaV4.swift:15-16`, `Schema.Version(4, 0, 0)`).
2. A new `SchemaV5` carrying the indexed model.
3. A new `MigrationStage` V4→V5 (lightweight — an index add is metadata-only, no property change).

The planner must model this as its own task with its own verification, **not** as a line-edit bundled into a performance task. If the owner does not want a schema bump for a perf-only change, close A3-1 as accepted-and-deferred rather than amending `SchemaV4`.

**Measurement caveat:** the win is real but currently small — the working set is 7 days of one person's drinks. It grows with history length and matters most for the `earliestEvents` full-table sort, which scans everything to return one row. Verify with an actual measurement (`OSSignposter` around the fetch, or the existing `ViewLoadLogger`) before and after, rather than asserting an improvement.

#### A3-2 · `nit` · `HistoryView.swift:10`

`@Query private var profiles: [UserProfile]` is unbounded. `UserProfile` is a singleton table by design (`UserProfileStore` deduplicates — `Domain/Persistence/UserProfileStore.swift:28-36`), so this is harmless. Adding `fetchLimit = 1` would make the intent explicit and match the `earliestEvents` pattern already used two lines below. Cosmetic.

---

### A4 — Row body cost

#### A4-1 · `worth-fixing` · `EventRow.swift:23, 32, 40, 43, 49, 52-68` — **the largest per-row cost in the app**

`EventRow` formats the same underlying values **twice per body evaluation**: once for what is drawn, and again for the accessibility label — which is a plain computed property, so it is evaluated eagerly on every render whether or not VoiceOver is running.

Duplicated work per row, per body pass:

| Operation | Display call site | A11y call site |
|-----------|------------------|----------------|
| `event.displayName(in: unitSystem)` → `DrinkTypePreset.preset(for:)` + linear `first(where:)` over `volumes` + `trimmingCharacters` | `:23` | `:62` |
| `unitSystem.formatVolume(event.volumeMl)` → `String(localized:)` bundle lookup + `String(format:)` | `:53` (inside `subtitleText`) | `:63` |
| `alcoholUnit.formattedValue(massGrams, guideline:)` → `String(format: "%.1f", …)` | `:40` | `:60`, `:64` |
| `alcoholUnit.unitLabel(for:)` → `String(localized:)` bundle lookup | `:43` | `:65` |
| `event.consumptionDate.formatted(.dateTime.hour().minute())` → inline `Date.FormatStyle` construction + full format pass | `:55` | `:67` |
| `String(format: "%.1f%%", event.abv * 100)` | `:54` | `:61` (as `%.1f percent`) |

That is **six formatting operations done twice = twelve per row, per body pass**, on top of two `String(localized:)` bundle lookups inside `formatVolume` (`UnitSystem+Volume.swift:47, 52` `[VERIFIED: drinkpulse/Domain/UnitSystem+Volume.swift:43-56]`) and one inside `unitLabel` (`AlcoholUnit.swift:76-80`).

This is exactly the anti-pattern A4 targets and the one the skill names: "BAD — creates new formatter every body call… GOOD — static or stored formatter" and "Move sorting, filtering, and formatting into models or computed properties. The `body` should be a pure structural representation of state." `[CITED: swiftui-expert-skill references/performance-patterns.md:344-387]`

Mitigating facts, stated honestly: `DrinkTypePreset.preset(for:)` returns `nonisolated static let` values (`DrinkTypePreset+FermentedPresets.swift:30`, `+SpiritPresets.swift:34`, `+MixedPresets.swift:16` `[VERIFIED]`), so the presets are built once, not per call — the per-call cost is a struct copy plus a short linear scan, not a rebuild. And no `DateFormatter`/`NumberFormatter`/`MeasurementFormatter` object is constructed anywhere in a row body (`grep` confirms zero hits in `Domain/`), and **no Swift Charts view is rendered per row**. So this is "the same modest cost paid twice, on every row, on every pass" — not a pathological one.

**Concrete fix:** precompute both strings once, in one place, and hand them to a POD row view. Add to `EventRow` (or a new `EventRowStrings` value type):

```swift
struct EventRowStrings: Equatable {
    let name: String
    let subtitle: String       // "500 ml · 5.0% · 21:14"
    let amount: String         // "2.0"
    let unitLabel: String      // "std"
    let accessibilityLabel: String
}
```

Build it once in `EventRow.init` (or in a pure `HistoryViewModel.rowStrings(for:profile:)` function, which is unit-testable and keeps the VM stateless w.r.t. persistence per ADR-0004), reusing the *same* `name` / `volume` / `time` locals for both the visible text and the accessibility string. This halves the formatting work and makes `EventRow` a POD view — "POD (Plain Old Data) views use `memcmp` for fastest diffing" `[CITED: swiftui-expert-skill references/performance-patterns.md:87-136]`.

**Testing note:** `EventRowStrings` construction being a pure function is what makes this verifiable — `verification_criteria` can assert exact string output for a fixed event/profile pair in `drinkpulseTests/Features/History/`, rather than asserting "it is faster."

---

#### A4-2 · `worth-fixing` · `HistoryListQueryView.swift:82-87`

```swift
private func sectionTitle(for day: Date) -> String {
    let cal = Calendar.current
    if cal.isDateInToday(day) { return String(localized: "history.today") }
    if cal.isDateInYesterday(day) { return String(localized: "history.yesterday") }
    return day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
}
```
`[VERIFIED: drinkpulse/Features/History/HistoryListQueryView.swift:82-87]`

Called at `:46` for **every section, on every body evaluation**. Each call fetches `Calendar.current`, runs two calendar comparisons, and — for all but two sections — constructs a four-component `Date.FormatStyle` inline and runs a full locale-aware format pass. With a 7-day window that is up to 7 calls per pass; the window grows without bound as the user paginates.

**Concrete fix:** fold the title into the precomputed section value produced once per data change (see B8-1) rather than derived per render:

```swift
// HistoryViewModel.swift — pure, testable, no ModelContext
struct DaySection: Identifiable, Equatable {
    let id: Date          // startOfDay — also the ForEach identity
    let title: String     // precomputed once
    let events: [ConsumptionEvent]
}
func daySections(_ events: [ConsumptionEvent], now: Date = .now, calendar: Calendar = .current) -> [DaySection]
```

Then `ForEach(dayGroups) { HistoryDaySectionCard(title: $0.title, …) }` — no `id:` argument needed, no `.id()` modifier needed (resolves A6-2), no per-render formatting.

**Correctness caveat the planner must encode:** "Today"/"Yesterday" are time-dependent. Precomputing them means a section title can go stale if the app stays foregrounded across midnight. Today's per-render derivation is accidentally immune to that. The fix must recompute on scene-phase activation (or on a day-change notification) — and that behavior should be a `verification_criteria` line, not an unstated assumption.

#### A4-3 · `nit` · `EventRow.swift:7-12`

`alcoholUnit`, `guideline`, `unitSystem`, `massGrams` are computed properties re-derived on each access; `massGrams` is read at `:40` and again at `:60`. Each is trivial (an optional read or one multiply chain), so this is dominated by A4-1 and is subsumed by the same `EventRowStrings` fix. No separate action.

---

### A5 — `onAppear` misuse

**Result: no violations.** `grep` for `onAppear|onDisappear` across `drinkpulse/` returns 6 production sites; exactly one is inside a `List`.

#### A5-1 · compliant · `HistoryListQueryView.swift:116-127`

`LoadMoreSentinel` uses `.onAppear` to fire pagination and `.onDisappear` to reset a one-shot latch. This is **precisely the "genuinely appearance-bound work like paging"** A5 carves out. It performs no row setup, mutates no row size or content, and the sentinel is a `Color.clear.frame(height: 1)` whose geometry is fixed. **Nothing to fix.**

No `onAppear` exists in `HistoryDaySectionCard`, `EventRow`, `GuidelinePickerSheet`, or `GuidelineStep`. The other production sites (`drinkpulseApp.swift:134`, `RootShellView.swift:96`, `DrinkDetailInputView.swift:115`, `EditEventView.swift:197`, `ViewLoadLogger.swift:75`) are not inside any `List`.

**⚠️ But see "Contradictions" below** — the *justification comment* at `:103-115` for choosing `.onAppear` rests on a mechanism claim that is not Apple-documented, and it directly reverses a fix recorded as shipped in a `resolved` debug session. The behavior is fine; the paper trail is not.

---

### A6 — Invalidation

#### A6-1 · `worth-fixing` · `HistoryListQueryView.swift:48`, `HistoryDaySectionCard.swift:15`, `EventRow.swift:5`

`profile: UserProfile?` — a SwiftData `@Model` **class**, i.e. an `@Observable` reference type — is threaded down into every single row. Each `EventRow` reads `profile?.alcoholUnit`, `profile?.guidelineChoice`, `profile?.unitSystem` (`EventRow.swift:7-9`), establishing an observation dependency on that object from every visible row.

Consequence: editing *any* observed property of `UserProfile` — including body weight, date of birth, or the weekly goal, none of which a History row displays — invalidates every visible row. The `Settings` screen mutates `UserProfile` directly via `@Bindable` (`SettingsView.swift:25`), so this is a live path, not theoretical.

The skill is explicit: "Avoid passing large 'config' or 'context' objects. Pass only the specific values each view needs… With `@Observable`, views update only when accessed properties change, but passing entire objects still creates broader dependencies than necessary." `[CITED: swiftui-expert-skill references/performance-patterns.md:48-61]` and "Narrow state scope to reduce update fan-out." `[CITED: …:215-233]`

**Concrete fix:** replace the `UserProfile?` parameter on `EventRow` / `HistoryDaySectionCard` with a small POD value carrying only what a row renders:

```swift
struct RowUnitContext: Equatable, Sendable {
    let alcoholUnit: AlcoholUnit
    let guideline: GuidelineChoice
    let unitSystem: UnitSystem
    init(_ profile: UserProfile?) {
        alcoholUnit = profile?.alcoholUnit ?? .standardDrinks
        guideline   = profile?.guidelineChoice ?? .who
        unitSystem  = profile?.unitSystem ?? .metric
    }
}
```
Resolve it once in `HistoryListQueryView` and pass the value down. Rows become POD (fast `memcmp` diffing) and invalidate only when a displayed unit actually changes. The `?? .standardDrinks / .who / .metric` defaults are lifted verbatim from `EventRow.swift:7-9` so behavior is unchanged.

**Bonus:** this also fixes the same fan-out in `HistoryCalendarDayDetail.swift:14-15`, which reads `profile` for the exact same three values.

#### A6-2 · `nit` · `HistoryListQueryView.swift:51`

```swift
ForEach(vm.groupedByDay(events), id: \.day) { section in
    HistoryDaySectionCard(…)
        .id(section.day)
```
`[VERIFIED: drinkpulse/Features/History/HistoryListQueryView.swift:44-51]`

`.id(section.day)` assigns **explicit identity** to a row whose implicit `ForEach` identity is *already* `section.day`. It is exactly redundant. Explicit identity is a distinct mechanism from `ForEach` identity — a change to an explicit `.id()` value tears down and rebuilds the view rather than updating it `[CITED: developer.apple.com/videos/play/wwdc2021/10022/ — "Demystify SwiftUI", WWDC21 session 10022, identity section]`. Because the two values can never differ here, the effect today is neutral-to-harmless.

It is nonetheless the **only** `.id()` call in the entire app (`grep -rn "\.id(" drinkpulse/` → one hit), which makes it an outlier worth removing: it invites the assumption that some rows need forced rebuilds, and it interacts unpredictably with the `.transition(...)` applied one level down at `HistoryDaySectionCard.swift:52`.

**Concrete fix:** delete line 51. Once the B8-1 / A4-2 `DaySection: Identifiable` refactor lands, the `ForEach` needs no `id:` argument either.

#### A6-3 · `nit` · `HistoryDaySectionCard.swift:9-11`

Each card reads three `@Environment` values (`\.modelContext`, `\.healthService`, `\.accessibilityReduceMotion`). None are fast-changing, so this is **not** the A6 violation. Worth recording only because "every write to *any* environment key forces every view that reads *any* key in that subtree to be checked" `[CITED: swiftui-expert-skill references/performance-patterns.md:235]` — so if a high-frequency `@Entry` is ever added to this subtree, these rows become the blast radius. Note it; do not act on it.

#### A6-4 · compliant

- **`AnyView` in row hierarchies:** `grep -rn "AnyView" drinkpulse/` → **zero hits repo-wide.** Clean.
- **`GeometryReader` inside rows:** two hits (`GuidelineComparisonCard.swift:34`, `ConsumptionOverviewCard.swift:111`), **neither inside any `List` row** — both are Insights/Dashboard cards in `ScrollView`s. Clean.
- **Fast-changing values through `@Environment`:** none. Clean.

---

### A7 — Extraction

#### A7-1 · `worth-fixing` · `HistoryDaySectionCard.swift:28-45` ↔ `HistoryCalendarDayDetail.swift:61-72`

The per-event row hierarchy — `VStack { Button { onEditEvent } label: { EventRow.contentShape(Rectangle()) }.buttonStyle(.plain)[.padding].eventContextMenu(…) ; if !last { Divider().padding(.leading, 48) } }` — is **written out twice, verbatim, in two files**, and is inlined in each parent rather than being its own `View` type.

The two copies have already diverged:

| | `HistoryDaySectionCard.swift` | `HistoryCalendarDayDetail.swift` |
|---|---|---|
| `.padding(.vertical, 10)` on the Button | ✅ `:40` | ❌ **absent** |

That padding is not cosmetic trivia — it is the entire subject of BUG 1 in `.planning/debug/resolved/history-scrollview-bugs.md`, whose root cause was recorded as *"rows collapsed to font-metrics-only height."* The calendar day-detail rows are still in that pre-fix state. Duplication is why the fix landed in one place only.

Extraction also buys the invalidation boundary A7 asks about: a standalone `EventRowButton` with `let event`, `let unitContext`, `let isLast` is POD (given A6-1), so SwiftUI can skip its body whenever those three compare equal — instead of re-running the inlined hierarchy as part of the parent card's body.

**Concrete fix:** create `drinkpulse/Features/History/Components/EventRowButton.swift`:

```swift
struct EventRowButton: View {
    let event: ConsumptionEvent
    let unitContext: RowUnitContext
    let isLast: Bool
    let onEdit: (ConsumptionEvent) -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.healthService) private var healthService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Button { onEdit(event) } label: {
                EventRow(event: event, unitContext: unitContext)
                    .padding(.vertical, 10)          // ← inside the label (fixes C14-1)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .eventContextMenu(for: event, in: modelContext,
                              healthService: healthService, reduceMotion: reduceMotion)
            if !isLast { Divider().padding(.leading, 48) }
        }
    }
}
```

Both call sites collapse to `EventRowButton(...)`. **This one extraction resolves A7-1, C12-1, and C14-1 together, and is the natural home for C14-2's `accessibilityAction`s.** File sizes drop: `HistoryDaySectionCard.swift` 77 → ~55, `HistoryCalendarDayDetail.swift` 112 → ~90; the new file is ~35 lines. All comfortably under the 300-line ceiling.

#### A7-2 · `worth-fixing` · `GuidelinePickerSheet.swift:12-34` ↔ `GuidelineStep.swift:27-48`

The guideline-choice row — `Button { … } label: { HStack { VStack { Text(name).font(.body); Text(thresholdSummary).font(.caption).secondary } ; Spacer() ; if selected { checkmark } }.contentShape(Rectangle()) }.buttonStyle(.plain)` — is inlined in both files. The copies have diverged in **three** ways:

| | `GuidelinePickerSheet.swift` | `GuidelineStep.swift` |
|---|---|---|
| Name source | `choice.displayName` (`:18`) | `choice.onboardingName` (`:32`, a private extension at `:65-77`) |
| Checkmark symbol | `"checkmark"` + `.fontWeight(.semibold)` (`:27-29`) | `"checkmark.circle.fill"` (`:41-42`) |
| `.accessibilityAddTraits(.isSelected)` | ❌ **absent** | ✅ `:48` |

The third row is a real accessibility defect (see C14-4). The first two are unexplained UI inconsistency between two screens that present the same choice list — reading `GuidelineChoice+Display.swift:14` and `GuidelineStep.swift:65-77` side by side, `onboardingName` resolves to the same `settings.guideline.*` String Catalog keys `displayName` does, so the two names are likely already identical strings reached by two code paths.

**Concrete fix:** create `drinkpulse/DesignSystem/` or `Features/Settings/Components/GuidelineChoiceRow.swift` taking `(choice, sex, isSelected, onSelect)`, and use it from both. Confirm with the owner which checkmark symbol is canonical before unifying — that is a visible design choice, not a mechanical refactor, and it is the one part of this fix that needs a decision rather than a rename.

#### A7-3 · compliant · `HistoryListQueryView.swift:90-139`

`LoadMoreSentinel` and `EndOfListFooter` are already `private struct` types with their own bodies, not inlined `@ViewBuilder` blobs. Correct per A7. No action.

---

# B. Sections

*Ranked by impact within the group.*

### B8 — How sections are built

#### B8-1 · `worth-fixing` · `HistoryListQueryView.swift:44` → `HistoryViewModel.swift:56-66`

```swift
ForEach(vm.groupedByDay(events), id: \.day) { section in
```
calls, **on every body evaluation**:
```swift
func groupedByDay(_ events: [ConsumptionEvent], calendar: Calendar = .current)
    -> [(day: Date, events: [ConsumptionEvent])] {
    let dict = Dictionary(grouping: events) { calendar.startOfDay(for: $0.consumptionDate) }
    return dict
        .sorted { $0.key > $1.key }
        .map { (day: $0.key, events: $0.value.sorted { $0.consumptionDate > $1.consumptionDate }) }
}
```
`[VERIFIED: drinkpulse/Features/History/HistoryViewModel.swift:56-66]`

Per pass: one `Dictionary(grouping:)` over all windowed events (N `startOfDay` calendar computations + N dictionary insertions), one sort of the day keys, and one sort **per day group**, plus the tuple array allocation. This is precisely what B8 is written to catch — `Dictionary(grouping:)` *and* sorts running inside `body`.

It re-runs not only when `events` changes, but whenever anything else invalidates `HistoryListQueryView`'s body: a `hasMore` flip, a `profile` mutation (A6-1's fan-out reaches here too), or a parent re-render. The skill: "BAD — sorts array every body call… GOOD — compute once… Move sorting, filtering, and formatting into models or computed properties." `[CITED: swiftui-expert-skill references/performance-patterns.md:366-387]`

**Concrete fix,** respecting ADR-0004 (no repository layer; the VM stays stateless w.r.t. persistence — the pure function lives on the VM, the *cache* lives in the view's `@State`):

```swift
// HistoryListQueryView
@State private var sections: [DaySection] = []

var body: some View {
    List {
        ForEach(sections) { section in           // Identifiable — no id: needed
            HistoryDaySectionCard(title: section.title, events: section.events, …)
        }
        …
    }
    .onChange(of: events, initial: true) { _, new in
        sections = vm.daySections(new)           // recomputed only when the fetch result changes
    }
}
```

`daySections` is a pure function on the existing `@Observable` VM — unit-testable against fixed inputs, no `ModelContext`, no new layer. This is the same "prefilter and cache" shape the skill prescribes `[CITED: swiftui-expert-skill references/list-patterns.md:71-81]`.

**This single restructure also closes A4-2 (title precomputed), A6-2 (no `.id()` needed), and the tuple half of A1-1 (`DaySection: Identifiable`).** It is the highest-leverage B-group fix and should be planned as one task with those, not four.

**Planner caveats:** (1) `onChange(of: events)` requires `[ConsumptionEvent]` to be `Equatable` — SwiftData model classes compare by reference identity, which is correct here (a new fetch result yields a new array). (2) `initial: true` is required or the first render shows an empty list. (3) The midnight-staleness caveat from A4-2 applies to the cached titles.

#### B8-2 · `nit` · `HistoryViewModel.swift:65`

`.map { (day: $0.key, events: $0.value.sorted { $0.consumptionDate > $1.consumptionDate }) }` re-sorts each day's events descending. But both callers already receive events sorted descending by the `@Query` (`HistoryListQueryView.swift:23-24` `sort: \ConsumptionEvent.consumptionDate, order: .reverse`; `HistoryCalendarQueryView.swift:26-27`, same), and `Dictionary(grouping:)` preserves the relative order of elements within each group for an ordered input.

So the per-group sort is redundant work per group per pass.

**Concrete fix:** drop it — **but only with the coupling made explicit.** Removing it makes `groupedByDay` silently dependent on its caller's sort order, which is a worse contract than a redundant sort. If the plan takes this, it must (a) document the precondition in the function's doc comment, and (b) keep/extend the `HistoryViewModelTests` case that feeds *unsorted* input, converting it from "asserts it sorts" to "asserts it preserves input order." Given the sort is over a handful of drinks per day, **this is genuinely marginal — take it only as part of the B8-1 rewrite, never on its own.**

---

### B10 — Empty / loading states

#### B10-1 · `worth-fixing` · `HistoryListQueryView.swift:60-70`

There is no state for **"the current window is empty but older data exists."** The builder covers `hasMore` (1pt invisible sentinel) and `!events.isEmpty` (end-of-list footer). When `events` is empty **and** `hasMore` is true, the user sees a completely blank `List`.

This became materially more likely five days ago: quick task `260802-uia` shrank `listPageDays` from **90 → 7** (STATE.md, 2026-08-02; `HistoryViewModel.swift:14-15`). A user who last logged a drink 10 days ago now opens History to an empty screen.

**Honest severity assessment — why this is not a blocker:** the sentinel is the only row, so it is immediately visible, so `.onAppear` fires immediately (`:119-123`), so `extendListWindow` runs, and `extendedWindowStart(from:earliest:)` collapses *all* consecutive empty pages in one jump (`HistoryViewModel.swift:36-47` `[VERIFIED]`). The blank state self-heals within roughly one render cycle. It is a flash, not a stuck screen. But it is an unstyled, uncommunicative flash on the app's main list, and the fix is three lines.

**Concrete fix:** add the missing branch, above the sentinel:

```swift
if events.isEmpty && hasMore {
    ProgressView()
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityLabel(String(localized: "history.list.loadingOlder"))
}
```
New String Catalog key required (English only, per CLAUDE.md). User-facing → needs a `drinkpulseUITests` test per CLAUDE.md's mandatory-UI-test rule: seed a dataset whose only events predate the 7-day window, assert the loading state appears and is then replaced by rows.

#### B10-2 · compliant · `HistoryView.swift:137-152, 203-209`

```swift
if earliestEvent == nil { emptyState } else { HistoryListQueryView(…) }
…
private var emptyState: some View {
    ContentUnavailableView(String(localized: "history.emptyTitle"), systemImage: "wineglass",
                           description: Text(String(localized: "history.emptyDescription")))
}
```
`[VERIFIED: drinkpulse/Features/History/HistoryView.swift:137-152, 203-209]`

`ContentUnavailableView` sits **above** the `List` — it replaces the entire list rather than leaking into a row. This is exactly what B10 asks for, and it is driven by the `fetchLimit = 1` `earliestEvents` probe rather than by the windowed query, so it correctly means "no data at all," not "no data in this window." **Correct. No action.**

`GuidelinePickerSheet` / `GuidelineStep`: **N/A** — both render a finite, non-empty, compile-time-known enum set. Neither can be empty or loading.

---

### B9 — Header / footer consistency

#### B9-1 · `worth-fixing` · `HistoryListQueryView.swift:56-58, 62-64, 67-69`

The same row-chrome triple is repeated on all three row kinds:

```
:56  .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
:57  .listRowSeparator(.hidden)
:58  .listRowBackground(Color.clear)
:62  .listRowInsets(EdgeInsets())
:63  .listRowSeparator(.hidden)
:64  .listRowBackground(Color.clear)
:67  .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
:68  .listRowSeparator(.hidden)
:69  .listRowBackground(Color.clear)
```
`[VERIFIED: drinkpulse/Features/History/HistoryListQueryView.swift:56-69]`

Six of the nine lines are identical, and the insets differ only between "content row" and "sentinel." Adding B10-1's loading row would make it a fourth copy.

**Concrete fix** — a local `ViewModifier`, which is unambiguously correct:

```swift
private extension View {
    func historyListRowChrome(insets: EdgeInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)) -> some View {
        listRowInsets(insets)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
```
Three call sites become `.historyListRowChrome()` / `.historyListRowChrome(insets: EdgeInsets())`.

**Do not** blind-hoist `.listRowSeparator(.hidden)` / `.listRowBackground(Color.clear)` onto the `List` itself as a "container-level modifier." I could not confirm from Apple documentation this session that row-scoped modifiers applied to the container propagate to every row in `.plain` style — that is `[ASSUMED]`, and it is the kind of thing that silently half-works. The `ViewModifier` above achieves B9's stated goal ("a single container-level modifier would do") without depending on unverified propagation semantics. If the executor wants the container-level form, it needs an actual on-device check first.

`.listStyle(.plain)` at `:72` is already correctly applied once at the container level. ✅

#### B9-2 · `nit` · `GuidelinePickerSheet.swift` (no `.listStyle`) vs `GuidelineStep.swift:50`

`GuidelineStep` states `.listStyle(.insetGrouped)` explicitly; `GuidelinePickerSheet` states nothing and inherits the platform default (`.insetGrouped` for a `List` inside a `NavigationStack` on iOS). Same rendered result today, reached implicitly in one file and explicitly in the other.

**Concrete fix:** add `.listStyle(.insetGrouped)` to `GuidelinePickerSheet.swift` after `:36`, or drop it from `GuidelineStep.swift:50` — either way, pick one convention. Subsumed by A7-2's shared row extraction if that lands with a shared container.

#### B9-3 · `nit` · `GuidelinePickerSheet.swift:10`, `GuidelineStep.swift:26`

These two are the **last `.insetGrouped` `List` screens in the app**, and the codebase records that as a deliberate thing to have moved away from:

> `/// the opaque `.insetGrouped` List rows that made Settings the odd screen out.`
> — `[VERIFIED: drinkpulse/Features/Settings/Components/SettingsSection.swift:5]`

Settings, Dashboard, Insights, and History all now use `ScrollView` + `dpGlassCard` sections (`SettingsSection`/`SettingsRow`, plan-0027; `HistoryDaySectionCard`, which its own doc comment describes as replacing `List`'s `Section(title){ForEach}` — `HistoryDaySectionCard.swift:4-7`). By that stated rationale, the guideline pickers are now the odd screens out.

**Concrete fix:** convert both to `ScrollView` + `SettingsSection` + the shared `GuidelineChoiceRow` from A7-2. **This is the one finding in this report that converts a `List` to a `ScrollView`,** which CONTEXT explicitly permits ("unless a finding specifically recommends converting a `List` to one"). It is a **visual** change, so it needs owner sign-off and a UI test, and it is cosmetic — schedule it last, or defer it entirely. Do not bundle it with a performance task.

#### B9-4 · N/A — pinned headers

No `Section` exists in any of the three `List` views, therefore no headers, no footers, no `.headerProminence`, and no pinned-header configuration anywhere. History deliberately uses card rows instead of `Section`s (the documented remedy for FB11280425 — `HistoryListQueryView.swift:35-43`). **Nothing to check.**

---

# C. Gestures

### C11 — Gesture inventory

**Method:** `grep -rn --include="*.swift" -E "\.swipeActions|\.contextMenu|onTapGesture|onLongPressGesture|LongPressGesture|\.onMove|\.onDelete|simultaneousGesture|highPriorityGesture|\.gesture\(|DragGesture|draggable|dropDestination|accessibilityAction|NavigationLink" drinkpulse/` — **2 hits repo-wide**, one of which is a comment. Widened separately for `contextMenu` (6 hits, 3 of them comments/the definition). The inventory below is therefore exhaustive, not a sample.

**Covering all three `List`-containing views:**

| Gesture | Where (`file:line`) | What it does |
|---------|---------------------|--------------|
| **`Button` tap** (implicit `TapGesture`) | `HistoryDaySectionCard.swift:29-35` — `Button { onEditEvent(event) } label: { EventRow.contentShape(Rectangle()) }.buttonStyle(.plain)` | Opens the Edit sheet for that event (`HistoryView.swift:148` → `.sheet(item: $editingEvent)` at `:87`). Hit shape pinned by `.contentShape(Rectangle())` — **but see C14-1: the row's 10pt vertical padding is applied outside the Button and is not tappable.** |
| **`.contextMenu`** (system long-press) | `HistoryDaySectionCard.swift:41` → `EventContextMenu.swift:30` | Presents Duplicate + Delete for one event. **Duplicate** (`EventContextMenu.swift:34-55`): `event.duplicated()` → `context.insert` → `RecordDeduplicator.ensureUniqueIdentity` → `try? context.save()`, all inside `animatedHistoryChange`. **Delete** (`:57-65`, `role: .destructive`): `HealthWriteHooks.remove` → `context.delete` → `try? context.save()`, same animation wrapper. |
| **`List` scroll** (system) | `HistoryListQueryView.swift:34` | Vertical scroll; drives `LoadMoreSentinel.onAppear` (`:119`) → `extendListWindow` (`HistoryView.swift:228-236`) → pagination. |
| **`Button` tap** | `GuidelinePickerSheet.swift:12-33` — `Button { selection = choice; dismiss() } label: { HStack.contentShape(Rectangle()) }.buttonStyle(.plain)` | Sets the bound `GuidelineChoice` and dismisses the sheet. |
| **`List` scroll** (system) | `GuidelinePickerSheet.swift:10` | Vertical scroll over 6 static rows. |
| **Sheet drag-to-dismiss** (system) | `GuidelinePickerSheet.swift:45-46` — `.presentationDetents([.medium, .fraction(0.95)])` + `.presentationDragIndicator(.visible)` | Interactive detent drag / dismiss. Owned by the sheet, competes with the `List`'s scroll via the system's standard sheet-vs-scroll arbitration. Not a custom gesture. |
| **`Button` tap** | `GuidelineStep.swift:27-46` — `Button { onSelect(choice) } label: { HStack.contentShape(Rectangle()) }.buttonStyle(.plain)` | Reports the selected guideline to the onboarding flow. Does not advance the step. |
| **`List` scroll** (system) | `GuidelineStep.swift:26` | Vertical scroll over 6 static rows. |

**Explicitly absent from every `List` in the app** (each verified by the greps above, zero hits):

| Gesture | Status |
|---------|--------|
| `.swipeActions` | **none anywhere in the repo** — see C13-2 and "Later" |
| `.onDelete` / `.onMove` | none |
| `.onTapGesture` | none |
| `.onLongPressGesture` / `LongPressGesture` | none |
| `.simultaneousGesture` / `.highPriorityGesture` / `.gesture(...)` | none |
| `DragGesture` / `.draggable` / `.dropDestination` | none |
| `NavigationLink` inside a `List` row | none (the repo's only `NavigationLink` is `EditEventView.swift:125`, inside a `Form`) |
| `.accessibilityAction` / `.accessibilityActions` | **none anywhere in the repo** — see C14-2 |
| `.refreshable` | none |

**For completeness (not a `List`, same component):** `HistoryCalendarDayDetail.swift:63-69` carries the identical `Button` + `.eventContextMenu` pair inside a `ScrollView`. Same gestures, same semantics, one divergence (no `.padding(.vertical, 10)` — see A7-1).

---

### C12 — Conflicts

#### C12-0 · compliant — **no gesture conflicts exist**

Every C12 sub-check comes back clean, and this is a genuinely good result rather than an absence of investigation:

| C12 check | Finding |
|-----------|---------|
| Custom gesture that can swallow the scroll | **None.** Zero `.gesture(...)`, `.simultaneousGesture`, `.highPriorityGesture`, or `DragGesture` in the repo. Nothing competes with `List`'s scroll recognizer. |
| Custom gesture fighting the swipe recognizer | **N/A** — there is no swipe recognizer; `.swipeActions` is used nowhere. |
| `longPressGesture` where `contextMenu` would be idiomatic | **None.** The app uses `.contextMenu` — the idiomatic API — and does so through one shared `View` extension (`EventContextMenu.swift:24-70`) rather than ad hoc per call site. This is the correct pattern and the correct factoring. |
| `onTapGesture` on a row that also has a `NavigationLink` or `Button` | **None.** All three `List` views wrap row content in a real `Button` with `.contentShape(Rectangle())` and `.buttonStyle(.plain)` — the recommended construction. No overlapping tap handling anywhere. |

#### C12-1 · `nit` · `HistoryDaySectionCard.swift:28-45` vs `HistoryCalendarDayDetail.swift:61-72`

Not a gesture *conflict*, but a gesture-surface **inconsistency**: the same `Button` + `.eventContextMenu` row has a 10pt vertical padding in one copy and not the other (see A7-1), so the two screens present different-sized touch surfaces for the identical interaction. Resolved for free by the A7-1 extraction.

---

### C13 — `swipeActions` review

#### C13-1 · `blocker` · `EventContextMenu.swift:57-65`

```swift
Button(role: .destructive) {
    animatedHistoryChange(reduceMotion: reduceMotion) {
        HealthWriteHooks.remove(event, using: healthService)
        context.delete(event)
        try? context.save()
    }
} label: {
    Label(String(localized: "action.delete"), systemImage: "trash")
}
```
`[VERIFIED: drinkpulse/Features/History/Components/EventContextMenu.swift:57-68]`

C13 asks whether destructive actions carry `role: .destructive` **and a confirmation path.**

- `role: .destructive` — ✅ present at `:57`.
- **Confirmation path — ✗ absent.** Long-press → tap Delete → the record and its HealthKit sample are gone. No confirmation, no undo, no snackbar.

What makes this a blocker rather than a preference is that **the same app already treats this exact operation as requiring confirmation on the other path.** The Edit sheet's delete is gated:

> `@State private var showDeleteConfirmation = false` — `[VERIFIED: drinkpulse/Features/History/EditEventView.swift:12]`
> `showDeleteConfirmation = true` — `[VERIFIED: …:180]`
> `.popover(isPresented: $showDeleteConfirmation) {` — `[VERIFIED: …:186]`

and that gate is pinned by a dedicated UI test whose doc comment describes the contract:

> "The destructive trash button in the Edit sheet's nav bar opens a popover (anchored to the button) carrying a confirm 'Delete' button. This pins the real flow: trash → popover → confirm removes the event and dismisses the sheet; trash → popover → dismiss-without-confirm keeps the event."
> — `[VERIFIED: drinkpulseUITests/Features/History/EditDeleteConfirmationUITests.swift:3-8]`

So: two paths, same irreversible destruction of personal health data, opposite safety postures — and **the unguarded path is the faster, easier-to-trigger one** (long-press + tap, versus tap → sheet → toolbar → popover → confirm). A misplaced long-press followed by a tap on a menu item silently destroys a record.

This also runs against CLAUDE.md's own change-hygiene rule: *"Anything outward-facing or hard to reverse (e.g. pushing, releasing, **deleting user data**…) needs explicit per-action approval"* — and against the privacy/health-data framing that classifies consumption events as sensitive personal health data.

**Concrete fix** — reuse the existing, already-tested pattern rather than inventing a second one. Because `.contextMenu` content cannot itself host a confirmation, hoist the state to the row:

```swift
// in EventRowButton (A7-1), or on the row in HistoryDaySectionCard
@State private var pendingDelete: ConsumptionEvent?
…
.eventContextMenu(for: event, …, onRequestDelete: { pendingDelete = event })
.confirmationDialog(
    String(localized: "history.delete.confirmTitle"),
    isPresented: .init(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
    titleVisibility: .visible
) {
    Button(String(localized: "action.delete"), role: .destructive) {
        guard let event = pendingDelete else { return }
        animatedHistoryChange(reduceMotion: reduceMotion) {
            HealthWriteHooks.remove(event, using: healthService)
            context.delete(event)
            try? context.save()
        }
        pendingDelete = nil
    }
    Button(String(localized: "action.cancel"), role: .cancel) { pendingDelete = nil }
}
```

`eventContextMenu` changes from *performing* the delete to *requesting* it; Duplicate is untouched (it is non-destructive and already saves immediately for the identity reason at `:39-50`).

**Required verification** (CLAUDE.md: user-facing change ⇒ mandatory UI test): a new `drinkpulseUITests/Features/History/ContextMenuDeleteConfirmationUITests.swift` mirroring `EditDeleteConfirmationUITests` — long-press → Delete → confirm removes the row; long-press → Delete → cancel keeps it. Note the disambiguation problem that test file already documents at `:10-13`: several controls expose the English label "Delete", so the confirm button needs a stable accessibility identifier.

**Owner decision required:** confirmation dialog (proposed above, consistent with the Edit sheet) versus undo-based recovery. This is a UX choice, not a mechanical fix — surface it rather than picking silently.

#### C13-2 · N/A — no `swipeActions` exist to review

`.swipeActions` appears **nowhere** in the repo. The only mention is a comment explaining its absence:

> `// TODO(iOS 27): native per-event swipe-to-delete is still not restorable —`
> `// `.swipeActions` is a row-level affordance tied to what List's own ForEach`
> `// treats as a discrete row, and each row here is a whole day (`HistoryDaySectionCard`,`
> `// multiple events), not a single event. Context-menu Delete (`.eventContextMenu`,`
> `// inside HistoryDaySectionCard) stays the sole delete path`
> — `[VERIFIED: drinkpulse/Features/History/HistoryListQueryView.swift:73-79]`

The reasoning is sound: `.swipeActions` scopes to a `List` row, and the current row is one day-card holding N events. Therefore:
- **edge** — N/A (no swipe actions configured)
- **`allowsFullSwipe`** — N/A
- **`role: .destructive`** — N/A for swipe; assessed for the context menu in C13-1
- **confirmation path** — assessed in C13-1

Restoring per-event swipe is filed under **"Later (needs iOS 27)"** per CONTEXT, and is deliberately excluded from the actionable list.

---

### C14 — Accessibility

#### C14-1 · `worth-fixing` · `HistoryDaySectionCard.swift:29-40`

```swift
Button {
    onEditEvent(event)
} label: {
    EventRow(event: event, profile: profile)
        .contentShape(Rectangle())          // ← :33  hit shape pinned to EventRow's frame
}
.buttonStyle(.plain)
.padding(.vertical, 10)                     // ← :40  OUTSIDE the Button
```
`[VERIFIED: drinkpulse/Features/History/Components/HistoryDaySectionCard.swift:29-40]`

The 10pt-top/10pt-bottom padding is applied to the **`Button`**, not to its **label**, and `.contentShape(Rectangle())` has already pinned the interactive shape to `EventRow`'s intrinsic frame *inside* the label. The result: **20pt of every row's height is visually part of the row but is not tappable.** A tap in the gutter between two rows does nothing.

This directly undercuts C14's ≥44pt hit-target requirement. `EventRow` at default Dynamic Type is roughly a `.body` line over a `.caption` line (~40pt), so the padding was carrying the row over the 44pt threshold — except it is inert. The touch target is likely *below* 44pt at default sizes and certainly below it at the smallest.

The padding was added as the fix for BUG 1 in `.planning/debug/resolved/history-scrollview-bugs.md`, whose stated intent was to restore *"the codebase's own established convention for 'items inside a `dpGlassCard`' (`SettingsRow`'s exact padding value)."* It achieved the visual goal and missed the interactive one — an easy thing to miss when verifying by eye.

**Concrete fix:** move the padding inside the label, before `.contentShape`:

```swift
Button {
    onEditEvent(event)
} label: {
    EventRow(event: event, unitContext: unitContext)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
}
.buttonStyle(.plain)
```
Zero visual change; the whole row becomes tappable. Landed naturally by the A7-1 extraction. **Verification:** a UI test asserting a tap near the row's top edge opens the Edit sheet, plus an accessibility-frame height assertion ≥44pt.

#### C14-2 · `worth-fixing` · `EventContextMenu.swift:30-69`

C14 asks: *does every swipe/long-press action have an equivalent `accessibilityAction`?* **`grep -rn "accessibilityAction" drinkpulse/` returns zero hits repo-wide.** So the answer is no, explicitly — the app defines no accessibility actions at all.

Duplicate and Delete are reachable **only** through `.contextMenu`, i.e. only through a long-press. Whether SwiftUI automatically republishes `.contextMenu` items as VoiceOver custom actions is something I could **not** confirm against Apple documentation this session (see Assumptions Log **A1** — the relevant doc pages would not fetch, and the search results covered `accessibilityAction`/rotors generally without stating `contextMenu`'s automatic behavior). It very likely does, via `UIContextMenuInteraction`'s standard accessibility bridging — but "very likely" is not the standard CLAUDE.md sets ("Never guess how to implement an unfamiliar API… or platform mechanic"), and this is the difference between a VoiceOver user being able to delete a drink and not.

Compounding it: `EventRow.swift:48` applies `.accessibilityElement(children: .combine)`, collapsing the row into one element. Combining children can affect how nested interactive affordances are exposed, which is exactly the configuration where an assumption is least safe.

**Concrete fix — two parts:**

1. **Verify, don't assume.** Add a `checkpoint:human-verify` task: run VoiceOver on device, focus a History row, swipe up/down through the Actions rotor, and record whether "Duplicate" and "Delete" are announced. This is the only way to settle it, and it doubles as the first concrete step on STATE.md's outstanding "Accessibility audit (VoiceOver, Dynamic Type up to AX5) — not yet started" blocker.
2. **Add explicit actions regardless.** Cheap, unconditionally correct, and independent of the answer:

```swift
.accessibilityActions {
    Button(String(localized: "action.duplicate")) { … }
    Button(String(localized: "action.delete")) { … }   // routes through C13-1's confirmation
}
```
Belongs on the row in `EventRowButton` (A7-1), sharing the same action closures as the context menu so the two can never drift.

#### C14-3 · `worth-fixing` · `EventRow.swift:15-47`, `HistoryDaySectionCard.swift:43`

C14 asks whether the row survives the largest Dynamic Type sizes (project rule: **up to AX5**). `EventRow` is a rigid three-column `HStack` with hard-coded geometry and no adaptation:

| Line | Code | Problem at AX5 |
|------|------|----------------|
| `:16-18` | `Text(event.icon).font(.title2).frame(width: 36)` | Fixed 36pt frame; a `.title2` emoji at AX5 scales far past 36pt and clips or overflows. |
| `:15` | `HStack(spacing: 12)` with a leading name column and a trailing value column | Three columns of scaled text on one line. The name (`.body`) and the amount (`.body.weight(.medium)`) collide; `Spacer()` at `:37` cannot absorb it. |
| `:43-45` | `Text(alcoholUnit.unitLabel(...)).font(.caption2)` | `.caption2` at AX5 is still large; the trailing `VStack` grows and squeezes the name column further. |
| `HistoryDaySectionCard.swift:43` | `Divider().padding(.leading, 48)` | 48pt hard-codes the icon column (36 frame + 12 spacing). It does not track a scaled icon, so the divider misaligns as type grows. |

No `@ScaledMetric`, no `ViewThatFits`, no `.dynamicTypeSize(...)` cap, and no `AnyLayout` appears anywhere in `EventRow` or its container.

**Concrete fix:**
```swift
@ScaledMetric(relativeTo: .title2) private var iconWidth: Double = 36
@ScaledMetric(relativeTo: .body)   private var dividerInset: Double = 48
@Environment(\.dynamicTypeSize) private var dynamicTypeSize

// :18
.frame(width: iconWidth)

// :15 — swap the layout axis at accessibility sizes
let layout = dynamicTypeSize.isAccessibilitySize
    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
    : AnyLayout(HStackLayout(spacing: 12))
layout { … }
```
and thread `dividerInset` into `HistoryDaySectionCard.swift:43` (or move the divider to an `.overlay(alignment: .bottom)` aligned to the text column, removing the magic number entirely).

**Verification:** `drinkpulseUITests` launched with `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge`, asserting the name and amount labels are both hittable and non-overlapping. That gives an automatable `verification_criteria` line instead of "looks fine at AX5."

#### C14-4 · `worth-fixing` · `GuidelinePickerSheet.swift:26-30`

```swift
if selection == choice {
    Image(systemName: "checkmark")
        .foregroundStyle(.tint)
        .fontWeight(.semibold)
}
```
`[VERIFIED: drinkpulse/Features/Settings/Components/GuidelinePickerSheet.swift:26-30]`

Selection is conveyed **only** by a checkmark glyph. There is no `.accessibilityAddTraits(.isSelected)`, and the image is neither labelled nor `.accessibilityHidden(true)`. A VoiceOver user hears the guideline name, the threshold summary, and — at best — an SF Symbol's default description, with no selected/not-selected state.

The sibling screen does it correctly:

> `.accessibilityAddTraits(selection == choice ? .isSelected : [])`
> — `[VERIFIED: drinkpulse/Features/Onboarding/Components/GuidelineStep.swift:48]`

So this is a one-line omission in one of two near-identical screens — precisely the failure mode A7-2's duplication predicts.

**Concrete fix:** add `.accessibilityAddTraits(selection == choice ? .isSelected : [])` to the Button at `GuidelinePickerSheet.swift:34`, and `.accessibilityHidden(true)` to the checkmark image (the trait now carries the meaning). Permanently fixed by the shared `GuidelineChoiceRow` from A7-2.

#### C14-5 · `nit` · `EventRow.swift:25-30, 59-68`

The row draws a `note.text` glyph when the event has notes, correctly marked `.accessibilityHidden(true)` at `:29` — but `accessibilityLabel` (`:59-68`) never mentions the note. A VoiceOver user has no way to know a note exists on that drink.

**Concrete fix:** append a clause when `event.notes?.isEmpty == false`, e.g. `String(localized: "history.row.hasNote")`. Fold into A4-1's `EventRowStrings` so it is built once and unit-testable.

#### C14-6 · `nit` · `HistoryDaySectionCard.swift:29-35`

The row `Button` has no `accessibilityHint`. VoiceOver announces the combined label plus "Button", but not what activation does (opens the editor). A one-line `.accessibilityHint(String(localized: "history.row.editHint"))` closes it. Low priority; bundle with C14-2 since both land on the same view.

#### C14-7 · manual verification required — contrast

CLAUDE.md requires 4.5:1 for body text and 3:1 for large text. `EventRow` uses `.foregroundStyle(.secondary)` on `.caption`/`.caption2` (`:27`, `:34`, `:45`) over a `.glassEffect(.regular, …)` background (`DPGlass.swift:28` via `HistoryDaySectionCard.swift:50`). Liquid Glass is translucent, so effective contrast depends on what is behind it and on the appearance mode — **it cannot be determined statically and I am not asserting a violation.**

**Concrete fix:** a manual `checkpoint:human-verify` task — Accessibility Inspector's contrast audit on the History list in light and dark, plus with Increase Contrast on. If it fails, the remedy is `.foregroundStyle(.secondary)` → an explicit token meeting the ratio, not a font-size change.

---

# Later (needs iOS 27)

**Excluded from the actionable severity-ranked lists above, per CONTEXT.** Do not raise the deployment target (CLAUDE.md: iOS 26 is non-negotiable). Do not fold these into the plan.

### L1 — Per-event swipe-to-delete inside a multi-event day row

**Source:** `HistoryListQueryView.swift:73-79` (`TODO(iOS 27)`).

**What is blocked:** `.swipeActions` scopes to whatever `List`'s own `ForEach` treats as a discrete row. Today each row is a whole day (`HistoryDaySectionCard`) containing N events, so there is no way to attach a swipe action to one event without making one event = one `List` row.

**Why the workaround is not acceptable today:** flattening to one event per `List` row would reintroduce `List { ForEach(groups) { Section { ForEach(items) { … } } } }`, the structure the `contextmenu-zoom-glitch` session identified as Apple defect **FB11280425** — which defeats `List`'s row-level laziness entirely and was the measured cause of the cold-start hitch that commit `2e0fd4f` fixed. Trading the confirmed hitch back for a swipe affordance is a regression, not a fix.

**⚠️ Unverified API name.** CONTEXT refers to a `swipeActionsContainer()`-style iOS 27 API. **The code's own TODO names no API, and I could not verify that any such API exists** — see Assumptions Log **A2**. What is *needed* is a way to scope a swipe affordance to a sub-element of a `List` row (or to make a nested `ForEach` a first-class row provider without defeating laziness). Whether iOS 27 ships that is unconfirmed. The plan must not cite an API name that has not been verified against Apple documentation.

**Action now:** none. Re-evaluate when iOS 27 documentation is available. Delete-by-context-menu (with C13-1's confirmation added) remains the sole delete path from the list, which is a complete and reachable interaction — not a gap.

---

## Contradictions Found (flagged, not fixed — per CONTEXT `<deferred>`)

CONTEXT and CLAUDE.md both require surfacing doc-vs-code contradictions rather than planning around them. Three were found.

### X1 — `.planning/debug/resolved/history-scrollview-bugs.md` is archived as **resolved** describing a fix that no longer exists

That session's `Resolution.fix` states:

> "BUG 2: (a) replaced `LoadMoreSentinel`'s `.onAppear` with `.onScrollVisibilityChange(threshold: 0)` (iOS 18+, well under this app's iOS 26 min) plus a defensive one-shot latch per visible-transition"
> — `[VERIFIED: .planning/debug/resolved/history-scrollview-bugs.md:162]`, with `files_changed` listing `HistoryListQueryView.swift` at `:170`

**The current code uses `.onAppear`/`.onDisappear`, not `.onScrollVisibilityChange`** — `[VERIFIED: drinkpulse/Features/History/HistoryListQueryView.swift:116-127]`. `grep -rn "onScrollVisibilityChange" drinkpulse/` returns **zero production hits** (only the two explanatory comments at `:104` and `:115`).

The reversal was deliberate and is explained at `HistoryListQueryView.swift:103-115`: the whole container changed from `ScrollView`+`LazyVStack` back to `List` in the later `contextmenu-zoom-glitch` session, and the `LazyVStack` estimated-geometry rationale for `onScrollVisibilityChange` no longer applied. **The code is defensible; the archive is misleading.** A `resolved` session whose recorded fix is absent from the codebase will mislead the next person who greps for it.

**Recommended (out of this phase's scope):** append an Evidence entry to `history-scrollview-bugs.md` noting the container reversal superseded BUG 2's mechanism, cross-linking `contextmenu-zoom-glitch.md`. Do not edit the existing entries (append-only per CLAUDE.md).

### X2 — The `.onAppear` justification comment rests on an unverified mechanism claim

`HistoryListQueryView.swift:106-113` justifies `.onAppear` thus:

> "`List` (iOS 15+) has no such estimate: it is cell-reuse-backed by UICollectionView, which tracks EXACT row frames, not estimates — a dedicated 'loading row' whose `.onAppear` fires the next page is List's own long-standing idiomatic pagination pattern (e.g. tanaschita.com 'How to implement pagination with SwiftUI's List view'; fatbobman.com 'List or LazyVStack')."
> `[VERIFIED: drinkpulse/Features/History/HistoryListQueryView.swift:106-113]`

The **conclusion** (List + a trailing `.onAppear` row is the idiomatic pagination pattern) is well established. The **mechanism** ("cell-reuse-backed by UICollectionView, which tracks EXACT row frames, not estimates") is stated as fact but cites only two third-party blogs. CLAUDE.md is explicit that "Apple's own docs are always the primary source of truth; third-party sources are supplementary, not a substitute."

Counter-signal worth recording: Apple Developer Forums thread 722234, *"List = Row task / onAppear not called"* `[CITED: developer.apple.com/forums/thread/722234]`, surfaced in this session's search for List laziness — indicating `.onAppear` inside `List` is not universally reliable either. That does not mean the current code is wrong; it means the comment overstates the certainty.

Compounding it, `history-scrollview-bugs.md:106-119` records that **the committed UI test cannot reproduce the original race at all** ("reverting ONLY the trigger mechanism … still PASSED"; the later full revert at `:123-138` also passed). So the current `.onAppear` implementation has **no regression net** for the failure mode it replaced.

**Recommended:** soften the comment to claim only what is sourced, and add a `verification_criteria` line requiring a real-device scroll-to-bottom check on the History list when this area is next touched. **Not an action for this audit** — flagged so the plan does not inherit the certainty.

### X3 — `docs/plans/0038-history-list-lazy-scrollview/plan.md` is stale (already known)

Frozen at `in-progress`, still describing `List` → `ScrollView`+`LazyVStack` as the shipped direction; the code reverted to `List` (commit `3093b02`). Already recorded in STATE.md (2026-08-03) and in CONTEXT `<deferred>` as belonging to whoever closes plan-0038. **Confirmed still true; no new information.** Flagged, not fixed.

---

## Findings Summary

| Group | blocker | worth-fixing | nit | compliant / N/A |
|-------|:-------:|:------------:|:---:|:---------------:|
| **A** — List performance | 1 (A1-1) | 6 | 6 | A2, A5, A6-4 |
| **B** — Sections | 0 | 3 | 3 | B9-4, B10-2 |
| **C** — Gestures | 1 (C13-1) | 5 | 3 | C12-0, C13-2 |
| **Later (iOS 27)** | — | — | — | 1 deferred (L1) |
| **Total** | **2** | **14** | **12** | — |

### Recommended execution order (highest leverage first)

| # | Work item | Closes | Rationale |
|---|-----------|--------|-----------|
| 1 | ForEach identity → `\.element.uuid` | **A1-1** | Blocker; one keypath; documented data-loss precedent. Gate on owner approval (identity ≈ sync conflict resolution). |
| 2 | Context-menu Delete confirmation | **C13-1** | Blocker; irreversible health data; reuses the already-tested Edit-sheet pattern. Needs an owner UX decision (dialog vs undo). |
| 3 | Extract `EventRowButton` | **A7-1, C12-1, C14-1, C14-2** | Four findings, one component. Removes the diverged duplicate and fixes the dead-padding hit target. |
| 4 | `DaySection` precompute (`@State` + `onChange`) | **B8-1, A4-2, A6-2, A1-3** | Four findings, one restructure. Biggest per-render win. Watch the midnight-staleness caveat. |
| 5 | `EventRowStrings` precompute | **A4-1, C14-5** | Halves per-row formatting; makes `EventRow` POD; pure ⇒ unit-testable. |
| 6 | `RowUnitContext` value type | **A6-1** | Enables #5's POD benefit; cuts profile-edit fan-out. Do with or right after #5. |
| 7 | Dynamic Type / AX5 hardening | **C14-3** | Standalone; automatable via a content-size-category UI test. |
| 8 | Extract `GuidelineChoiceRow` + `GuidelineChoice.selectable` | **A7-2, A1-2, C14-4, B9-2** | Four findings, one component. Needs an owner call on the canonical checkmark symbol. |
| 9 | Loading state for empty-window-with-more | **B10-1** | Small; user-facing ⇒ needs a UI test. |
| 10 | `historyListRowChrome` modifier | **B9-1** | Cosmetic; do it while touching #9 (which adds a fourth copy otherwise). |
| 11 | `#Index` on `consumptionDate` | **A3-1** | ⚠️ **Own task.** Requires `SchemaV5` + `MigrationStage`. Measure before/after. May be declined outright. |
| 12 | Remaining nits | A2-1, A3-2, A6-3, B8-2, C14-6 | Opportunistic only. |
| 13 | `.insetGrouped` → `dpGlassCard` conversion | **B9-3** | Visual change; owner sign-off; schedule last or defer. |

**Phase-split guidance (CONTEXT gives this to Claude's discretion):** items 1–2 (blockers, both needing owner decisions) form a natural first plan; 3–6 (the extraction + precompute cluster, all touching the same four History files) a second; 7–13 a third. If the planner returns `## PHASE SPLIT RECOMMENDED`, that is the expected shape, not a failure.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest + Swift Testing (`@Test`/`#expect` for new tests, per CLAUDE.md), XCUITest for UI |
| Config file | none — Xcode scheme `drinkpulse`; all three targets are `PBXFileSystemSynchronizedRootGroup`s, so new files in the right folder are auto-included with no `project.pbxproj` edit |
| Quick run command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/HistoryViewModelTests` |
| Full suite command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` (~25 min) |

**Existing coverage in the audited area** (all verified present on disk):
`drinkpulseTests/Features/History/` — `HistoryViewModelTests.swift`, `HistoryViewModelTests+Pagination.swift`, `HistoryViewTests.swift`, `EditEventDeleteTests.swift`, `EditEventVolumeGuardTests.swift`.
`drinkpulseUITests/Features/History/` — `HistoryInteractionUITests.swift` (+`Helpers`, `+Pagination`, `+DirectionalTransition`), `EditDeleteConfirmationUITests.swift`, `DuplicateEditPersistenceUITests.swift`, `EditVolumeIntegrityUITests.swift`, `HistoryUnitDisplayUITests.swift`.

### Findings → Test Map

| Finding | Behavior to pin | Type | Automated command | File exists? |
|---------|-----------------|------|-------------------|--------------|
| A1-1 | Duplicating an event keeps the original row's identity/state across the temp→permanent id flip | UI | `-only-testing:drinkpulseUITests/DuplicateEditPersistenceUITests` | ✅ extend |
| C13-1 | Context-menu Delete: confirm removes, cancel keeps | UI | `-only-testing:drinkpulseUITests/ContextMenuDeleteConfirmationUITests` | ❌ **Wave 0** |
| C14-1 | Tap near a row's top edge opens the editor; row a11y frame ≥ 44pt | UI | `-only-testing:drinkpulseUITests/HistoryInteractionUITests` | ✅ extend |
| C14-2 | VoiceOver actions expose Duplicate + Delete | **manual** | `checkpoint:human-verify` (VoiceOver on device) | ❌ manual — see Assumptions A1 |
| C14-3 | Name + amount labels hittable and non-overlapping at AX5 | UI | `-only-testing:drinkpulseUITests/HistoryDynamicTypeUITests` with `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge` | ❌ **Wave 0** |
| C14-4 | Selected guideline row carries the `.isSelected` trait | UI | `-only-testing:drinkpulseUITests/GuidelinePickerUITests` | ❌ **Wave 0** |
| C14-7 | Contrast ≥ 4.5:1 on `.secondary` captions over glass, light + dark | **manual** | `checkpoint:human-verify` (Accessibility Inspector) | ❌ manual |
| B8-1 / A4-2 | `daySections(_:now:calendar:)` returns correct grouping, order, and Today/Yesterday titles | unit | `-only-testing:drinkpulseTests/HistoryViewModelTests` | ✅ extend |
| B8-2 | `groupedByDay` preserves input order within a day | unit | `-only-testing:drinkpulseTests/HistoryViewModelTests` | ✅ extend (repurpose) |
| A4-1 | `EventRowStrings` yields exact strings for a fixed event × profile matrix | unit | `-only-testing:drinkpulseTests/Features/History/EventRowStringsTests` | ❌ **Wave 0** |
| A6-1 | `RowUnitContext(nil)` yields the documented `.standardDrinks`/`.who`/`.metric` defaults | unit | `-only-testing:drinkpulseTests/Features/History/RowUnitContextTests` | ❌ **Wave 0** |
| B10-1 | Window empty + older data ⇒ loading state, then rows | UI | `-only-testing:drinkpulseUITests/HistoryInteractionUITests+Pagination` | ✅ extend (new fixture) |
| A3-1 | V4→V5 migration opens an existing store without data loss; index present | unit | `-only-testing:drinkpulseTests/Domain/Persistence/MigrationTests` | ❌ **Wave 0** — gated on the schema decision |

### Sampling Rate
- **Per task commit:** scoped `-only-testing:` run over the changed area's class(es) — the project's documented default.
- **Per wave merge:** all History unit + UI classes together (`HistoryViewModelTests`, `HistoryViewTests`, `HistoryInteractionUITests*`, `EditDeleteConfirmationUITests`).
- **Escalate to full suite when:** 3+ test classes are affected, **or** the change touches `Domain/` — which **A1-1** (`ConsumptionEvent` identity), **A3-1** (schema), **A4-1** and **A6-1** (Domain value types) all do. Expect at least one full-suite run per wave in practice.
- **Phase gate:** full suite green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `drinkpulseUITests/Features/History/ContextMenuDeleteConfirmationUITests.swift` — C13-1 (needs a stable `confirmDeleteButton`-style identifier; see the label-collision note in `EditDeleteConfirmationUITests.swift:10-13`)
- [ ] `drinkpulseUITests/Features/History/HistoryDynamicTypeUITests.swift` — C14-3
- [ ] `drinkpulseUITests/Features/Settings/GuidelinePickerUITests.swift` — C14-4
- [ ] `drinkpulseTests/Features/History/EventRowStringsTests.swift` — A4-1
- [ ] `drinkpulseTests/Features/History/RowUnitContextTests.swift` — A6-1
- [ ] `drinkpulseTests/Domain/Persistence/MigrationTests.swift` — A3-1 (only if the schema bump is approved)
- [ ] A UI-test fixture seeding events **outside** the 7-day window with none inside — B10-1
- [ ] Two `checkpoint:human-verify` tasks — C14-2 (VoiceOver rotor) and C14-7 (contrast)

*No framework install needed; all targets and both test schemes already exist.*

---

## Security Domain

`security_enforcement: true`, `security_asvs_level: 1` (`.planning/config.json`). This phase writes no code, but the fixes it proposes touch personal health data, so the categories are assessed against the *proposed* changes.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|:-------:|-----------------|
| V2 Authentication | no | No accounts; CLAUDE.md lists login/account systems as out of scope. |
| V3 Session Management | no | No sessions; offline-first, no backend. |
| V4 Access Control | no | Single-user on-device app; iOS app-container isolation + SwiftData file-protection defaults. |
| V5 Input Validation | **yes** | No new user input is introduced. C13-1's confirmation dialog takes no free text. B10-1's loading copy is a static localized string. Existing validators (`EditEventVolumeGuardTests`) unaffected. |
| V6 Cryptography | no | No crypto is written or configured; nothing hand-rolled. |
| V7 Error Handling & Logging | **yes** | **Highest-relevance category here** — see below. |
| V8 Data Protection | **yes** | C13-1 *strengthens* it: it adds a confirmation gate in front of an irreversible deletion of health data. A1-1 touches record identity, which underpins CloudKit LWW de-dup — the fix uses the existing `uuid` (the CloudKit-safe key), so no regression. Nothing is written outside the app container; no export path is touched. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation | Status in this audit |
|---------|--------|--------------------|----------------------|
| PII / health data in logs | Information Disclosure | `os.Logger` with `privacy: .private`; never log values | ⚠️ **Pre-existing issue confirmed** — `HistoryView.swift:232-234` logs `listWindowStart` with `privacy: .public`. It is a window boundary, not a logged drink, and the whole block is `#if DEBUG`-gated (`:231`, `:235`), so it never ships. But a date bound derived from `.now` at app-open is weakly behavioral. **Not a finding in scope** (not a `List` view, not one of the 18 checks) — recorded here because the security section is where it belongs. Same pattern, same gating, at `EventContextMenu.swift:31-33`. |
| Accidental irreversible destruction of health data | Denial of Service (availability of the user's own data) | Confirmation and/or undo before destructive actions | ❌ **This is C13-1** — the blocker. |
| Unintended network egress | Information Disclosure | On-device only; no URL requests, no third-party SDKs | ✅ No finding proposes a dependency, network call, or SDK. Verified: nothing in this report adds an import beyond SwiftUI/SwiftData/OSLog. |
| Schema amendment causing store recovery (data moved aside) | Denial of Service | New `VersionedSchema` + `MigrationStage`, never an in-place edit | ⚠️ **A3-1 is exactly this risk.** Called out as a hard gate; must not be executed as a line edit. |
| Test hooks leaking into production | Tampering | Launch-argument-gated, never seeds real PII | ✅ Existing `UITestSeed` is launch-argument gated (`-dp_uitest`). New Wave 0 fixtures must follow the same pattern per CLAUDE.md. |

**No package installs.** This phase and its proposed fixes add zero external dependencies, so the Package Legitimacy Audit is not applicable — every fix uses first-party SwiftUI/SwiftData/Foundation APIs already imported by the files in question.

---

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|------------|:---------:|---------|----------|
| Xcode / `xcodebuild` | build + test gates | ✓ | Xcode 26 toolchain (iOS 26 SDK) | — |
| iPhone 17 Pro simulator | the project's documented `-destination` | ✓ | iOS 26 | any iOS 26 simulator |
| `swiftui-expert-skill` | CLAUDE.md-mandated consult | ✓ | v4.0.0 (`~/.claude/plugins/cache/swiftui-expert-skill/swiftui-expert/4.0.0/`) | — |
| Physical iPhone | C14-2 VoiceOver rotor check | ? | — | Simulator VoiceOver is a weaker signal; prefer device |
| Accessibility Inspector | C14-7 contrast audit | ✓ | bundled with Xcode | — |
| Network / third-party SDKs | — | N/A | — | Forbidden by CLAUDE.md |

**No missing dependency blocks execution.** The only uncertainty is real-hardware availability for the two manual accessibility checkpoints; both can start in the Simulator and be confirmed on device at the phase's human-verify gate.

---

## Assumptions Log

Claims below are **not** verified against a primary source this session and must be confirmed before being treated as fact.

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| **A1** | SwiftUI's `.contextMenu` automatically republishes its menu items as VoiceOver custom actions, so Duplicate/Delete are already reachable without a long-press. Apple doc pages would not fetch this session; the searches returned general `accessibilityAction`/rotor material without stating `contextMenu`'s automatic behavior. `EventRow.swift:48`'s `.accessibilityElement(children: .combine)` makes the configuration less predictable. | C14-2 | If false, VoiceOver users **cannot delete or duplicate a drink at all** — a hard functional gap, not a polish item. C14-2's fix deliberately adds explicit `.accessibilityActions` so the outcome is correct either way, plus a human-verify checkpoint to settle it. |
| **A2** | An iOS-27 API exists (CONTEXT calls it `swipeActionsContainer()`) that would let a swipe affordance be scoped to a sub-element of a `List` row. **The code's own TODO names no API**, and no such API was verified. | Later / L1 | If no such API ships, per-event swipe stays permanently unavailable under the current row shape, and any plan citing the name would be citing something that does not exist. L1 therefore describes the *capability* needed, not an API name. |
| **A3** | `.listRowSeparator` / `.listRowBackground` applied to a `List` container propagate to every row under `.plain` style. Unverified. | B9-1 | If false, hoisting them to the container silently stops hiding separators/backgrounds. B9-1's recommended fix is a `ViewModifier` precisely to avoid depending on this; the container-level form is explicitly marked as needing an on-device check first. |
| **A4** | `Enumerated`'s conditional `RandomAccessCollection` conformance (Swift 6.1+) is available to this project, so `Array(...)` can be dropped. The project sets `SWIFT_VERSION = 6.0` (language mode, not toolchain). | A1-3 | If false, the change simply fails to compile — caught immediately at build, zero runtime risk. Marked as "verify it compiles, else close as N/A." |
| **A5** | `Dictionary(grouping:)` preserves the relative order of elements within each group for an ordered input, making `groupedByDay`'s per-group re-sort redundant. Widely relied upon, not confirmed against the Swift stdlib documentation this session. | B8-2 | If false, removing the sort would render each day's drinks in arbitrary order. B8-2 is already ranked a marginal nit and is explicitly conditioned on keeping a unit test that feeds unsorted input. |

---

## Open Questions

1. **Confirmation vs. undo for context-menu Delete (C13-1).**
   - Known: the Edit sheet uses a confirmation popover, pinned by `EditDeleteConfirmationUITests`.
   - Unclear: whether the owner wants the context menu to match that, or prefers a lighter undo/snackbar so the fast path stays fast.
   - Recommendation: propose the confirmation dialog (consistent with the existing, already-tested pattern) and get an explicit yes before implementing. CLAUDE.md requires per-action approval for deleting user data.

2. **Is a schema version bump acceptable for a performance-only change (A3-1)?**
   - Known: `#Index` needs `SchemaV5` + a `MigrationStage`; the current working set (7 days) is small.
   - Unclear: whether the owner accepts migration risk for a win that is currently modest and grows with history length.
   - Recommendation: measure first (`OSSignposter` around the fetch, or `ViewLoadLogger`), decide second. Accepting-and-deferring is a legitimate outcome.

3. **Canonical checkmark for the guideline row (A7-2).**
   - Known: `GuidelinePickerSheet` uses `"checkmark"` + `.semibold`; `GuidelineStep` uses `"checkmark.circle.fill"`.
   - Unclear: which is intended.
   - Recommendation: owner picks one before the shared row is extracted — it is a visible design decision, not a refactor detail.

4. **Should `Form`-based screens get the same audit (out of scope here)?**
   - Known: `Form` renders as a grouped list on iOS; `CustomNameSuggestionSection.swift:11` holds an unbounded `@Query(filter: #Predicate<ConsumptionEvent> { $0.customName != nil })`.
   - Unclear: whether the owner considers `Form` in scope for a follow-up.
   - Recommendation: propose a small follow-up phase. CONTEXT forbids widening this one ("do not add checks beyond them").

---

## Sources

### Primary (HIGH confidence — read first-hand this session)
- **The codebase itself** — every file cited with a `file:line` reference was opened with `Read` this session; every discrete value quoted is verbatim from the line range given.
- `.planning/phases/07-swiftui-list-performance-gesture-audit/07-CONTEXT.md` — the 18-point checklist, reproduced verbatim in `<user_constraints>`.
- `CLAUDE.md` — architecture, schema-migration, accessibility, testing, and privacy constraints.
- `.planning/debug/resolved/history-scrollview-bugs.md` — BUG 1 (row padding) and BUG 2 (pagination trigger) root causes; the recorded UI-test limitation.
- `.planning/debug/contextmenu-zoom-glitch.md` — the `List` re-scope decision, the FB11280425 research trail, and the geometry analysis.
- `swiftui-expert-skill` v4.0.0 — `references/list-patterns.md`, `references/performance-patterns.md` (consulted per CLAUDE.md's mandate).

### Secondary (MEDIUM confidence — search-result summaries; the full doc pages would not fetch)
- ["Demystify SwiftUI performance" — WWDC23 session 10160](https://developer.apple.com/videos/play/wwdc2023/10160/) — constant vs. non-constant view counts per `ForEach` element; eager iteration when the count is dynamic.
- ["Demystify SwiftUI" — WWDC21 session 10022](https://developer.apple.com/videos/play/wwdc2021/10022/) — implicit vs. explicit identity; `ForEach` identity semantics.
- ["What's new in SwiftData" — WWDC24 session 10137](https://developer.apple.com/videos/play/wwdc2024/10137/) — `#Index` introduction and its filtering/sorting benefit.
- [`Index(_:)` — SwiftData](https://developer.apple.com/documentation/swiftdata/index(_:)-74ia2) — the macro's formal definition.
- ["Dive into lazy stacks and scrolling with SwiftUI" — WWDC26 session 321](https://developer.apple.com/videos/play/wwdc2026/321/) — `LazyVStack` estimated content geometry (the basis of the superseded `onScrollVisibilityChange` rationale).
- ["Understanding and improving SwiftUI performance"](https://developer.apple.com/documentation/Xcode/understanding-and-improving-swiftui-performance) — referenced; body would not fetch.
- [`accessibilityAction(_:_:)`](https://developer.apple.com/documentation/swiftui/view/accessibilityaction(_:_:)) / [`accessibilityActions(category:_:)`](https://developer.apple.com/documentation/swiftui/view/accessibilityactions(category:_:)) — the API surface for C14-2's fix.
- ["Catch up on accessibility in SwiftUI" — WWDC24 session 10073](https://developer.apple.com/videos/play/wwdc2024/10073/) — general accessibility-action guidance.
- [Apple Developer Forums thread 722234 — "List = Row task / onAppear not called"](https://developer.apple.com/forums/thread/722234) — counter-signal cited in X2.
- [`PersistentIdentifier` — SwiftData](https://developer.apple.com/documentation/swiftdata/persistentidentifier) — referenced; body would not fetch.

### Tertiary (LOW confidence — corroborating only, not load-bearing)
- [Michael Tsai — "NSManagedObjectID and PersistentIdentifier"](https://mjtsai.com/blog/2024/09/27/nsmanagedobjectid-and-persistentidentifier/) and [fatbobman — "Mastering Data Identifiers in Core Data and SwiftData"](https://fatbobman.com/en/posts/nsmanagedobjectid-and-persistentidentifier/) — corroborate the temporary→permanent `PersistentIdentifier` flip behind **A1-1**. A1-1's primary evidence is this repo's own `EventContextMenu.swift:39-50` and the `sheet-closes-reopens-loses-state` debug session, not these.
- [useyourloaf — "SwiftData Fetching An Existing Object"](https://useyourloaf.com/blog/swiftdata-fetching-an-existing-object/) — same corroboration.

---

## Metadata

**Confidence breakdown:**
- **View inventory:** HIGH — exhaustive `grep` over `drinkpulse/` for `List`, then a widened `\bList\b` sweep, then `Form`; every hit opened and read. 3 production `List` views + 1 preview.
- **Code-level findings (`file:line`, severities, fixes):** HIGH — every claim traces to a line range read this session, with discrete values quoted verbatim.
- **Framework-mechanism attributions:** MEDIUM — Apple doc *pages* would not fetch through `WebFetch`; the WWDC-session claims rest on search-result summaries plus the `swiftui-expert-skill` references. The specific behaviors relied on are well-established and cross-checked against two independent sources each.
- **Accessibility findings:** MEDIUM for the code-level ones (C14-1, C14-3, C14-4, C14-5 — all directly readable); LOW for C14-2's `contextMenu`-auto-exposure question (Assumptions A1) and C14-7's contrast (not statically determinable). Both are routed to human-verify checkpoints rather than asserted.
- **Gesture inventory (C11):** HIGH — the greps returned so few hits repo-wide that the table is provably exhaustive rather than sampled.

**Research date:** 2026-08-03
**Valid until:** ~2026-09-02 (30 days). Re-verify sooner if the History feature is touched, if plan-0038 is formally closed, or if iOS 27 documentation lands (invalidates the L1 assumption).
