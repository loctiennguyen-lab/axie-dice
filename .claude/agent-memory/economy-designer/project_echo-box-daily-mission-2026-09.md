---
name: project-echo-box-daily-mission-2026-09
description: Axie Dice Tactics — Echo Box gate rework and Daily Mission spec, decided/written 2026-09-07 in design/gdd/economy-progression.md §10.3
metadata:
  type: project
---

Two amendments written to `design/gdd/economy-progression.md` §10.3 on
2026-09-07 (design-only; no code changed — this is a handoff spec for
`gameplay-programmer`/`ui-programmer`):

**Echo Box gate v3** (this is the SECOND gate-philosophy change; v1 was
"100% Collection Log" as an end-game reward, 2026-09-01/02): removed
`collectionComplete()` as a requirement entirely (both call sites:
`echoBoxOpen()` `client.html:2368`, `scEchoBox()` `client.html:3056`). New
gate = none — only the existing `shards >= cost` check applies. Box #1 price
cut to a new constant `ECHO.introCost = 50` (vs. the existing `echoCost(1)=500`
formula); box #2 onward reverts unchanged to `echoCost(n)` (`base=500,
growth=1.035`). Rationale: product owner wants Gene-Shard-only, very-light
threshold (see [[feedback-no-new-currency-prefer-gene-shard]]), and this
doesn't meaningfully compete with in-run Merchant/shop-reroll spend since
Echo Box is a meta-only screen, not accessible mid-run.

**Daily Mission** (mechanic listed in the approved faucet table since before
2026-09-01 as "Nhiệm vụ ngày +60/ngày" but never implemented — confirmed by
lead on 2026-09-07 that there is currently NO way to earn Gene Shard outside
of playing a run): spec'd as a single mission ("complete 1 run today, win or
lose"), UTC-day reset, no streak bonus, no catch-up for missed days, one new
META field `dailyDate` (string, last UTC date the +60 was granted), granted at
the same run-end hook that already does `META.runs++`/`META.wins++`. Reward
stays exactly +60/day (no change to the already-approved economy baseline of
~156 Shard/run).

**Why this matters going forward:** if a future session is asked to implement
either of these, the design doc section is the source of truth — read
`design/gdd/economy-progression.md` §10.3 (search "2026-09-07") rather than
re-deriving the numbers. If asked to *change* the +60/day figure or the
Echo Box intro price, treat that as a new decision requiring explicit
product-owner sign-off and flag it as an amendment to an already-approved
number (same pattern used throughout this doc's revision history, see its
§Phụ lục C).
