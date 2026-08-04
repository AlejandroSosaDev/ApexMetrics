# 0002. Separate reads from writes: EF Core for commands, hand-written SQL for analytics

- **Status:** Accepted
- **Date:** 2026-08-04

## Context

The two halves of this application want opposite things from a data access
layer.

**Writes** are small, transactional and invariant-heavy. Moving a task from
`To Do` to `In Progress` loads one aggregate, validates a state transition,
and saves. Change tracking, unit of work and migrations are worth their cost
here.

**Analytics reads** are the opposite. `REQ-3` specifies three aggregations —
resource allocation across developers, estimated-versus-logged variance per
project, and bottleneck detection across four joined tables — and states
plainly that the endpoint *"cannot load raw data and process it in memory; all
data aggregation must happen at the MySQL database layer."*

An ORM can be coerced into emitting that SQL. The cost is that the resulting
LINQ is harder to read than the SQL it produces, small expression changes
silently alter the generated query, and the developer ends up reading
`EXPLAIN` output anyway to confirm what actually ran. The abstraction stops
abstracting precisely where the interesting work is.

There is also a failure mode worth naming: it is easy to write LINQ that looks
like it aggregates in the database but silently materialises rows first — one
unsupported expression flips the whole query to client-side evaluation. That
would violate `REQ-3` while still passing a test that only checks the returned
numbers.

## Decision

Separate the read and write paths.

- **Commands** use EF Core 10. Aggregates are loaded, invariants enforced in the
  domain, and saved transactionally. EF Core also owns the schema through
  migrations.
- **Analytics queries** use Dapper with hand-written SQL. Each query is
  parameterised, lives beside its `EXPLAIN` plan, and returns a purpose-built
  DTO rather than a domain entity.
- The three analytics queries are served by one endpoint in a **single round
  trip**, using `Dapper.QueryMultiple`. They are always requested together, so
  three sequential round trips would be three network waits for one dashboard.

This is CQRS at the level of data access only. There is no separate read
database, no eventual consistency, and no event sourcing — both paths hit the
same MySQL instance in the same transaction boundary.

The command/query dispatcher is a small hand-written implementation rather than
MediatR. MediatR v13 moved to a paid commercial licence, and the pattern is
roughly sixty lines: a marker interface, a handler interface, and a resolve-and
-invoke dispatcher with a pipeline for validation and logging. Taking the
dependency would mean paying a licence to avoid writing code that is easier to
read than the library's configuration.

## Consequences

**What this costs.** Two data access technologies to learn and maintain. SQL
strings are not checked by the compiler, so a column rename that EF Core
migrations handle automatically will break a Dapper query at runtime instead of
at build time. This is a real risk and it is mitigated, not eliminated: every
analytics query is covered by an integration test that runs against real MySQL
in Testcontainers. An in-memory provider would not catch it, which is exactly
why the test suite does not use one.

Writing the dispatcher also means owning it. If the pipeline needs features
MediatR provides for free — streaming, notification fan-out — that becomes work.
The scope here does not need them.

**What it buys.** The analytics SQL is readable as SQL, which means it is
reviewable, `EXPLAIN`-able, and tunable by anyone who knows MySQL without also
knowing this codebase's LINQ conventions. Compliance with `REQ-3` is verifiable
by reading the query rather than by inspecting generated SQL. And the write path
keeps the full benefit of an ORM where that benefit is real.

**What it enables.** Index design becomes a first-class, documented activity —
see `docs/analytics-benchmark.md`, which records the execution plans and the
measured difference against a naive implementation.

## Alternatives considered

**EF Core everywhere.** One technology, compile-time safety on column names,
less to explain. Rejected because the analytics queries are the part of this
system where knowing the exact emitted SQL matters most, and `REQ-3` makes
in-memory aggregation a specification failure rather than a performance
question. The compile-time safety argument is the strongest point against this
decision, and it is answered with integration tests rather than dismissed.

**Dapper everywhere.** Consistent, fast, and no ORM to fight. Rejected because
the write path genuinely benefits from change tracking and transactional unit
of work when enforcing aggregate invariants, and hand-writing migrations for a
schema that is still moving would be tedious for no gain.

**A stored procedure per analytic.** Would satisfy `REQ-3` and keeps the SQL in
the database where it can be tuned by a DBA. Rejected because procedures live
outside version control's usual review flow, are awkward to test in CI, and
would make the seed and migration story more complicated than the project
warrants.

**Full CQRS with a separate read model.** Materialised projections updated by
domain events. Rejected as unjustifiable at this scale: it would add eventual
consistency — and the user-visible bugs that come with it — to a dashboard over
thirty tasks. Worth revisiting only if the aggregations outgrow what a single
query can serve.
