# 0013 — History calendar view with clickable days

**Status**: draft
**Size**: medium
**Created**: 2026-05-19

## Summary

Add a Calendar segment alongside the existing List view in History.
- Month-grid layout with `←` / `→` navigation; the prev arrow disables
  at the earliest tracked month and the next arrow disables when on the
  current month.
- Days are colour-coded against the daily limit (low / moderate / high)
  with future days dimmed.
- Tapping a day expands a "Day detail" panel below the grid showing the
  events for that day. Tapping an event opens the existing
  `EditEventView` sheet. Days with no events show a sober-day placeholder.

## Context

The Claude Design handoff (2026-05-19) shows the calendar as a primary
History view. The open question in `.claude/context/open-questions.md`
captured the colour-threshold decision; the user confirmed in the
transcript that days are coloured relative to *daily* limit, and any
"safe" wording should switch to "Low Risk" — see [[plan-0015]].

Currently `HistoryView` only has the list view.

## Scope

### In
- `Features/History/Components/HistoryCalendarView.swift` — month grid +
  navigation + clickable cells + inline day detail.
- `Features/History/HistorySegment.swift` — `enum HistorySegment { case
  list, calendar }`; state stored in `HistoryView`.
- `Features/History/HistoryViewModel.swift` — replaces inline grouping
  computation in `HistoryView`. Inputs `events`, `profile`, `now`.
  Outputs:
  - `monthCells(year:month:) -> [DayCell]`
  - `events(on day: Date) -> [ConsumptionEvent]`
  - `gramsByDay(year:month:) -> [Date: Double]`
  - `riskColor(forGrams: Double, dailyLimit: Double) -> Color`
- Toggle UI atop History — segmented "📅 Calendar / 📋 List".
- Bounds: prev/next arrows guarded by earliest event month and current
  month.

### Out
- Heatmap-like opacity scaling — calendar uses discrete low/moderate/high.
- Multi-month "year view" — explicit out.
- Edit-from-day-detail beyond opening `EditEventView` (no inline edit).
- Calendar export.

## Implementation steps

1. **`HistoryViewModel`** — extract grouping logic from `HistoryView`
   so calendar derivations can share it.
2. **`HistoryCalendarView`** — pure view; bindings:
   `monthShown: Date`, `selectedDay: Date?`, `onSelect:`, `onEditEvent:`.
3. **`DayCell`** — view: rounded square, theme-tinted today highlight,
   risk-coloured fill for non-zero days, dimmed future. Cell is a
   `Button` for VoiceOver.
4. **Tap behaviour** — toggling the same day deselects.
5. **Day detail panel** — placed below the grid inside the same
   `GlassCard`; shows date, total grams (formatted via active
   `AlcoholUnit`), then a list of rows mirroring the existing `EventRow`.
6. **Empty-state** — when `selectedDay` has no events: 🌙 "Sober day — no
   drinks recorded".
7. **Bounds**:
   - `canGoPrev = earliest event month exists and `monthShown` > earliest`.
   - `canGoNext = monthShown < currentMonth`.
8. **Tests** — `HistoryViewModelTests`:
   - `monthCells(May 2026)` returns 31 entries with correct `dayOfWeek`
     offset.
   - `gramsByDay` sums correctly for multi-event days.
   - `riskColor` boundaries at 0%, 50%, 100% of daily limit.
9. **Toolbar / FAB** — remove the History toolbar `+` (replaced by FAB —
   see [[plan-0010]]).

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/History/Components/HistoryCalendarView.swift` | Create |
| `drinkpulse/Features/History/Components/HistoryCalendarDayCell.swift` | Create |
| `drinkpulse/Features/History/Components/HistoryCalendarDayDetail.swift` | Create |
| `drinkpulse/Features/History/HistorySegment.swift` | Create |
| `drinkpulse/Features/History/HistoryViewModel.swift` | Create |
| `drinkpulse/Features/History/HistoryView.swift` | Modify (segment + bind VM) |
| `drinkpulseTests/HistoryViewModelTests.swift` | Create |
| `drinkpulse/Localizable.xcstrings` | Append keys |

## Open questions

- [ ] **Q1 — Colour thresholds** (resolves the open-question doc):
  - A) Green < 50%, orange 50–100%, red > 100% of daily limit (default)
  - B) Green < 80%, orange 80–100%, red > 100%
  - The transcript hinted at A by re-using the same thresholds as
    `ConsumptionOverviewCard`.

- [ ] **Q2 — Default segment**: open History on Calendar or List?
  - A) List (default — matches today's behaviour; less surprising)
  - B) Calendar (matches design's emphasis on calendar)

- [ ] **Q3 — Future days**: dim with no fill, or fill grey?
  - A) Dim with neutral fill (default — matches design)

- [ ] **Q4 — First weekday**: locale-aware (`Calendar.firstWeekday`) or
  Sun-first (matches design)?
  - A) Locale-aware (default — correct for European users)
  - B) Sun-first (matches design)

## Tests required

- Threshold boundaries, day-of-week offset, multi-event sum.
- VM tests do not require SwiftData; pass `[ConsumptionEvent]` directly.

## Future links

- [[plan-0007]] — glass card.
- [[plan-0014]] — clicking an event in the detail opens edit sheet.
- [[plan-0015]] — legend reads "Low / Moderate / High Risk".
