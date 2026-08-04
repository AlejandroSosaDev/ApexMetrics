---
name: new-task
description: Run a roadmap task end to end — branch, tests, implementation, verification, pull request, stop. Use when starting any APEX-XX task from the roadmap.
---

# Running a task

One task, one branch, one pull request. The ritual below is not bureaucracy:
it is what makes the commit history readable as evidence of how this engineer
works.

## 1. Branch

Off the latest `main`:

```bash
git checkout main && git pull --ff-only
git checkout -b <prefix>/APEX-XX-short-slug
```

Prefixes: `feat` `fix` `chore` `docs` `test` `perf` `refactor` `ci` `deploy` `a11y`

If the task depends on an unmerged branch, stack on it and say so explicitly in
the PR description, naming the branch that must merge first.

## 2. Decide what to test, before writing code

Invoke `test-strategist` for anything with branching logic. Write the failing
test first where it is practical — always for a bug fix.

## 3. Implement

Smallest change that satisfies the requirement. Resist adding abstraction for a
future that has not arrived yet.

While implementing, consult:

- `architecture-guardian` — when unsure which layer a type belongs in
- `sql-performance-analyst` — for any query or index decision
- `ui-design-reviewer` — for any component

## 4. Verify — actually run it

Never report success from inspection alone.

```bash
dotnet build -warnaserror
dotnet test
pnpm --filter apex-ui test && pnpm --filter apex-ui build
docker compose up --build      # when infrastructure changed
```

Report failures with their output. A task that is 90% done is reported as 90%
done, with the blocker named.

## 5. Commit

Conventional Commits. The body explains **why**, and states the requirement:

```
feat(analytics): aggregate resource allocation in a single query

Developers with no active tasks must still appear in the allocation report —
an INNER JOIN would hide exactly the idle capacity a manager is looking for,
so this uses a LEFT JOIN with COALESCE on the aggregates.

Execution plan and index rationale in docs/analytics-benchmark.md.

REQ: 3.1
```

## 6. Open the pull request, then stop

```bash
git push -u origin <branch>
gh pr create --fill --base main
```

If `gh` is unavailable, push and hand over the compare URL:
`https://github.com/AlejandroSosaDev/ApexMetrics/compare/<branch>?expand=1`

The PR body states: requirement satisfied · approach · trade-off accepted ·
how it was verified · anything deliberately left out.

**Then stop.** Never merge. Never push to `main`. Alejandro merges manually —
that review gate is the point of the workflow.

## Definition of done

- [ ] Builds with no warnings; architecture test passes
- [ ] New behaviour covered by tests at the right level, and they pass
- [ ] No secrets, no commented-out code, no bare `TODO`
- [ ] Everything in English, including comments and test names
- [ ] Architectural decisions recorded in an ADR
- [ ] PR explains the reasoning and how it was verified
