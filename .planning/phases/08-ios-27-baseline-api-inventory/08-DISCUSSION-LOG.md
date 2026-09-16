# Phase 08: iOS 27 Baseline & API Inventory - Discussion Log

> **Audit trail only.** Downstream agents use `08-CONTEXT.md`; this log records alternatives discussed.

**Date:** 2026-09-16  
**Areas discussed:** Baseline evidence, Inventory detail, Rewrite decision gate, Living documentation, Swift 6.4 scope

## Folded todo

The owner selected the pending “Migrate project to iOS 27 and modernize codebase” todo for inclusion. Other matched todos were not folded because they concern GSD branching, completed notification startup work, or future autocomplete behavior.

## Baseline evidence

| Question | Options presented | Owner selected |
|---|---|---|
| Baseline run | iOS 27 simulator build and tests; simulator plus real device; builds only | iOS 27 simulator build and tests |
| Test breadth | Full unit and UI suite; unit plus selected UI flows; selected tests only | Full unit and UI suite |
| Failed baseline | Record and classify; fix in Phase 08; stop at blocker | Record and classify; carry fixes to relevant later phase |
| Evidence retained | Summary plus raw logs; summary only; raw logs only | Summary plus raw logs |

## Inventory detail

| Question | Options presented | Owner selected |
|---|---|---|
| Entry granularity | Distinct API or pattern with all source locations; one per location; one per feature area | Distinct API or pattern with all source locations |
| No-change coverage | Explicit area row; coverage checklist; candidates only | Explicit area row |
| Uncertain workaround | Retain pending evidence; externally blocked; change candidate | Retain pending evidence |
| Later-phase handoff | Priority and destination; destination only; flat inventory | Priority and destination |

## Rewrite decision gate

| Question | Options presented | Owner selected |
|---|---|---|
| Substantial threshold | Behavior or data risk; code size; every API replacement | Behavior or data risk |
| Multiple candidates | Separate brief per candidate; one combined brief; briefs by feature area | Separate brief per candidate |
| Review outcome | Approve, retain, or defer; approve or reject; priority only | Approve, retain, or defer |
| Later discovery | Pause affected rewrite; pause whole phase; finish phase then review | Pause affected rewrite; continue unrelated approved work |

## Living documentation

| Question | Options presented | Owner selected |
|---|---|---|
| Toolchain instructions | Existing README/CLAUDE entry points; new platform guide; phase artifacts only | Existing entry points, linked to Phase 08 report |
| Inventory and briefs | Phase artifacts; permanent docs inventory; split by destination phase | Phase 08 artifacts |
| Raw logs in Git | Linked local logs with committed summary/paths/hashes; commit full logs; excerpts only | Linked local logs with committed summary/paths/hashes |
| Documentation breadth | All active build guidance; README and CLAUDE only; every historical mention | All active build guidance; leave historical records dated |

## Swift 6.4 and current practice

After the four areas, the owner explicitly requested Swift 6.4 and current best practices as part of this milestone, provided changes are nonbreaking. This was incorporated as Swift 6.4 toolchain verification and a source-backed codebase inventory in Phase 08, implementation of approved candidates in Phases 09–10, and release verification in Phase 11. The distinction between Swift 6.4 compiler and Swift 6 language mode was explained using official Xcode and Swift sources. The owner then instructed the agent to write context.

## Agent discretion

No question was delegated to the agent. Exact artifact filenames, inventory formatting, and evidence-collection mechanics remain implementation details for research and planning.

## Deferred ideas

None added during discussion.
