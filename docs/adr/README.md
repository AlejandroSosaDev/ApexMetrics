# Architecture Decision Records

Each file records one decision, the context it was made in, and what it cost.
They are written at the time of the decision and are not edited afterwards to
match how things turned out — when a decision is reversed, a new ADR supersedes
the old one and the old one stays. The record of having changed your mind is
part of the value.

| # | Decision | Status |
| --- | --- | --- |
| [0001](0001-clean-architecture-with-enforced-dependency-rule.md) | Clean Architecture, with the dependency rule enforced by a test | Accepted |
| [0002](0002-cqrs-with-ef-core-writes-and-dapper-analytics-reads.md) | EF Core for commands, hand-written SQL for analytics reads | Accepted |
| [0003](0003-stateless-jwt-authentication.md) | Stateless JWTs with role claims and rotating refresh tokens | Accepted |

## Writing a new one

Use the `adr` skill, or copy the structure: **Context → Decision → Consequences
→ Alternatives considered**, numbered sequentially, titled as a statement of the
decision rather than a topic.

Two sections carry the weight. **Consequences** must include what got worse — a
decision with only upsides was not a decision, and a reader who notices an
unlisted downside stops trusting the document. **Alternatives considered** must
state each rejected option at its strongest; a strawman is transparent to an
experienced reader and discredits the rest.
