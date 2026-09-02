# Design: Minimal Telemetry & Admin Dashboard

## Status
Draft — awaiting studio-lead approval. **No code has been written for this design.**

## Owner / Reports
Authored by `analytics-engineer`. Depends on ADR-0002 (player accounts) for
identity; reuses ADR-0001/ADR-0002 infrastructure (Vercel Functions + Upstash
Redis free tier). No new vendor.

## Scope Guardrail
This is a beta-scale indie project (dozens–low-thousands of DAU, Upstash
**free** tier: bounded command count/day and bounded storage). This design
deliberately avoids: a raw event log warehouse, Segment/Amplitude/PostHog,
any ETL/batch job, and any new client dependency. If the project outgrows
free-tier limits, see "Future Escalation Path" at the end — that is
explicitly *not* today's recommendation.

---

## 1. What to Track — Event Schema

Four event types, chosen to answer exactly the studio lead's stated
questions (player count, progression funnel, DAU/retention, avg wave
reached) and nothing else. Every field has a stated purpose; no
kitchen-sink taxonomy.

| Event | Trigger | Fields | Purpose |
|---|---|---|---|
| `account.created` | Successful `POST /api/auth.js {action:'register'}` | `username` (server-verified), `ts` (server-stamped) | Total player count, signup rate over time |
| `session.login` | Successful `POST /api/auth.js {action:'login'}` | `username` (server-verified), `ts` (server-stamped) | DAU/WAU/MAU, retention cohorts |
| `run.started` | Client calls `startRun()` (src/ui.js) | `username` (server-verified via token), `mode` (`short`\|`full`), `ascension` (0-10), `ranked` (bool), `ts` (server-stamped) | Funnel numerator: how many runs begin; segment by mode/ascension/ranked |
| `run.ended` | Client reaches `phase==='won'`/`'lost'`, or player explicitly quits to menu mid-run | `username`, `mode`, `ascension`, `ranked`, `outcome` (`win`\|`loss`\|`quit`), `wave` (final `s.step` reached), `durationMs`, `ts` (server-stamped) | Funnel denominator, win rate, avg/median wave reached, avg run duration |

Naming follows the project's `[category].[action].[detail]` convention
(`account.created`, `session.login`, `run.started`, `run.ended`).

**Deliberately not tracked:** individual UI clicks, screen views, per-turn
combat actions, device/browser fingerprinting, IP addresses, or any new PII.
`submit-run.js` already has a full replay log for Ranked Run anti-cheat —
telemetry does not duplicate that; it only needs coarse start/end signals
for *all* runs (ranked and casual), which `submit-run.js` doesn't cover
since Ranked Run is an opt-in toggle most runs don't use.

**Abandonment, not a separate event type:** a run that never sends
`run.ended` (browser closed, crash, network loss) is *implicitly* an
abandoned run — visible in aggregation as `runs_started - runs_ended`. This
avoids needing `beforeunload`/`sendBeacon` reliability work for a v1. A
player choosing "quit to menu" mid-run *does* send `run.ended` with
`outcome:'quit'`, so we can distinguish a clean quit from a silent
disappearance if that distinction becomes useful later.

---

## 2. Where It Lives — Storage Approach

**Recommendation: pre-aggregated counters only, no raw event log.**

Weighing the two options:

- **Raw event log (append-only list/stream, query later)**: flexible for
  ad-hoc future questions, but every event adds to Upstash storage forever
  (or needs manual TTL/trimming discipline), and answering "avg wave
  reached" requires pulling and processing potentially thousands of
  entries client-side or in a function on every dashboard load — more
  Redis commands per *read*, not just per write.
- **Pre-aggregated counters (increment on write)**: fixed, small number of
  Redis keys regardless of player count or time elapsed. Dashboard reads
  are O(1) `HGETALL`s. The tradeoff is that the schema of *what's
  aggregated* is fixed at write time — you can't retroactively ask a new
  question the counters don't cover. Given the stated questions are known
  and fixed, this tradeoff is acceptable and is the right fit for free-tier
  storage limits.

Every stated question (player count, funnel, avg wave, DAU/retention) is
answerable with **histograms and sums**, not individual records — so
pre-aggregation loses nothing here. This is the hybrid pattern in disguise:
"histogram bucket per possible value" gives distribution-shape answers
(e.g. wave-reached distribution) without storing one row per run.

### Redis Key Layout

All keys use Redis **HASH** (`HINCRBY`) so a whole day/scope is one key,
keeping key-count bounded (important on free tier — key count and command
count both matter, not just bytes).

