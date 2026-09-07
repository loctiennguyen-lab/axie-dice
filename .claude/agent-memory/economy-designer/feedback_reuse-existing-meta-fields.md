---
name: feedback-reuse-existing-meta-fields
description: This project strongly prioritizes reusing existing META fields/hooks over adding new tracking state — apply this by default when designing gates or missions
metadata:
  type: feedback
---

The project (Axie Dice Tactics) has an established, repeatedly-applied norm:
when a new gate/mission/threshold is needed, prefer reusing an existing
persisted field or existing run-lifecycle hook over inventing a new one.

**Why:** `design/gdd/world-tour.md` explicitly justifies reusing `META.ascMax`
(already tracked, already incremented on run-win) for THREE different gate
purposes (in-map landmark, cross-map hard gate, Gold badge threshold) rather
than adding new tracking fields, citing "không bịa cơ chế mới nếu tránh được"
(don't invent new mechanics if avoidable) as an explicit design principle. I
followed the same logic on 2026-09-07 when speccing the Daily Mission (single
new field `META.dailyDate`, reusing the existing run-end hook where
`META.runs++`/`META.wins++` already fire, instead of adding per-day sub-quest
counters for things like "kill 1 elite") and the revised Echo Box gate (removed
`collectionComplete()` entirely rather than swapping in a different tracked
milestone, relying on the existing Shard-balance check instead).

**How to apply:** Before proposing any new META field or new counter for a
gate/mission/reward condition, check whether an existing field (run count,
win count, ascMax, boss/relic/face collection arrays, shard balance) already
implies the same condition. Only add a new field when no existing signal can
serve, and keep new fields to the minimum needed (prefer a single field over a
boolean+counter pair when the single field's absence/inequality already encodes
both states, as with `dailyDate`).
