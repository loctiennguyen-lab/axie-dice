---
name: relic-pact-risk-mispricing
description: relic-system.md's RP model prices "pact" (HP-loss-for-buff) drawbacks via linear EV, not risk; r_bloodpact is the only pact relic in RELICS and was genuinely underpriced despite passing the 2026-09-03 model. Fixed in relic-rebalance-2026-09-07.md.
metadata:
  type: project
---

On 2026-09-07 the lead relayed a second-round complaint from the product owner:
even after confirming they knew about [[relic-rebalance-already-shipped]] (2026-09-03),
they still saw a relic self-harm/trade-off as "not worth it" — example given:
"lose 20% HP for a small damage bonus."

**Verification result — this was a real, new gap, not a stale re-raise:**

- Scanned all 94 `RELICS` entries in `src/data.js` for any HP/Shield/resource-cost-for-buff
  mechanic. Exactly **one** relic matches: `r_bloodpact` (LEGENDARY, `cat:'pact'` per
  `relic-system.md` §3.1 — pact is LEGENDARY-only by taxonomy, and the roster only ships one).
  No COMMON/RARE/EPIC relic has a drawback field.
- `relic-system.md` §4.5 example 6 already ran the RP math on `r_bloodpact` and stamped it
  "=" (no change needed): reward 42.0 (from `dmgMult:1.6`) minus a **linear-EV** drawback
  of -6.4 (from -25% Max HP) = net 35.6, inside the LEGENDARY band [31.77, 42.97].
- The bug: `startCombat()` (`engine.js:385`) rebuilds `s.party` via `buildUnit()` **every
  fight**, and `buildUnit()` always ends `u.hp=u.maxHp` (full heal to the *now-lower* ceiling,
  `engine.js:77`). So the drawback is not "you enter fights wounded" — it's "your Max HP
  ceiling is permanently 25% lower for every remaining fight of the run," raising total-wipe
  probability (`checkEnd`, `engine.js:945`) at every future encounter, not just absorbing less
  damage in one representative fight. The RP model's linear-EV term only prices the latter.
- Proposed fix (written to `design/gdd/relic-rebalance-2026-09-07.md`): add a `κ_risk = 2.0`
  correction multiplier on `pact`-type permanent-resource-loss drawbacks (mirrors the existing
  `κ_rng`/`κ_dot` correction pattern already used for APEX/INFERNO in §4.7 of `relic-system.md`,
  just inverted — those make relics *cheaper*, this makes a drawback *cost more*). Re-solving
  with `κ_risk` shows `r_bloodpact` at 25% HP loss actually prices to 29.2, *below* the
  LEGENDARY floor — i.e. the player pays more risk than the reward is worth, matching the
  complaint exactly. Recommended concrete fix: drop the HP cost from 25% → 15% (keep
  `dmgMult:1.6` unchanged), landing at 34.32 RP under the risk-adjusted model.
- Also cross-checked three relics `relic-roster-expansion.md` had flagged pre-implementation as
  "too weak"/"way over cap" (`r_hivequeen`, `r_dawnlance`, `r_ironmaiden`) against current
  `data.js` — all three already match their documented fixes exactly. No further action needed
  there; this confirms the 09-03 pass is otherwise solid and the pact-drawback formula gap was
  the one real thing it missed.
- A related but out-of-scope trade-off exists in `EVENTS` (not `RELICS`): the LUNACIA SHRINE
  "wager" option costs 20% Max HP for a random Legendary relic. Same underpricing logic likely
  applies, but it's a different data structure/system than `RELICS` and was left as a flagged
  follow-up, not fixed in this pass (the request was explicitly scoped to the `RELICS` variable).

**Why this matters**: [[relic-rebalance-already-shipped]] correctly established that most
"relics feel messy" complaints were already resolved by the 09-03 taxonomy/mload/ex rework — but
that doesn't mean *every* complaint post-09-03 is stale. This one held up under verification
because it's a genuinely different kind of bug: not a missing dedup/tier-cap rule, but a
methodological gap in how the RP formula itself treats permanent-resource-loss drawbacks (EV vs
risk). The lesson: when re-verifying an "already shipped" claim, check whether the specific
mechanism behind a fresh complaint was covered by the prior fix's *scope*, not just whether the
prior fix happened at all.

**How to apply**: if `pact`-category relics are added in the future (`relic-roster-expansion.md`
or later), they must be priced through the `κ_risk` formula in
`relic-rebalance-2026-09-07.md` §4, not the original linear-EV formula in `relic-system.md` §4.5.
