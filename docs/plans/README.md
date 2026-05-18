# Plans

Every new feature or significant refactor lives in a numbered folder here.
Trivial changes (single-line fixes, typos) do not need a plan.

See CLAUDE.md § "Plan-driven development" for the full lifecycle.

---

## Sizing guide

| Size | Scope | Typical duration |
|------|-------|-----------------|
| **small** | Single file or component; no schema change; clear requirements | < half a day |
| **medium** | New feature; 2–5 files; possible schema change; some open questions | 1–2 sessions |
| **large** | New screen, multi-feature, schema migration, or architectural change | multiple sessions |

---

## Folder structure

```
docs/plans/
├── INDEX.md                        ← always update after status changes
├── README.md                       ← this file
└── NNNN-kebab-title/
    ├── plan.md                     ← frozen once in-progress
    ├── execution.md                ← append-only during execution
    └── retrospective.md            ← created on completion
```

---

## plan.md template

```markdown
# NNNN — Title

**Status**: draft
**Size**: small | medium | large
**Created**: YYYY-MM-DD

## Summary

One paragraph: what this plan delivers and why.

## Context

What triggered this work? What constraints apply?

## Scope

### In
- …

### Out
- …

## Implementation steps

Numbered, ordered. Each step = one logical unit of work (ideally one commit).

1. …
2. …

## Files

| File | Action |
|------|--------|
| `path/to/file` | Create / Modify / Delete |

## Open questions

Must be answered before or during execution.

- [ ] Question (options: A / B)

## Tests required

- …
```

---

## execution.md template

```markdown
# NNNN — Execution Log

Append-only. Never edit or delete previous entries.

---

## YYYY-MM-DD — Short title

### Done
- …

### Deviations from plan
- …

### Discoveries
- …

### Open questions updated
- Resolved: [question] → chose option A because …
- New: …
```

---

## retrospective.md template

```markdown
# NNNN — Retrospective

**Completed**: YYYY-MM-DD

## What went well
- …

## What went wrong / surprises
- …

## Decisions made during execution
- …

## Leftover open questions
- …
```
