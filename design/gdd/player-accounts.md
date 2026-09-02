# Player Accounts & Progression Sync

## 1. Overview
Beta-scope account system: username + password login, letting players sync their `META` progression (Vault, Unlocks, Collection, Battle Pass, Shards) across devices instead of it being trapped in one browser's `localStorage`. **Login is mandatory** (2026-09-01 amendment — see `docs/architecture/adr-0002-player-accounts.md` Status): the app gates every screen, including PLAY, behind an authenticated session — there is no guest mode. Backend reuses the Vercel Functions + Upstash Redis infrastructure from `docs/architecture/adr-0001-leaderboard-backend-infrastructure.md`.

## 2. Player Fantasy
"My progress follows me, not my browser." A player who plays on a laptop at home and a phone on the go sees the same Vault, the same Unlocks, the same Collection — no re-grinding, no fear of losing everything to a cleared cache.

## 3. Detailed Rules

### App gate (mandatory — no guest mode)
- On launch, before rendering the menu (or any other screen), the app checks for a cached, non-expired session token.
- No valid token → the app shows ONLY the login/register form. PLAY and every menu tile are unreachable — there is no "skip for now" path.
- A valid, but not-yet-verified-with-the-server token still lets the app render normally optimistically (avoids a network round-trip blocking every launch); if the server later rejects it (401 on the first authenticated call), the app drops back to the gate rather than silently continuing in a half-authenticated state.

### Registration
- Reached only from the login gate (first launch) or an explicit "switch account" action later. Same form either way.
- Username: 3–20 characters, `[a-z0-9_]` only, case-insensitive uniqueness.
- Password: minimum 8 characters, no other composition rule (length over complexity theater).
- On successful registration, the player's **current local `META` becomes their first cloud save** (relevant for a returning device that had pre-gate local progress; a brand-new device just starts at `DEF_META`).

### Login
- Username + password → session token (30-day expiry), cached in `localStorage`.
- Server's stored `META` is fetched and compared against local `META` by `savedAt` timestamp:
  - If server copy is newer or local has no unsynced changes: silently adopt the server copy.
  - If local has changes newer than the server copy (e.g. played offline before logging in on this device): show a clear choice — "Keep this device's progress" vs "Use cloud progress" — never silently discard either.

### Ongoing sync
- Every `saveMeta()` call, while logged in, schedules a debounced (~5s) push to the server.
- Sync failures (offline, server error) never block or interrupt gameplay — same graceful-degrade pattern the leaderboard already uses for `stored:false`.

### Leaderboard integration
- Every Ranked Run submission uses the account's **username** as the leaderboard display name automatically — there is no free-text name entry anymore, since a submission is impossible without being logged in.

### Logout
- Clears the cached session token and returns straight to the login/register gate (per the App gate rule — there is nowhere else for a logged-out session to go). Local `META` on the device is left as-is (not wiped) so logging back in with the SAME account resumes instantly without a network round-trip needed to feel right, but no screen is reachable until that login happens.

## 4. Formulas
No gameplay-numeric formulas. The only computed value is the password hash: `crypto.scrypt(password, randomSalt, 64)` (Node builtin), stored as `{salt, hash}` — never the raw password.

## 5. Edge Cases
- **Duplicate username at registration** → generic "username taken" error. Login failures use a generic "invalid username or password" (no hint about which field is wrong — avoids username enumeration).
- **Forgotten password** → **no recovery flow in beta** (no email service configured yet). Explicitly flagged as a bigger risk now that login is mandatory (see ADR-0002 Amendment): a player who forgets their password is locked out of the game itself, not just cloud sync. Still a known, explicit beta limitation, not an oversight — but should be prioritized sooner than "eventually."
- **Sync conflict** (two devices edited offline) → resolved by the explicit choice prompt described above under Login, never a silent last-write-wins on the client's behalf. (Server storage itself is last-write-wins — whichever `POST /api/sync-save` lands last wins — but the client always gives the player the choice before it triggers an overwrite from a divergent state.)
- **Two different accounts sharing one device** (fixed 2026-09-02, was a real bug in the first shipped version) → local `META` carries an `owner` field (the username whose progress currently occupies this device's local storage). The keep-local-vs-use-cloud prompt above is now gated on `META.owner === (account being logged into)` — a different account, or a brand-new device, NEVER sees that prompt and never has a chance to have another account's local progress merged into it; it just gets its own cloud save (or a clean slate if it has none yet). Registering a second account on a device that already has a first account's local progress also starts that second account clean, for the same reason. Logging back into the SAME account that already owns this device's local data behaves exactly as before (the by-`savedAt` comparison and prompt still apply — that path is for one player's own multi-device sync, which is unaffected).
- **Registering/logging in while offline / server down** → the gate shows a clear network-error message and stays on the gate (nothing to fall back to — there is no guest mode). Does not silently fail or spin forever.
- **Brute-force attempts** → rate-limited per-IP on `api/auth.js` (same in-memory limiter pattern as `api/axie.js`), generic error responses regardless of whether the username exists.
- **Cached token present but expired/invalid** (e.g. 30 days passed, or `AUTH_JWT_SECRET` rotated server-side) → the first authenticated call fails with 401, the client clears the stale token and returns to the gate with a neutral "please log in again" message — never a silent infinite retry loop.

## 6. Dependencies
- `docs/architecture/adr-0001-leaderboard-backend-infrastructure.md` — reused infrastructure (Vercel Functions, Upstash Redis).
- `docs/architecture/adr-0002-player-accounts.md` — technical decision record for this system.
- `src/ui.js` `META`/`DEF_META`/`saveMeta()`/`loadMeta()` — existing progression state this system syncs.
- `design/gdd/leaderboard-system.md` — leaderboard display-name integration for logged-in players.

## 7. Tuning Knobs
- Minimum password length (currently 8).
- Session token expiry (currently 30 days).
- Sync debounce interval (currently ~5s after last `META` change).
- Username length bounds (currently 3–20 chars).

## 8. Acceptance Criteria
- A brand-new visitor cannot reach PLAY, or any menu screen, without registering or logging in first — the gate is the only thing rendered until authentication succeeds.
- A new player can register with username + password and immediately see their existing local progress (if any, on a returning device) preserved as their first cloud save.
- Logging in on a second, fresh device pulls down the same Vault/Unlocks/Collection/Shards as the first device.
- Logging in with unsynced local progress present prompts an explicit keep-local-vs-use-cloud choice; neither is ever silently discarded.
- Logging out returns to the gate; the app is unreachable again until logging back in.
- An expired or invalid cached token drops the app back to the gate with a clear message, not a broken/half-loaded state.
- No password is ever stored or logged in plaintext, verified by reading `api/auth.js` and confirming only `{salt, hash}` reaches Redis.
- Repeated failed login attempts from one IP are rate-limited.
- Every Ranked Run submission uses the account username automatically, without a separate name-entry step.
