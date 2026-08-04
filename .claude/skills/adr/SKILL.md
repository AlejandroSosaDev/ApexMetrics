---
name: adr
description: Write an Architecture Decision Record. Use when a choice was made that a future reader would otherwise question, reverse, or have to re-derive.
---

# Architecture Decision Record

An ADR captures a decision at the moment it was made, with the information that
was available then. Its value is that it lets a future reader — including an
interviewer — see the reasoning rather than guess at it.

## When to write one

Write an ADR when the decision would be **expensive to reverse**, when a
reasonable engineer would have chosen differently, or when the choice will look
wrong without its context.

Do not write one for choices with an obvious default. An ADR justifying the use
of `git` dilutes the ones that matter.

## File

`docs/adr/NNNN-kebab-case-title.md`, sequentially numbered, never renumbered.
The title states the **decision**, not the topic: "Use Dapper for analytics
reads", not "Data access".

## Template

```markdown
# NNNN. <Decision as a statement>

- **Status:** Proposed | Accepted | Superseded by [ADR-NNNN](...)
- **Date:** YYYY-MM-DD

## Context

The forces at play: the requirement, the constraint, the thing that made this a
real question. Written so it makes sense to someone who was not in the room.
Facts, not conclusions.

## Decision

What was decided, in the active voice. "We aggregate in the database."

## Consequences

What follows — including what got worse. A decision with only upsides was not a
decision, and a reader who spots an unlisted downside stops trusting the rest of
the document.

## Alternatives considered

Each alternative, and why it lost. State each one at its strongest; a strawman
here discredits the whole ADR and is transparent to an experienced reader.
```

## Quality bar

- **Context before decision.** A reader must be able to reach your conclusion
  themselves before reading it.
- Name the trade-off explicitly. "Hand-written SQL is faster but is not checked
  by the compiler, so it is covered by integration tests against real MySQL."
- Prefer measurements to adjectives.
- Keep it under a page. An ADR nobody finishes reading has failed.
- Never edit an accepted ADR to reflect a new decision. Write a new one and
  mark the old one superseded — the record of having changed your mind is
  itself worth keeping.
