# Contributing

Conventions for working on ApexMetrics. The rules Claude Code follows live in
[CLAUDE.md](CLAUDE.md); this file is the human-facing setup and workflow.

## Prerequisites

| Tool | Version | Install |
| --- | --- | --- |
| .NET SDK | 10.0 (LTS) | `winget install Microsoft.DotNet.SDK.10` |
| Node.js | 22 LTS | `winget install OpenJS.NodeJS.LTS` |
| pnpm | 10+ | `npm install -g pnpm` |
| Docker Desktop | 27+ | `winget install Docker.DockerDesktop` |
| GitHub CLI | 2+ | `winget install GitHub.cli` |

Only Docker is strictly required to *run* the stack. The SDK and Node are for
working on the code outside containers, which is faster during development.

## One-time repository setup

```bash
gh auth login
bash .github/setup-branch-protection.sh
```

Branch protection on a free plan requires the repository to be **public**. That
is the intended state anyway: this is a portfolio project, and public
repositories also get unlimited GitHub Actions minutes, which is what allows CI
here to be thorough rather than rationed.

## Running the stack

```bash
docker compose up --build
```

The API waits for the database to report healthy before starting, and the
database initialises from `db/seed.sql`, so the analytics dashboard has
meaningful data on first load.

## Workflow

One task, one branch, one pull request.

```bash
git checkout main && git pull --ff-only
git checkout -b feat/APEX-XX-short-slug
# ... work, with tests ...
git push -u origin feat/APEX-XX-short-slug
gh pr create --fill --base main
```

Branch prefixes: `feat` `fix` `chore` `docs` `test` `perf` `refactor` `ci`
`deploy` `a11y`.

Commits follow [Conventional Commits](https://www.conventionalcommits.org). The
body explains **why** — the diff already shows what.

Pull requests are merged manually, by a human, after review. Nothing merges
itself here.

## Before opening a pull request

```bash
dotnet build -warnaserror
dotnet test
dotnet format --verify-no-changes
(cd apex-ui && pnpm test && pnpm build)
```

Run them. A pull request that says "tests pass" without having run them costs
more trust than the time it saved.

## Definition of done

- [ ] Builds with no warnings; the architecture test passes
- [ ] New behaviour covered by tests at the right level, and they pass
- [ ] No secrets, no commented-out code, no `TODO` without a linked issue
- [ ] Everything in English, including comments and test names
- [ ] Public API changes reflected in the OpenAPI document
- [ ] Architectural decisions recorded in an [ADR](docs/adr/)
- [ ] The PR explains the reasoning and how it was verified

## Architecture in one paragraph

Four backend projects with dependencies pointing inward — `Domain` references
nothing, `Api` is a composition root. The rule is enforced by a test, not by
review discipline. Writes go through EF Core; the analytics endpoint uses
hand-written SQL through Dapper, because `REQ-3` requires aggregation to happen
in the database. Full reasoning in [docs/adr/](docs/adr/).

## Testing

Put each test at the cheapest level that can actually prove the behaviour:
domain rules as unit tests, SQL against real MySQL through Testcontainers, HTTP
contracts through `WebApplicationFactory`, and only critical journeys in
Playwright.

**Analytics tests never mock the database.** The SQL is the subject under test,
and an in-memory provider has different semantics — it would prove nothing
about the thing being verified.
