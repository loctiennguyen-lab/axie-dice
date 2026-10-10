# Player Accounts & Cloud Save

> **Status**: Implemented and live on axiedice.fun (10 Oct 2026).
> Replaces the earlier username + password / mandatory-login design (Vercel + Upstash). That
> design was never shipped in the Godot build and is dropped: there is no password, no
> registration form, and guest play stays.
> Code: `godot/autoload/AccountService.gd`, `godot/scripts/core/save_store.gd`,
> `godot/scenes/shared/AccountUI.gd`, `godot/scenes/settings/SettingsView.gd` (Account section),
> `worker/src/accounts.js`, `worker/src/legal.js`, `worker/migrations/0001_accounts.sql`.

## 1. Overview
Players can sign in with Google (a Sky Mavis work account or a personal Gmail) and their
progress — the meta save and any run in progress — is stored on the server and follows them to
any browser. Signing in for the first time creates the game profile automatically; there is no
second registration. Guest play still works and keeps progress in the browser only. The backend
is the same Cloudflare Worker that serves the game (`axie-dice`), with a D1 database
(`axie-dice-db`).

## 2. Player Fantasy
"My progress follows me, not my browser." Clearing the cache, opening another browser or
switching laptops never costs a run, a shard or a Vault Axie. Signing in is one button, and a
guest who signs in later keeps what they already earned.

## 3. Detailed Rules

### Sign-in (web build only)
- `CONTINUE WITH GOOGLE` navigates the whole page to `/auth/login`. No popup.
- The Worker runs OAuth authorization code + PKCE with `state` and `nonce`, held in a signed
  10-minute cookie (`ad_oauth`, Path=/auth). The code is exchanged on the server; the client
  secret and tokens never reach the page.
- The ID token is checked against Google's JWKS (RS256) plus `iss`, `aud`, `nonce`, `exp` and
  `email_verified`.
- Profile key is `google:<sub>`, never the email. `hd = skymavis.com` shows a `Sky Mavis` badge.
- Session: random token in an HttpOnly, Secure, SameSite=Lax cookie (`ad_session`,
  Domain=axiedice.fun, 30 days). Only its SHA-256 hash is stored in D1.
- `www.axiedice.fun` hops to the apex before login so the cookie domain is always the same.
- The callback returns to the game with `?auth=signed_in` or `?auth_error=<code>`; return URLs
  are restricted to the same origin.
- Desktop/editor builds have no sign-in; Settings explains that progress stays on this device.

### Guest and first sign-in
- No session → the menu offers a `Save your progress` panel once the server has answered 401.
  `Play as guest` closes it. The panel is never shown before `/api/me` answers.
- First sign-in, empty cloud, guest progress on this browser → ask: `Move progress` or
  `Start fresh`.
- Cloud already has progress and this browser has different guest progress → ask which to keep,
  showing runs / shards / Vault / last played for both. Never merge.
- Whatever is not kept is copied to a local backup profile for 7 days.

### Saves
- `SaveStore` keeps one folder per profile: guest uses the old keys
  (`axiedice:user://...`), an account uses `user://acct/<id>/...`. Switching accounts on one
  browser can never read someone else's save.
- Every write through `SaveStore` marks the account dirty; `AccountService` uploads after 3 s
  of quiet, and flushes on tab hide (best effort).
- `PUT /api/save` carries the `rev` the client last saw. A stale `rev` → 409 with the server
  copy → `This account was played somewhere else.` → `Keep this device` / `Keep cloud`.
- If the cloud copy is newer and this browser has no unsynced edits, it is adopted silently.
- Upload failure → chip shows `Offline — will sync`, retries at 5 / 15 / 60 / 120 s (then every 120 s). `Sync now` retries at once.
- Continue Run reads the run from the cloud copy, so a run started on one device can be
  continued on another.

### Sign out / switch
- Settings → Account: name, email, badge, status, `SWITCH ACCOUNT`, `SIGN OUT`.
- Sign out needs a second press. With unsynced edits the button becomes `SYNC AND SIGN OUT` and
  uploads first. The game only drops to guest after the server confirms the logout.
