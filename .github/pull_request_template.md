## What and why

<!-- The diff shows what changed. Explain why it needed to change. -->

**Requirement:** <!-- REQ-x.y, or "none (foundation)" -->
**Task:** <!-- APEX-XX -->

## Approach

<!-- The path taken, and the one not taken. If you considered another design
     and rejected it, one sentence on why is worth more than a paragraph
     describing what you built. -->

## Trade-off accepted

<!-- What got worse. Every real change costs something: a slower build, a new
     dependency, duplication, a case deliberately left unhandled. A PR that
     claims no downside usually has an unexamined one. -->

## How this was verified

<!-- What was actually run, not what should pass. Paste output or attach a
     screenshot. "Tests pass" without evidence is not verification. -->

- [ ] `dotnet build -warnaserror`
- [ ] `dotnet test`
- [ ] `(cd apex-ui && pnpm test && pnpm build)`
- [ ] `docker compose up --build` <!-- if infrastructure changed -->

## Definition of done

- [ ] Builds with no warnings; the architecture test passes
- [ ] New behaviour covered by tests at the right level
- [ ] No secrets, no commented-out code, no `TODO` without a linked issue
- [ ] Everything in English, including comments and test names
- [ ] Public API changes reflected in the OpenAPI document
- [ ] Architectural decisions recorded in an ADR

## Left out on purpose

<!-- Anything deliberately deferred, and to which task. Better stated here than
     discovered later. Delete this section if nothing was. -->

---

<!-- Stacked on an unmerged branch? Name it here and set the PR base to it. -->
