# 0043 — Retrospective

**Completed**: 2026-11-20

## What went well
- The `Form` cut the Settings UI to small section views; five custom components and the guideline
  sheet are gone, and every setting, service call and presentation kept its behaviour (63 / 63
  scoped tests green).
- Moving the "touch only on change" binding into a tested `UserProfile` extension pinned the LWW
  contract before any view changed.
- Writing the Task 4 tests early kept the delete-all alert pinned through the move of its
  presentation modifier.

## What went wrong / surprises
- System `Form` text is not audit-clean on the Frost tint: grey headers and picker values are
  about 3.2–3.4:1 in Light. Fixed with the existing `dpSecondaryText`, which step 11 must now keep.
- A conditional style modifier on a whole `Section` made the audit report `dynamicType` on every
  picker label; on each `Picker` it does not. Not documented by Apple; found by comparing the
  clean Sex picker.
- `.navigationLink` pickers at AX5 draw audit findings on labels that render fine; exempted
  provisionally.
- XCUITest needed `Form`-specific handling: lazy rows, `Link` not a button, `Toggle` rows tapped
  on the label.

## Decisions made during execution
- See `execution.md` "Deviations from plan".

## Leftover open questions
- Owner decision on the AX5 picker-label exemption (open-questions).
- A design-system name for the contrast-safe secondary ink before step 11 (open-questions).
- `HistorySearchUITests` isolation warnings (open-questions).
- Owner device check (plan "Device check").
