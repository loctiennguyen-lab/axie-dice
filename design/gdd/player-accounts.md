# Player Accounts & Progression Sync

## 1. Overview
Beta-scope account system: username + password login, letting players sync their `META` progression (Vault, Unlocks, Collection, Battle Pass, Shards) across devices instead of it being trapped in one browser's `localStorage`. Guest (no-account) play is unaffected — accounts are opt-in. Backend reuses the Vercel Functions + Upstash Redis infrastructure from `docs/architecture/adr-0001-leaderboard-backend-infrastructure.md`; see `docs/architecture/adr-0002-player-accounts.md` for the technical decision record.

## 2. Player Fantasy
"My progress follows me, not my browser." A player who plays on a laptop at home and a phone on the go sees the same Vault, the same Unlocks, the same Collection — no re-grinding, no fear of losing everything to a cleared cache.

## 3. Detailed Rules

### Guest mode (default, unchanged)
- No account required. `META` lives only in `localStorage`, exactly as it does today.
- Leaderboard submissions use a free-text display name, exactly as they do today.

### Registration
- Screen: new `ACCOUNT` menu tile → register/login form.
- Username: 3–20 characters, `[a-z0-9_]` only, case-insensitive uniqueness.
- Password: minimum 8 characters, no other composition rule (length over complexity theater).
- On successful registration, the player's **current local `META` becomes their first cloud save** — no data loss going from guest to account.

### Login
- Username + password → session token (30-day expiry), cached in `localStorage`.
- Server's stored `META` is fetched and compared against local `META` by `savedAt` timestamp:
  - If server copy is newer or local has no unsynced changes: silently adopt the server copy.
  - If local has changes newer than the server copy (e.g. played offline before logging in on this device): show a clear choice — "Keep this device's progress" vs "Use cloud progress" — never silently discard either.

### Ongoing sync
- Every `saveMeta()` call, while logged in, schedules a debounced (~5s) push to the server.
- Sync failures (offline, server error) never block or interrupt gameplay — same graceful-degrade pattern the leaderboard already uses for `stored:false`.

### Leaderboard integration
- Logged-in players submitting a Ranked Run use their **account username** as the leaderboard display name automatically (no separate name entry). Guests keep the current free-text field.

### Logout
- Clears the cached session token. Local `META` remains on the device (does not revert to a pre-login state) — logging out is not equivalent to guest mode, it just stops syncing.

## 4. Formulas
No gameplay-numeric formulas. The only computed value is the password hash: `crypto.scrypt(password, randomSalt, 64)` (Node builtin), stored as `{salt, hash}` — never the raw password.

## 5. Edge Cases
- **Duplicate username at registration** → generic "username taken" error. Login failures use a generic "invalid username or password" (no hint about which field is wrong — avoids username enumeration).
- **Forgotten password** → **no recovery flow in beta** (no email service configured yet). This is a known, explicit beta limitation — a fast-follow once an email provider is chosen, not an oversight.
- **Sync conflict** (two devices edited offline) → resolved by the explicit choice prompt described above under Login, never a silent last-write-wins on the client's behalf. (Server storage itself is last-write-wins — whichever `POST /api/sync-save` lands last wins — but the client always gives the player the choice before it triggers an overwrite from a divergent state.)
- **Registering while offline / server down** → same "computed but not saved" pattern as `submit-run.js`: registration form shows a clear network-error message, does not silently fail.
- **Brute-force attempts** → rate-limited per-IP on `api/auth.js` (same in-memory limiter pattern as `api/axie.js`), generic error responses regardless of whether the username exists.

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
- A new player can register with username + password and immediately see their existing local progress preserved as their first cloud save.
- Logging in on a second, fresh device pulls down the same Vault/Unlocks/Collection/Shards as the first device.
- Logging in with unsynced local progress present prompts an explicit keep-local-vs-use-cloud choice; neither is ever silently discarded.
- Guest play (no account) is functionally identical to the current game — no regression.
- No password is ever stored or logged in plaintext, verified by reading `api/auth.js` and confirming only `{salt, hash}` reaches Redis.
- Repeated failed login attempts from one IP are rate-limited.
- A logged-in player's Ranked Run submission uses their account username automatically, without a separate name-entry step.
