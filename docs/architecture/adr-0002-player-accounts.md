# ADR-0002: Player Accounts & Progression Sync

## Status
Accepted (2026-09-01) — beta scope: username/password only, wallet auth deferred.

**Amendment (2026-09-01, same day, product owner directive):** the original Decision below treated accounts as opt-in — guest play unaffected, login only needed for sync/Ranked Run. The product owner has since decided login is **mandatory**: the app must not let a player reach PLAY (or any other screen) without an authenticated session. Guest mode is removed entirely. Everything else in this ADR (backend choice, token mechanism, hashing, sync contract) is unchanged — only the client-side enforcement policy changes, from "accounts are additive" to "accounts gate the app." The "Negative Consequences" and "Edge Cases" below that assumed guest fallback (e.g. "no password reset flow — a player who forgets their password loses access to *that account's cloud save*") now mean losing access to the game entirely, which raises the stakes on the still-missing password-recovery flow — flagged again here so it isn't lost: **recovery-less accounts are a materially bigger risk once login is mandatory than they were when it was optional**, and should be prioritized sooner than "beta fast-follow."

## Date
2026-09-01

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Custom — Vanilla JavaScript/HTML5, no game engine |
| **Domain** | Core / Networking (server-side auth + save sync; client change is additive `fetch()` calls from `src/ui.js`, same pattern as the leaderboard) |
| **Knowledge Risk** | LOW — password hashing uses Node's built-in `crypto.scrypt`, no post-cutoff API |
| **References Consulted** | `docs/architecture/adr-0001-leaderboard-backend-infrastructure.md` (reused infra), `src/ui.js` `META`/`DEF_META` (existing progression shape) |
| **Verification Required** | Confirm `crypto.scrypt` (Node builtin, no dependency) runs correctly in the Vercel Functions Node runtime — same "smoke-test in the real runtime, not just local Node" discipline ADR-0001 already established for `engine.js`. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (reuses the same Vercel Functions + Upstash Redis infrastructure — no new vendor) |
| **Enables** | Progression sync across devices; leaderboard submissions using an account-backed display name instead of a free-text name (closes a name-spoofing gap noted during ADR-0001's beta rollout) |
| **Blocks** | Nothing existing — guest/offline play is unchanged. Blocks any future "Standard vs Collector board split" work that ADR-0001 explicitly deferred pending server-verified progression (this ADR is the prerequisite for that fast-follow, not a delivery of it). |
| **Ordering Note** | This ADR fixes *auth mechanism and save-sync contract* only. It does not redesign the leaderboard board split — that remains out of scope until a later story explicitly picks it up. |

## Context

### Problem Statement
All player progression (`META` in `src/ui.js`: Vault, Unlocks, Collection, Shards, Battle Pass) lives only in `localStorage`. A player who switches devices or clears browser data loses everything, and the leaderboard's free-text name field lets anyone submit under any name. The product owner wants real accounts for the beta, explicitly choosing username/password now (Ronin/Web3 wallet auth deferred to a later iteration) and full progression sync (not just leaderboard identity) as the goal.

### Constraints
- No bundler, no new client dependency — same constraint ADR-0001 already satisfied (`.claude/docs/technical-preferences.md`).
- No password may ever be stored in plaintext.
- Guest (no-account) play must keep working exactly as today — accounts are additive, not required.
- Reuse the existing Upstash Redis instance and Vercel Functions deploy — no new vendor for a beta-scope feature.

### Requirements
- Register (username + password), login, and receive a session credential usable on subsequent requests.
- Upload/download the full `META` object, keyed to the account.
- Leaderboard submissions use the account's username as `displayName` once logged in (guests keep the current free-text field).
- Basic abuse resistance on auth endpoints (rate limiting), reusing the in-memory limiter pattern already shipped in `api/axie.js`.

## Decision

Add two new Vercel Functions, backed by the same Upstash Redis instance ADR-0001 introduced:

- **`api/auth.js`** — `POST` with `{action: 'register'|'login', username, password}`. Registration hashes the password with `crypto.scrypt` (random salt per user, stored alongside the hash) and writes `user:<username_lowercased>` → `{username, salt, hash, createdAt}` in Redis. Both actions return a signed session token on success.
- **`api/sync-save.js`** — `GET`/`POST`, both requiring `Authorization: Bearer <token>`. `GET` returns the account's stored `META` JSON (or `null` if never synced). `POST` overwrites `save:<username_lowercased>` with the body's `META` JSON.

**Session token**: a stateless signed token (HMAC-SHA256 over `{u: username, exp}` using a new `AUTH_JWT_SECRET` env var), not a server-side session store — avoids an extra Redis round-trip per authenticated request and needs no separate invalidation mechanism for beta scope. 30-day expiry.

**Client (`src/ui.js`)**: a new `ACCOUNT` menu screen (register/login form). On successful login, the token is cached in `localStorage` alongside the existing `META`/`RK` keys; `META` is pulled from `api/sync-save.js` and merged over local (last-write-wins by a `savedAt` timestamp added to `META`, see Edge Cases). While logged in, `saveMeta()` additionally debounce-pushes to `api/sync-save.js` (~5s after the last change) so a network hiccup never blocks gameplay — same graceful-degrade philosophy as the leaderboard's `stored:false`.

### Architecture Diagram

```
Client (src/ui.js)                  Vercel Functions               Upstash Redis
───────────────────                 ─────────────────               ─────────────
Register/Login  ───POST────────▶  api/auth.js                   user:<username> → {salt, hash, createdAt}
  ◀── {token} ────────────────────────  │ crypto.scrypt verify/hash
localStorage: token, META              │ sign session token (HMAC)
                                        ▼
saveMeta() (debounced) ──POST──▶  api/sync-save.js  ──JWT verify──▶  save:<username> → META JSON
App load (if token present) ──GET──▶     │
  ◀── META JSON ──────────────────────  ▼
merge into local META (last-write-wins by META.savedAt)
```

### Key Interfaces
- **`POST /api/auth`** — body `{action, username, password}`. `register`: 3-20 char `[a-z0-9_]` username, ≥8 char password. `login`: verifies via timing-safe compare. Response: `{ok: true, token, username}` or `{ok: false, error}` (generic "invalid credentials" for login failures — no username-enumeration hints).
- **`GET /api/sync-save`** (Bearer token) → `{meta: <META JSON> | null}`.
- **`POST /api/sync-save`** (Bearer token, body `{meta}`) → `{ok: true}`. Server stamps `meta.savedAt` server-side (not trusted from client) so cross-device conflict resolution has a consistent clock.

## Alternatives Considered

### Alternative 1: Ronin/Web3 wallet signature auth now
- **Pros**: No password storage at all; fits the game's Axie theme; the "Import Axie" screen already gestures at wallet connect.
- **Cons**: Needs a signing library and wallet-connect UX (bigger client surface); most beta testers won't have a Ronin wallet installed, raising the bar to try the feature the product owner wants validated first.
- **Rejection Reason**: Product owner explicitly chose username/password for beta and wallet auth as a later iteration — this ADR revisits nothing, it records that sequencing decision.

### Alternative 2: Full account system via a hosted auth provider (e.g. Clerk, Auth0, Supabase Auth)
- **Pros**: Battle-tested security, less code to write and maintain, built-in password reset flows.
- **Cons**: New vendor, likely a client SDK (violates "no bundler/dependency"), and a paid tier once past free-tier limits — disproportionate for a beta-scope, low-traffic feature that ADR-0001 already chose to keep infra-light.
- **Rejection Reason**: Same reasoning ADR-0001 used to reject a heavier backend for the leaderboard — stay on the already-adopted Vercel + Upstash stack until scale demands otherwise.

## Consequences

### Positive
- Progression now survives device changes and cleared browser storage for any player who registers.
- Leaderboard name-spoofing (flagged during ADR-0001 rollout) is closed for logged-in players as a side effect, with no separate system needed.
- No new vendor, no new client dependency — extends the exact pattern ADR-0001 established.

### Negative
- The project's first system storing player-authored secrets (password hashes) — raises the security bar for `api/auth.js` specifically (must never log passwords, must rate-limit, must use timing-safe compare).
- No password-reset flow in beta scope (no email service yet) — a player who forgets their password loses access to that account's cloud save until a fast-follow ships recovery.
- Last-write-wins sync can silently drop progress made offline on a second device between syncs — acceptable for beta, documented as a known limitation (mirrors ADR-0001's leaderboard tiebreak precedent).

### Risks
- **Brute-force / credential-stuffing against `api/auth.js`.** *Mitigation*: reuse the in-memory rate limiter pattern from `api/axie.js` (per-IP request cap); generic error messages; minimum password length enforced server-side, not just client-side.
- **`AUTH_JWT_SECRET` leak would let an attacker forge session tokens for any account.** *Mitigation*: treat it exactly like `UPSTASH_REDIS_REST_TOKEN` — Vercel env var only, never in a committed file; document the setup step in the same place as the Upstash setup steps.
- **Sync conflicts (two devices, offline edits) resolved by last-write-wins may surprise a player who loses a session's progress.** *Mitigation*: client shows a clear "cloud save is newer — overwrite local?" prompt on login when `meta.savedAt` disagrees with local, rather than silently discarding either side.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| `design/gdd/player-accounts.md` | Register/login with username+password | `api/auth.js`, `crypto.scrypt` hashing, signed session token |
| `design/gdd/player-accounts.md` | Progression syncs across devices | `api/sync-save.js` + client debounced push / load-time pull |
| `design/gdd/player-accounts.md` | Guest play unaffected | Account flow is entirely additive; `META`/`localStorage` path unchanged when logged out |
| `design/gdd/leaderboard-system.md` (fast-follow note) | Name spoofing on submitted scores | Logged-in submissions use the account username, not a free-text field |

## Performance Implications
- **CPU**: `crypto.scrypt` is intentionally slow (that's its security property) — bounded to auth endpoints only (register/login), not called on every request, so cost stays proportional to auth traffic, not gameplay traffic.
- **Storage**: One Redis key per user for credentials, one per user for the save blob (`META` JSON is small, comparable in size to the localStorage copy already shipping today).
