# Architecture Decision Records

Record every significant technical decision here so future contributors
(and future Claude sessions) understand *why* the codebase is shaped the
way it is.

## When to write an ADR

- Choosing between two or more non-obvious approaches
- Deviating from a default / framework convention
- Accepting a known trade-off
- Deciding NOT to do something that might otherwise seem obvious

## File naming

`NNNN-short-kebab-title.md` — four-digit zero-padded number, sequential.
Example: `0001-abv-stored-as-fraction.md`

## Template

```markdown
# NNNN — Title

**Status**: Accepted  
**Date**: YYYY-MM-DD

## Context

What situation prompted this decision?
What constraints or forces were at play?

## Decision

What did we decide to do?

## Consequences

### Positive
- …

### Negative / trade-offs
- …

### Alternatives considered
- **Option B** — rejected because …
```

## Status values

| Status | Meaning |
|--------|---------|
| Proposed | Under discussion, not yet in code |
| Accepted | In effect |
| Deprecated | No longer in effect; superseded ADR noted |
| Superseded | Replaced by ADR NNNN |
