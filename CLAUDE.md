# ApexMetrics — working agreement

ApexMetrics is a project intelligence tool: an agile board plus an analytics
engine that aggregates entirely in the database. Full specification in
[docs/requirements.md](docs/requirements.md).

It is also a **portfolio project**. Its purpose is to demonstrate engineering
judgement in a hiring conversation. That changes what "done" means: a decision
is only finished once the reasoning behind it is written down somewhere a
reviewer can find it. An `EXPLAIN` plan, an ADR and a meaningful test are
deliverables here, not overhead.

---

## 1. Git workflow — hard rules

**One task, one branch, one pull request.**

```
main (protected) → feat/APEX-XX-slug → conventional commits → push → open PR → STOP
```

- **Never merge a pull request.** Alejandro merges every PR manually.
- **Never push to `main`.** Never force-push a branch that is under review.
- **Never rewrite published history.**

Branch prefixes: `feat/` · `fix/` · `chore/` · `docs/` · `test/` · `perf/` ·
`refactor/` · `ci/` · `deploy/` · `a11y/`

Commits follow [Conventional Commits](https://www.conventionalcommits.org).
The body explains **why**, not what — the diff already shows what changed.

Pull request descriptions state the requirement they satisfy (`REQ-x.y`), the
approach, the trade-off accepted, and how it was verified.

---

## 2. Language

**Everything inside this repository is in English, without exception**: code,
identifiers, comments, commit messages, branch names, PR descriptions, docs,
test names, log messages, error strings, seed data.

Conversation language escalates as the project advances:

| Phase | Alejandro writes | Claude replies |
| --- | --- | --- |
| 0–2 | Spanish | Spanish |
| 3–4 | Spanish, attempting English | English + short Spanish summary |
| 5–7 | English (Spanish as a safety net) | English, with phrasing feedback |
| 8–10 | English | English, interview mode |

### When a request is unclear

Do **not** ask Alejandro to rephrase. Written expression is the specific skill
being trained here, and reading is not the bottleneck. Instead, offer three or
four concrete interpretations of what the request might mean and let him pick
one. Phrase the options in the English he would have used, so each ambiguity
doubles as vocabulary practice.

### Interview drills

At the end of every milestone, ask two or three technical questions in English
about decisions actually made in this codebase — the kind an interviewer would
ask. Alejandro answers; return feedback on both the technical content and the
phrasing.

---

## 3. Architecture

Clean Architecture in four projects. Reasoning in [docs/adr/](docs/adr/).

```
ApexMetrics.Domain          → no project references at all
ApexMetrics.Application     → Domain
ApexMetrics.Infrastructure  → Application, Domain
ApexMetrics.Api             → Application, Infrastructure (composition root only)
```

**The dependency rule points inward and is enforced by a test**, not by
discipline. `ArchitectureTests` fails the build on violation.

Non-negotiable consequences:

- `Domain` references no ORM, no framework, no NuGet package that implies one.
  Business rules must be testable without a database.
- Application handlers depend on **interfaces**, never on EF Core types.
  A handler that knows `DbContext` exists is a bug.
- HTTP endpoints contain no business logic. They bind, dispatch, and map the
  result to a status code.
- Entities protect their own invariants. No public setter that allows an
  object to reach an invalid state.

### Reads and writes are not symmetric

- **Writes** go through EF Core: change tracking and transactions earn their
  cost when enforcing invariants.
- **Analytics reads** use hand-written SQL through Dapper. `REQ-3` forbids
  aggregating in application memory. Every analytics query ships with a
  documented `EXPLAIN` plan and a justification for each index it relies on.

Never load rows into memory to count, sum or group them.

---

## 4. Testing

Tests exist to make refactoring safe and to document intent. A test that
restates the implementation is worse than no test.

| Layer | Tool | What belongs here |
| --- | --- | --- |
| Domain unit | xUnit + Shouldly | Invariants, state transitions, calculations |
| Application unit | + NSubstitute | Orchestration, authorisation, failure paths |
| Integration | + Testcontainers (real MySQL) | SQL, migrations, persistence behaviour |
| API functional | `WebApplicationFactory` | Status codes, auth, contract shape |
| Frontend | Vitest + RTL + MSW | Behaviour a user can observe |
| E2E | Playwright | Critical journeys only |

Rules:

- **Never mock the database in analytics tests.** The SQL *is* the thing under
  test; an in-memory provider proves nothing about it.
- Name tests `Method_Scenario_ExpectedOutcome`.
- Test behaviour through public APIs, not private methods.
- Query the DOM by role and accessible name, never by CSS class.
- Every bug fix starts with a failing test that reproduces it.
- Assert on values, not on "did not throw".

---

## 5. Security

- No secret in the repository, ever. Configuration comes from environment
  variables; only `*.example` files are committed.
- All SQL is parameterised. String concatenation into a query is a blocking
  review failure — `CA2100` is configured as an error for this reason.
- Passwords: BCrypt with a configurable work factor. Never a bare hash.
- Authorisation is checked server-side on every request. A hidden button in
  the UI is not an access control.
- Error responses never leak stack traces, SQL, or whether an account exists.

---

## 6. Definition of done

A task is done when all of these hold:

- [ ] Builds with no warnings; the architecture test passes
- [ ] New behaviour is covered by tests at the right level, and they pass
- [ ] No secrets, no commented-out code, no `TODO` without a linked issue
- [ ] Everything is in English, including comments and test names
- [ ] Public API changes are reflected in the OpenAPI document
- [ ] Architectural decisions are recorded in an ADR
- [ ] The PR explains the reasoning and states how it was verified

---

## 7. Commands

```bash
docker compose up --build          # full stack; API waits for a healthy DB
dotnet test                        # all backend tests
dotnet format --verify-no-changes  # style gate, same rules as CI
(cd apex-ui && pnpm dev)            # frontend dev server
(cd apex-ui && pnpm test)           # component tests
(cd apex-ui && pnpm build)          # production build
npx playwright test                # E2E against the running stack
```

---

## 8. Model routing

`.claude/settings.json` sets the model to **`opusplan`**: Opus while in plan
mode, Sonnet for execution. Design decisions are expensive to reverse once code
is written; typing out an already-decided design is not.

The switch happens at the **plan mode boundary**, not on topic. Asking an
architecture question outside plan mode is answered by Sonnet. Enter plan mode
(`Shift+Tab`) before any conversation that decides something.

Two subagents pin `model: opus` regardless of phase:

| Agent | Why it is pinned |
| --- | --- |
| `architecture-guardian` | Its verdicts are hard to verify. A missed dependency-rule violation enters the codebase stamped as reviewed, and the next one cites it as precedent. |
| `sql-performance-analyst` | Owns `REQ-3`, where a plausible-looking query that silently aggregates in memory satisfies every test while failing the requirement. |

The other four inherit. Test design, UI review, documentation and language
coaching all produce output that is cheap to check by reading it, so the cost of
a weaker answer is a re-read rather than a defect.

## 9. Working style

- Prefer the boring solution. Every added abstraction has to earn its place,
  and "it might be useful later" is not a justification.
- When a requirement is ambiguous, state the interpretation being used rather
  than silently choosing one.
- Report results honestly. A failing test is reported as failing, with output.
- Flag it explicitly when a requirement in `docs/requirements.md` appears to
  conflict with good practice, then implement the requirement.
