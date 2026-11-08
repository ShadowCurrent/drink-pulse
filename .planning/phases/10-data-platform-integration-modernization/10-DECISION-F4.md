# F4 — Weekly summary notification copy versus delivery-time staleness

**Status:** awaiting owner decision — no copy change started
**Proposed destination:** Phase 10, plan 10-10 (copy application, gated on this record)

## Current behavior

`drinkpulse/Services/WeeklySummaryService.swift` `scheduleIfEnabled(context:now:calendar:)` reads the opt-in flag, then computes two completed-week ranges with `InsightsPeriod.week.dateRange(offset:now:calendar:)` (`drinkpulse/Features/Insights/InsightsPeriod.swift`): offset -1 ("last week", the week before the week containing `now`) and offset -2 ("the week before last"). It sums `pureAlcoholGrams` per range, asks `WeeklySummaryCalculator.content(currentWeekGrams:priorWeekGrams:hasAnyPriorWeekData:)` for the content, builds the request with `makeRequest(calendar:content:)` and replaces the pending request. `makeRequest` creates a repeating `UNCalendarNotificationTrigger` on `calendar.firstWeekday` at 09:00 with a static body resolved when the request is built. Content `.skip` cancels the pending request instead.

The five current strings (English only, `drinkpulse/Localizable.xcstrings`, keys `weeklySummary.notification.body.*`), verbatim:

- `directionOnlySame`: "No alcohol logged again this week."
- `directionOnlyUp`: "You logged a drink this week — none last week."
- `down`: "You drank %d%% less than last week."
- `same`: "About the same as last week."
- `up`: "You drank %d%% more than last week."

**The staleness (finding F4).** The body is built when the app was last foregrounded and delivered at the next occurrence of the week start at 09:00, a week boundary later, with the text frozen at build time. Worked example for a Monday-first calendar and a foreground on Wednesday 2026-11-04:

- Baked comparison at foreground time: last week = Oct 26 to Nov 1, the week before = Oct 19 to 25.
- Delivery: Monday 2026-11-09 09:00. At that moment "last week" is Nov 2 to 8, so a notification that says "last week" describes Oct 26 to Nov 1 and the reader will take it to mean Nov 2 to 8.
- If the app is not opened again before delivery (the common case), the comparison is one week behind what the words claim.

This is pinned by the characterization test `WeeklySummaryCompletedWeekTests.f4_bakedComparisonIsOneWeekBehindAtTheNextDelivery` (plan 10-04, Task 1): at the next delivery date the last-week range differs from the one used at scheduling time and equals the week containing the scheduling time, and the baked body differs from what a delivery-time comparison would produce. The boundary tests in the same suite pin the completed-week comparison itself (Wednesday, Sunday 23:30 and Monday 00:30, Monday-first and Sunday-first calendars), so the comparison is correct; only the wording-versus-delivery-time relationship is the issue.

In every option below `WeeklySummaryCalculator` and the plus or minus 5 percent band stay unchanged, copy stays English only, and the existing placeholders stay (a percent `%d` in `down` and `up`, none in the other three). The Polish wording in the folded todo (`2026-09-15-clarify-weekly-alcohol-summary-comparison.md`) does not apply, because the app is English only.

**Accuracy rule.** Every candidate string must be true under the delivery-staleness semantic, and D-16 requires every variant to name both compared periods using the existing placeholders. Where an option cannot satisfy the first half, this brief says so plainly.

## Source-backed decision table

**Availability:** The iOS 27 minimum covers `UNCalendarNotificationTrigger` and `UNMutableNotificationContent`; no replacement or deprecation is claimed, and none is inferred from age.

