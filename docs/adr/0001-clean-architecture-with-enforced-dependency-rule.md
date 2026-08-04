# 0001. Structure the backend as Clean Architecture with a test-enforced dependency rule

- **Status:** Accepted
- **Date:** 2026-08-04

## Context

ApexMetrics has two kinds of logic with very different lifetimes. Business rules
— which task status transitions are legal, how estimation points are
constrained, what makes a task a bottleneck — should outlive any framework
choice. Delivery concerns — HTTP, JSON, MySQL, JWT — are details that change on
someone else's schedule.

The specification pushes these apart further. `REQ-2.2` defines four strictly
sequential statuses, which is a domain rule. `REQ-3` mandates aggregation at the
database layer, which is an infrastructure concern that must not be allowed to
dictate how the domain is modelled.

The usual failure mode in a layered codebase is not choosing the wrong layers.
It is that the layering degrades: someone adds an EF Core attribute to a domain
entity because it is convenient, a handler takes a `DbContext` because the
interface was one indirection too many, and eighteen months later the "domain"
cannot be instantiated without a database. Every one of those commits passed
code review, because a reviewer comparing a diff against an architecture
diagram is doing unreliable work.

## Decision

Four projects, with dependencies pointing inward:

```
ApexMetrics.Domain          → no project references at all
ApexMetrics.Application     → Domain
ApexMetrics.Infrastructure  → Application, Domain
ApexMetrics.Api             → Application, Infrastructure (composition root only)
```

The rule is **enforced by an automated test**, not by review discipline.
`ArchitectureTests` uses NetArchTest to assert the dependency graph and fails
the build on violation.

Concretely:

- `Domain` references no ORM, no framework, no NuGet package implying one.
  Business rules are testable with no database and no host process.
- `Application` depends on interfaces it declares itself. A handler naming
  `DbContext` or `MySqlConnection` is a defect, not a shortcut.
- `Api` binds input, dispatches, and maps a result to a status code. A
  conditional expressing a business rule there belongs in `Domain`.

## Consequences

**What this costs.** More projects, more interfaces, and more indirection than
this application's size strictly requires. Adding a field touches several
layers. For a CRUD-only application this overhead would not pay for itself, and
that is a fair criticism of using it here — the justification is that this
codebase has a genuinely rich domain rule set (the status state machine,
estimation constraints, bottleneck definition) plus an analytics module with
sharply different data-access needs.

**What it buys.** The domain rules can be tested in milliseconds with no
container. The analytics module can bypass the ORM entirely (see
[ADR-0002](0002-cqrs-with-ef-core-writes-and-dapper-analytics-reads.md)) without
that decision leaking into how entities are modelled. And the dependency rule
stays true, because a violation turns the build red instead of relying on
someone noticing during review.

**What it constrains.** Enforcement is now a build dependency. If NetArchTest
lags a .NET release, the architecture test is temporarily the thing blocking an
upgrade. That is an acceptable trade: an unenforced rule is a comment.

## Alternatives considered

**A single project with folders.** Fastest to write, and entirely defensible at
this size — many production services should be built this way. Rejected because
nothing prevents the domain from acquiring framework dependencies, and the
specification's separation between business rules and a database-layer analytics
mandate is exactly the seam that erodes first. The intent here is to demonstrate
the boundary being held.

**Vertical slice architecture.** Organise by feature, each slice owning its own
data access end to end. Genuinely attractive: it has less ceremony, better
locality of change, and would suit the analytics module particularly well since
that slice legitimately wants different data access from everything else.
Rejected because the domain rules here are shared across slices — task status
transitions are used by the board, by analytics and by reporting — and
duplicating them per slice is how they drift apart. This is the closest
alternative, and on a larger team it might have won.

**Traditional N-tier (Controller → Service → Repository).** The most widely
recognised structure. Rejected because dependencies point *downward* toward the
database, so the business layer ends up shaped by the persistence model rather
than the other way around. That is the specific coupling this project is trying
to demonstrate control over.