```
tel:totals                          HASH, all-time global counters:
  accounts_created
  logins
  runs_started
  runs_started:ranked
  runs_ended:win
  runs_ended:loss
  runs_ended:quit
  duration_sum_ms                   (sum of all run.ended durationMs)
  duration_count                    (count, for avg = sum/count)

tel:totals:wave                     HASH, all-time wave-reached histogram:
  0, 1, 2, ... 59, "60+"            each field = count of run.ended at that wave

tel:d:<YYYY-MM-DD>                  HASH, same fields as tel:totals but per UTC day
  (accounts_created, logins, runs_started, runs_ended:win/loss/quit, ...)

tel:dau:<YYYY-MM-DD>                SET of usernames active that day
                                     (added on login OR run.started; EXPIRE 90d)

tel:players                         SET of all usernames ever seen
                                     (for lifetime unique player count; SCARD)
```

**Cost estimate at beta scale** (e.g. 200 DAU, 5 runs/player/day = 1000
runs/day): ~1000 `run.started` + ~1000 `run.ended` events/day, each ~2-4
`HINCRBY`/`SADD` calls → ~6,000 Redis commands/day for telemetry. Well
within Upstash's free-tier daily command allowance, and storage stays flat
(a few dozen hash/set keys total, not one per event) — it does not grow
unbounded with usage, only `tel:dau:*` accumulates one key per day (bounded
by the 90-day `EXPIRE`) and `tel:players` grows one entry per unique
player (small at this scale; a few thousand usernames is trivial storage).

If growth later makes even this too chatty, the client-side mitigation is
batching (queue `run.started`+`run.ended` and flush together, or sample
a percentage of sessions) — not a redesign of the storage model.

---

## 3. How It's Collected

**New endpoint: `api/telemetry.js`.** Reasoning against piggybacking:

- `account.created` and `session.login` **do** piggyback — zero extra
  client calls. Add the `HINCRBY`/`SADD` calls directly inside the existing
  `api/auth.js` register/login handlers, right after the existing Redis
  writes succeed. No new endpoint, no new round trip.
- `run.started`/`run.ended` **cannot** piggyback on `api/submit-run.js`,
  because that endpoint only fires for Ranked Run submissions, and Ranked
  Run is an opt-in toggle most runs don't use (`pickRanked` defaults off —
  see `src/ui.js` line ~1015). Casual/practice runs are the majority of
  play and need coverage too. There's no existing endpoint that fires at
  "a run started" or "a non-ranked run ended," so a new endpoint is
  required for those two events.

`api/telemetry.js` — single `POST` endpoint, small and dumb by design:

```
POST /api/telemetry.js
Headers: Authorization: Bearer <token>   (same JWT as sync-save.js)
Body:    {type: 'run.started', mode, ascension, ranked}
      or {type: 'run.ended',   mode, ascension, ranked, outcome, wave, durationMs}
Response: {ok:true}  (always 200 unless malformed; never blocks gameplay)
```

- **Identity is never client-supplied.** `username` comes from
  `verifyToken()` (reused from `api/_auth.js`), exactly like
  `sync-save.js` — the same trust boundary already established for
  accounts, no new spoofing surface there.
- **`ts` is always server-stamped**, never trusted from the client (same
  rule ADR-0002 already established for `savedAt`).
