# Current Focus

_Update this file at the end of every session._

## Status: plan-0038 in-progress — History list List → ScrollView+LazyVStack (2026-08-02)

v1.3 "Native Feel" milestone shipped 2026-07-31 (Phases 4-6, archived to
`.planning/milestones/v1.3-*`). No GSD milestone currently active.

Working outside GSD tracking on pre-GSD plan **0038**
(`docs/plans/0038-history-list-lazy-scrollview/`): replaces
`HistoryListQueryView`'s `List(.insetGrouped)` with `ScrollView` +
`LazyVStack`, fixing a confirmed cold-start hitch — `List`+`ForEach`
eagerly evaluates every row's body and `.contextMenu` content for the
entire loaded window on every render, not just visible rows (confirmed via
device Console logs). New `HistoryDaySectionCard` component (day title +
`dpGlassCard`, mirrors `SettingsSection`/`SettingsRow` from plan-0027).
Native `.swipeActions` dropped (needs `List` row context or
`swipeActionsContainer()`, iOS-27-only; app min deployment is iOS 26) —
context-menu Delete is the sole delete path until iOS 27, tracked in
`open-questions.md`.

**Done this session**: steps 1-6, 9-10 of the plan. Build clean/zero
warnings; scoped History UI suite 16/16 green (found and fixed one
pre-existing test relying on a `List`-only `.collectionViews` accessibility
element — see `docs/DEVLOG.md` 2026-08-02 entry and
`docs/plans/0038-history-list-lazy-scrollview/execution.md`).

**Outstanding — next session should start here**: plan step 7, manual
real-hardware verification (cold-install hitch feel, day-card/row
insert-delete-duplicate animation feel) — not automatable, requires a
human on a physical device. Once that passes: step 8 removes the two
remaining first-session diagnostic loggers (`extendListWindow`, row-tap —
row-tap already folded away during the `HistoryDaySectionCard` extraction,
so only `extendListWindow` remains). Plan stays `in-progress` until then;
close it out (`docs/DEVLOG.md`, `docs/plans/INDEX.md` → completed,
`retrospective.md`) once verified.
