# 0004. Model estimated hours as a field separate from estimation points

- **Status:** Accepted
- **Date:** 2026-08-04

## Context

`REQ-2.3` requires every task to carry Estimation Points, constrained to the
Fibonacci-like set `{1, 2, 3, 5, 8, 13}`, and logged hours. `REQ-3.2` requires
computing "the total estimated hours vs. actual logged hours per project" and
a variance percentage between them.

The specification never states where "estimated hours" comes from. Read
literally, `REQ-2.3` supplies only two task-level numbers — points and logged
hours — and `REQ-3.2` needs a third: an hours-denominated estimate to compare
logged hours against. This is a gap in the specification, not a contradiction,
and `CLAUDE.md` calls for stating the interpretation used rather than silently
picking one.

Estimation points and hour estimates measure different things in practice.
Points are a relative, unitless sizing signal used for velocity and
comparison between tasks — a task is "5 points" relative to other 5-point
tasks, not "5 hours." Treating a task's point value as its hour estimate
would let `REQ-3.2`'s variance calculation compile and produce a number, but
that number would describe the drift between logged hours and a complexity
score, not between logged hours and a time budget. It would satisfy the
requirement's SQL shape while answering a different question than a project
manager reading "efficiency" would expect.

## Decision

Add `estimated_hours` to the `tasks` table as its own required, positive
decimal — independent of `estimation_points`. Both are collected when a task
is created:

- `estimation_points` — relative sizing, Fibonacci-constrained, used for
  velocity and workload comparisons (`REQ-3.1`).
- `estimated_hours` — the manager's time budget for the task, compared
  against `logged_hours` for `REQ-3.2`'s variance calculation.

This mirrors how Jira and Linear model the same distinction: Story Points and
an Original Time Estimate coexist as separate fields serving separate
questions, and teams that use both do not treat one as a stand-in for the
other.

## Consequences

**What this costs.** A field the specification's `REQ-2.3` wording does not
explicitly list, on every task, in every form and every seed row. Someone
reading `REQ-2.3` in isolation could reasonably ask why a required field
exists that the requirement did not name — this ADR is the answer.

**What it buys.** `REQ-3.2`'s variance percentage means what it says: how far
actual time drifted from the time that was budgeted. That number is
defensible in the sentence a project manager would actually use it in. It also
keeps `estimation_points` honest as a sizing signal — nothing pressures it
toward looking like an hour count.

**What it risks.** Two numbers that are easy to conflate invites a UI that
mislabels one as the other, or a future contributor who "simplifies" the
schema by removing the field that looks redundant. The board and task-detail
views must label both fields explicitly and never merge them into one display.

## Alternatives considered

**Use `estimation_points` directly as the hours in `REQ-3.2`'s formula.** No
schema change, and defensible as the most literal reading of `REQ-2.3`'s
required-fields list. Rejected because it produces a number that is
technically an "estimated vs. logged" variance but not an *hours* variance —
an entrepreneur asking "how far off were we on time budget" would get an
answer computed against complexity points instead. In an interview setting,
"why does 8 story points equal 8 hours" is not a defensible answer.

**Derive `estimated_hours` from `estimation_points` via a fixed conversion
table** (e.g., 1 point = 2 hours, 13 points = 40 hours). Keeps a single
source of truth and avoids double entry. Rejected because a fixed ratio
between complexity and time is exactly the assumption agile estimation
practice exists to avoid — two 5-point tasks routinely take different amounts
of real time, and baking a conversion table into the schema would misrepresent
that as a fixed relationship the domain does not actually have.
