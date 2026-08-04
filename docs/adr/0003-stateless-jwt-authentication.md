# 0003. Authenticate with stateless JWTs carrying role claims

- **Status:** Accepted
- **Date:** 2026-08-04

## Context

`REQ-1.1` mandates stateless authentication using JSON Web Tokens. `REQ-1.3`
requires role claims distinguishing `Admin` (project manager) from `Developer`.
`REQ-1.4` requires protected endpoints to validate a Bearer token and return
`401` when validation fails.

The deployment target constrains this further. The API runs on a free tier that
sleeps after fifteen minutes of inactivity and restarts cold. Any authentication
scheme depending on in-process state — a session cache, an in-memory token store
— loses that state on every restart and would sign users out unpredictably.

## Decision

Stateless JWT Bearer authentication.

- **Access tokens** are short-lived (15 minutes), signed with HMAC-SHA256, and
  carry `sub`, `role`, `jti`, `iat` and `exp`. No personal data beyond the user
  identifier: a JWT is signed, not encrypted, and anyone holding it can read the
  payload.
- **Refresh tokens** are long-lived (7 days), opaque, random, and stored hashed
  in the database. They rotate on use, and reuse of a consumed refresh token
  revokes the whole family — the standard detection for a stolen token.
- Passwords use **BCrypt** with a configurable work factor (`REQ-1.2`).
- Authorisation uses ASP.NET Core policies, applied per endpoint. The analytics
  endpoint requires the `Admin` policy (`REQ-3`).
- `401` means "not authenticated"; `403` means "authenticated but not permitted".
  They are different answers and both are asserted in tests.
- The signing key comes from configuration and never from source. Token
  validation explicitly checks issuer, audience, lifetime and signing key, and
  the accepted algorithm is pinned.

## Consequences

**What this costs — and this is the important one.** A stateless access token
cannot be revoked before it expires. If an account is disabled, its existing
access token stays valid for up to fifteen minutes. That window is the price of
statelessness, and the mitigations chosen are: keep it short, and make refresh
tokens — which *are* stateful and revocable — the only way to extend a session.
For an application handling payments this would not be acceptable and a token
denylist would be needed; for this system it is a reasonable trade.

**Where the tokens live is a real risk.** `localStorage` is readable by any
script on the page, so a single XSS becomes a full account takeover. An
`HttpOnly` cookie removes that but introduces CSRF, which then needs its own
mitigation. The refresh token is held in an `HttpOnly`, `Secure`, `SameSite=Strict`
cookie; the access token is kept in memory only and never persisted, so a page
reload performs a silent refresh. This is more work in the frontend than storing
both in `localStorage`, and it is the correct trade.

**Clock skew matters.** Short-lived tokens make `exp` validation sensitive to
drift between the API container and the database host. Default tolerance is
reduced from five minutes to thirty seconds; anything larger partly defeats a
fifteen-minute lifetime.

**What it buys.** No server-side session state, so the API restarts cold without
signing anyone out — which matters directly given the free-tier sleep behaviour.
Horizontal scaling needs no sticky sessions or shared cache.

## Alternatives considered

**Server-side sessions with a cookie.** Simpler, immediately revocable, and no
token-in-storage question at all. Genuinely the better default for a monolithic
web application. Rejected because `REQ-1.1` explicitly mandates stateless JWT,
and because session state would not survive the free-tier restarts this
deployment expects.

**Long-lived access tokens with no refresh.** Much less machinery. Rejected
because it makes the revocation window hours instead of minutes, turning the one
real weakness of this scheme into a serious one.

**A managed identity provider — Auth0, Entra ID, Clerk.** What most production
systems should use: no password storage, MFA and account recovery included, and
someone else patching the auth stack. Rejected for two reasons. The
specification asks for authentication to be implemented, and outsourcing it
would remove the part a reviewer is meant to evaluate. It would also add an
external dependency to a stack that is otherwise entirely self-contained in
`docker compose up`.

**Storing both tokens in `localStorage`.** The most common implementation and
the simplest frontend. Rejected as described above: it converts any XSS into a
persistent account takeover, and the split in-memory/`HttpOnly` approach costs
only a silent-refresh flow to avoid.
