# 0026 — Retrospective

**Completed**: 2026-06-15

## What went well
- Small, additive change with a clean seam: a single `View` modifier
  (`eventContextMenu(for:in:)`) reused verbatim in both History surfaces, so the
  list and calendar-detail stay in sync with zero duplicated menu logic.
- The domain `duplicated()` helper kept the copy logic testable (5 tests, 100%
  on the new code) and out of the view layer.
- "Save immediately, no edit sheet" matched the user's intent (fast re-log) and
  needed no new navigation state — the duplicate just appears under "Today".

## What was tricky
- Test-target compile: Swift Testing file had no implicit `Foundation`, so `Date`
  was unresolved; `DrinkTemplate.init` needs `colorHex`. Both fixed quickly.
- SourceKit reported a flood of "cannot find type in scope" false positives
  (whole-module symbols) mid-edit; the real signal was `xcodebuild`.

## Decisions (and rejected alternatives)
- **Immediate save** over opening Add/Edit pre-filled — the latter is almost
  normal add-drink and defeats the speed gain. Edit is still one tap away.
- **Keep the `template` reference** on the duplicate (same drink); relationship
  `deleteRule: .nullify` covers later template deletion.
- **Long-press only**, no leading duplicate swipe action — matched the request
  and avoided crowding the existing trailing swipe-to-delete.

## Follow-ups
- None required. Possible nicety: a leading-swipe Duplicate shortcut on the list
  if the long-press proves too hidden in use.