- **Client trust for `mode`/`ascension`/`outcome`/`wave`/`durationMs`**:
  these *are* spoofable — a player could send `wave: 999` — but this
  matters far less here than in `submit-run.js`, because telemetry is not
  competitive (it doesn't feed the leaderboard or unlock anything) and a
  single player spoofing a few data points has negligible effect on an
  aggregate histogram across hundreds of runs. Cheap sanity clamps are
  still worth adding for data-quality (not anti-cheat) reasons, mirroring
  the shape validation already in `submit-run.js`:
  - `mode` must be `'short'|'full'`, `ascension` integer 0-10 (reject
    silently, i.e. drop the event, don't 400 and risk a console error
    loop — telemetry failures must never be player-visible).
  - `wave` clamped to `[0, 60]` before bucketing into the histogram (a
    `60+` bucket absorbs outliers rather than polluting a `999` field).
  - `durationMs` clamped to a generous max (e.g. 4 hours) before being
    added to the sum, so one bogus value can't skew the average
    meaningfully.
- **Never blocks or slows gameplay.** The client fires these as
  fire-and-forget (`fetch(...).catch(()=>{})`, no `await` in the render
  path), same graceful-degrade philosophy as `sync-save.js`'s
  `stored:false` handling — telemetry being down must never be visible to
  a player.
- **Guests**: recall accounts are now mandatory (ADR-0002 amendment) — every
  player reaching PLAY has a token, so there's no guest-mode gap to design
  around.

---

## 4. How the Studio Lead Views It

**Recommendation: a small admin-only endpoint + a static HTML page.**
Reuses this project's own no-framework/no-build-tool convention — no
dashboarding dependency, no separate deploy.

- **`api/admin-stats.js`** — `GET`, requires a separate admin secret (new
  env var `ADMIN_DASHBOARD_TOKEN`, checked via a simple header compare —
  *not* a player JWT, since this exposes aggregate data across all
  players and has no need to be tied to a specific player account). Reads
  the `tel:*` keys above (`HGETALL tel:totals`, `HGETALL tel:totals:wave`,
  `HGETALL tel:d:<date>` for the last N days, `SCARD tel:players`, `SCARD
  tel:dau:<date>` for the last N days) and returns one aggregate JSON
  blob. This is a handful of Redis reads per dashboard load, not per
  visitor-of-the-game, so cost is negligible regardless of player count.
- **`tools/admin-dashboard.html`** (or `production/` — open question,
  see below) — a single static HTML file, same DOM/CSS/vanilla-JS style
  as the rest of the project, no `<canvas>`/charting library required for
  v1 (simple bar rows built from `<div>` widths, or a `<table>`, are
  sufficient at this data volume). Prompts for the admin token once
  (stored in `localStorage` for convenience, same pattern as the player
  session token), fetches `/api/admin-stats.js`, renders:
  - Player count (lifetime unique, `tel:players` SCARD)
  - DAU sparkline (last 30 `tel:dau:<date>` SCARDs)
  - Signups/logins per day (last 30 days from `tel:d:<date>`)
  - Funnel: runs started → runs ended (win/loss/quit) → implied abandoned
  - Win rate, avg run duration
  - Wave-reached histogram (bar per wave 0-60, "60+" bucket)
- Not served to players; not linked from the game's own HTML/menu. Kept
  out of `build.py`'s single-file assembly entirely — it's a separate,
  small static file, deployed alongside but never bundled into the game.

**Open question for studio lead**: where should this file live —
`tools/admin-dashboard.html` (fits "build/pipeline tools" per
`.claude/docs/directory-structure.md`) or a new `admin/` top-level
directory? I'd default to `tools/` unless you'd rather keep it elsewhere.

---

## 5. Answering the Stated Questions

| Question | How |
|---|---|
| **How many players do we have?** | `SCARD tel:players` (lifetime unique accounts that ever logged in or registered) |
| **What does progression look like?** | `tel:totals:wave` histogram gives the shape of "how far do players get" in aggregate across all runs. For per-account progression detail (Shards, Unlocks, Vault), that already lives in each player's `save:<username>` META blob (existing `sync-save.js`) — telemetry doesn't duplicate it, but the admin dashboard could optionally spot-check individual saves by username if needed (out of scope for v1 unless requested). |
| **What wave/level do players typically reach before quitting?** | Median/mode of `tel:totals:wave` histogram — directly answers "typical" without needing raw per-run rows. Combined with `runs_started - runs_ended` (implied abandons) vs. explicit `outcome:'loss'` at a given wave, this also distinguishes "died at wave N" from "walked away at wave N." |
| **DAU / retention?** | DAU = `SCARD tel:dau:<date>` per day. A rough Day-N retention (e.g. Day-1, Day-7) can be approximated by intersecting `tel:dau:<date>` sets (`SINTERSTORE`/`SINTERCARD` on cohort start date vs. date+N) — cheap, bounded by the 90-day SET expiry. True per-player cohort retention (exact signup-date cohorts tracked indefinitely) is a heavier ask than free-tier SET intersection comfortably supports at scale; flagged as a "if this matters more, revisit" item rather than solved fully in v1. |

---

## 6. Privacy / Scope

No new PII is collected. `username` is the same authenticated identifier
already required for login (ADR-0002) — telemetry only *counts* against it
in aggregate buckets (`tel:players`, `tel:dau:*` sets store usernames, but
solely for unique-counting; no event carries email, IP, device
fingerprint, or any field beyond what's listed in §1). No new consent flow
is needed beyond what mandatory account creation already requires,
per this project's existing accounts scope. If the studio later wants an
explicit telemetry opt-out separate from account creation itself, that's a
product decision to raise with `producer`/`game-designer`, not assumed
here.

---

## 7. Future Escalation Path (not today's recommendation)

Only relevant if Upstash free-tier limits are actually hit (command count
or storage) or if questions arise that fixed aggregate counters can't
answer (e.g. "show me the exact sequence of events for player X's last
session"). At that point, options in increasing cost/complexity:
1. Upstash paid tier (same architecture, higher limits, still no new code).
2. Add a *capped* raw log (e.g. last 500 `run.ended` events in a Redis
   LIST, trimmed via `LTRIM`) purely for spot-checking/debugging, without
   replacing the aggregate counters.
3. A hosted analytics tool (PostHog free self-serve tier, etc.) if the
   studio wants funnels/cohorts/session replay beyond what a home-grown
   dashboard can reasonably offer.

None of these are proposed for implementation now.