- Switch account = sign out + sign in with `prompt=select_account`.

### Errors
Every error has a plain sentence plus a way forward (`Try again`, `Use another account`,
`Play as guest`, `Sign in`). Mapped codes: `access_denied` (cancelled), `expired`/`state` (timed out), `network`,
`admin_policy_enforced`/`org_internal` (company block), `session_expired`, `save_failed`,
`sign_out_failed`; anything else gets a generic retry line. See `AccountService.error_message()`.

## 4. Formulas
- Upload debounce: `PUSH_DELAY = 3.0` s.
- Retry schedule: `RETRY_DELAYS = [5, 15, 60, 120]` s, then stays at 120 s.
- Local backup lifetime: `BACKUP_DAYS = 7`.
- Save body cap: 512 KB per `PUT /api/save`.
- Session lifetime: 30 days. OAuth state cookie: 10 minutes.

## 5. Edge Cases
- Signed-in session but no cached account on this browser (fresh profile, cleared storage):
  the welcome panel must wait for `/api/me`; a 200 closes any panel already open.
- Sign-in lands mid-run or on a non-menu scene: the save fetch is deferred until a safe scene.
- Two tabs or two devices writing → 409 → explicit choice, never a silent overwrite.
- Logout request fails → stay signed in and toast `sign_out_failed`, never fake a sign-out.
- Company Workspace blocks the app → `Use another account` / `Play as guest`.
- Incognito / strict cookie blocking: not tested yet. If the session cookie is dropped the player
  simply stays a guest; there is no dedicated message for it.

## 6. Dependencies
- Cloudflare Worker `axie-dice` (routes `/auth/*`, `/api/me`, `/api/save`, `/terms`, `/privacy`).
- Cloudflare D1 `axie-dice-db`: `players`, `saves`, `sessions` (`worker/migrations/0001_accounts.sql`).
- Google Cloud project `axie-dice`, OAuth client "Axie Dice Worker", redirect
  `https://axiedice.fun/auth/callback`. Secrets on the Worker: `GOOGLE_CLIENT_SECRET`,
  `SESSION_SIGNING_KEY`.
- `MetaState.reload_from_store()` and `SaveStore` (every save write must go through `SaveStore`).

## 7. Tuning Knobs
`PUSH_DELAY`, `RETRY_DELAYS`, `BACKUP_DAYS` in `AccountService.gd`; save size cap and session lifetime
in `worker/src/accounts.js`. Restricting sign-in to Sky Mavis accounts only is a one-line `hd`
check in the callback. Rate limits: `limit`/`period` of `AUTH_LIMITER` (30/60s) and
`SAVE_LIMITER` (60/60s) in `worker/wrangler.toml`; period can only be 10 or 60.

## 8. Acceptance Criteria
- `cd worker && node --test test/*.test.mjs` — 27 tests pass (4 of them cover rate limits).
- `godot/tests/t_account_sync` — 76 checks pass, including the welcome-panel regression test.
- Live QA (10 Oct 2026) passed: first sign-in moves guest progress; reload does not prompt;
  debounced upload; switch account and sign out; silent pull when another device is newer;
  conflict dialog with backup; offline then auto-upload; welcome panel never covers a
  signed-in menu.
- Not yet tested: Chrome incognito, Safari.

### Done 10 Oct 2026 (not deployed yet)
- Rate limits (Cloudflare Workers Rate Limiting binding): `/auth/login`, `/auth/callback`,
  `/auth/logout` 30/min per IP; `/api/save` 60/min per session (per IP when signed out).
  `/api/me` is not limited. Over the limit: login/callback go back to the game with
  `auth_error=rate_limited` (own message in `AccountService.error_message`); logout and save get
  429 + `Retry-After: 60`, which the game already treats as offline and retries.
- `production/privacy-preview.html` removed. "Axie Dice Dice" typo fixed on /terms and /privacy.

### Backlog (not started)
Dedicated login screen (with the final UI polish) · account chip to the top-right (both moved to
the final UI polish pass, Liam 10 Oct) · delete the old `axie-dice-fun` Worker (dashboard).