| Topic | as-of-last-visit (recommended) | d16-as-written | d16-then-refresh |
| --- | --- | --- | --- |
| Official source | See the source note below the table. | Same. | Same. |
| Proposed behavior | down: "As of your last visit, your latest completed week had %d%% less alcohol than the week before it."; up: "As of your last visit, your latest completed week had %d%% more alcohol than the week before it."; same: "As of your last visit, your latest completed week had about the same alcohol as the week before it."; directionOnlyUp: "As of your last visit, you logged alcohol in your latest completed week but none the week before it."; directionOnlySame: "As of your last visit, you logged no alcohol in your latest completed week or the week before it." | down: "Last week you drank %d%% less alcohol than the week before."; up: "Last week you drank %d%% more alcohol than the week before."; same: "Last week you drank about the same amount of alcohol as the week before."; directionOnlyUp: "Last week you logged alcohol; the week before you logged none."; directionOnlySame: "You logged no alcohol last week or the week before." | The same five d16-as-written strings are applied by plan 10-10, and a follow-up is commissioned to refresh the scheduled weekly content closer to delivery (for example re-scheduling when the app moves to the background, or on a background refresh). |
| Benefit | Names both periods, keeps the placeholders, and is true at delivery because both periods are anchored to the last foreground, which is when the calculator compared them. | Exactly the D-16 example family; short and natural; names both periods with the existing placeholders. | The only route that makes the D-16 wording true at delivery. |
| Cost | Longer, less punchy text; the lock-screen preview is more likely to truncate. | Inaccurate in the common delivery case (see Alternatives). | Same interim inaccuracy as d16-as-written until the follow-up ships, plus a future scheduling-lifecycle brief and its implementation. |
| Alternatives | The two other offered options, or owner-edited wording under the same rules. | Fails D-16's own verification clause (the wording must match the periods the calculator compares) in the common delivery case: at delivery "last week" is one week later than the week the calculator compared. The owner must accept that inaccuracy explicitly to pick it. | The refresh is a scheduling-lifecycle change, so it needs its own owner brief (Phase 08 D-09) and is not designed, coded or tested in this phase. The copy is still applied now because D-16 is locked and requires this phase to change the copy; deferring the copy until the refresh lands would be retain-current in effect, which is excluded below. The owner accepts the interim inaccuracy explicitly to pick it, and plan 10-10 also records the follow-up as a pending todo. |
| Compatibility | Calculator, band, placeholders, trigger, identifier and opt-in flow unchanged. | Same. | Same in this phase. |
| Data / accessibility / lifecycle risk | No data, schema or lifecycle change. Longer text is read in full by VoiceOver; truncation risk applies only to the visual preview. | No data change; a wrong health statement about the period shown to the user (threat T-10-09). | No data change in this phase; the follow-up would change notification scheduling lifecycle and needs its own brief. |

**Source note.** The notification content being fixed when the request is created, and the trigger repeating with that frozen content, are documented behaviors of `UNNotificationRequest`, `UNMutableNotificationContent` and `UNCalendarNotificationTrigger` (https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger). This executor had no Xcode MCP `DocumentationSearch` and no web access in its environment, so that page was not fetched for this brief and the statement is not source-verified by it. The decision rests on evidence that does not need the page: the production code in `WeeklySummaryService.swift` and the passing characterization test named above. Before the owner relies on the Apple wording, confirm the page via Xcode MCP DocumentationSearch (or developer.apple.com as fallback).

## D-16 compliance check

| Option | Names both compared periods | Existing placeholders only | Matches the periods the calculator compares at delivery | English only | Calculator and band unchanged |
| --- | --- | --- | --- | --- | --- |
| as-of-last-visit | yes | yes | yes | yes | yes |
| d16-as-written | yes | yes | no | yes | yes |
| d16-then-refresh | yes | yes | no in this phase, yes only after the follow-up refresh lands | yes | yes |

## Excluded by D-16

Not offered, because each contradicts locked D-16 (10-CONTEXT.md):

- retain-current: keeps today's copy, which contradicts the copy change D-16 requires. This also covers holding the copy back until a refresh lands.
- concrete-dates: names the weeks by date and needs a date placeholder, which D-16 forbids by keeping the existing placeholders.

Picking either requires the owner to amend D-16 in 10-CONTEXT.md first. This phase applies neither under the current D-16.

Out of scope for this phase: the refresh implementation itself (logic and lifecycle change). It is reachable only through the d16-then-refresh option's follow-up and would need its own brief.

## Recommendation and proposed scope

Recommend as-of-last-visit: it is the only offered wording that is true at delivery without a scheduling-lifecycle change, it satisfies every D-16 requirement and it leaves the calculator, band and placeholders untouched. Proposed scope for plan 10-10: replace the five `weeklySummary.notification.body.*` values in `drinkpulse/Localizable.xcstrings` with the owner's final strings, add explicit-wording assertions, and change no logic.

## Owner decision record

Allowed outcomes: as-of-last-visit, d16-as-written, d16-then-refresh, or custom D-16-compliant wording (every variant names both compared periods using the existing placeholders).

**Outcome:** pending
**Decision date:** pending
**Exact scope:** pending (the final five strings go here)
**Owner reason:** pending
