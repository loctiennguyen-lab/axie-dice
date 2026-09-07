---
name: relic-rebalance-already-shipped
description: The "94 relics are messy/unbalanced" complaint was already fully addressed by relic-system.md (2026-09-03) + relic-roster-expansion.md, implemented in src/data.js/engine.js, and machine-verified — check before starting a fresh rebalance pass.
metadata:
  type: project
---

On 2026-09-07 the lead relayed a request to review all 94 relics in `src/data.js`
(`RELICS`) because "relics haven't been touched, still feel messy/thrown-together."
Verification against the repo showed this premise is **stale**:

- `design/gdd/relic-system.md` (2463 lines, authored 2026-09-03) is a complete
  relic rebalance: 5-type taxonomy (`scale`/`rule`/`engine`/`act`/`pact`), an RP/VPM
  budget model deriving relic power from formulas (not designer taste), anti-stacking
  (`mload` cap 2) and de-duplication (`ex`/`exSub` tokens) laws, an 11-archetype
  coverage goal, and — critically — **§3.12 Tier Monotonicity**, an invariant that no
  lower-rarity relic can be stronger than a higher-rarity one, which the doc states
  explicitly is *"the product owner's complaint … turned into arithmetic."* This is
  the same complaint as the 2026-09-07 request, word for word.
- `src/data.js` `RELICS` array **already matches this design exactly**: 78 passive +
  16 active = 94, with `mload`, `ex`, `exSub`, `mfPhase` fields present on every entry
  as the doc specifies — this is not a coincidence, the redesign was implemented.
- `tools/t_relic.mjs` machine-verifies INV-1 (rarity-band RP disjointness) against
  both GDDs and the live `data.js`/`engine.js`; `.claude/docs/technical-preferences.md`
  records this suite at 94/94 (measured 2026-09-04, one day after the doc was
  authored), plus `t_relic_behaviour.mjs` at 38 behavioral proofs.
- `design/gdd/systems-index.md` still lists Relic System as "Draft for review (chưa
  duyệt)" — **this status label is stale**, since the design was clearly implemented
  and tested days ago. Flag this mismatch if seen again.

**Why this matters**: don't re-run a full from-scratch 94-relic audit on a fresh
ask that sounds identical to an already-solved complaint — check `t_relic.mjs`/
`t_relic_behaviour.mjs` results and `relic-system.md` §14 (product owner decisions)
first. See [[feedback_lead-vietnamese-design-consult]] for why verifying stale
premises matters with this requester specifically.

**How to apply**: if a future request re-raises "relics are unbalanced/messy," first
check whether it predates or postdates 2026-09-03. If postdates, ask for *specific*
relic IDs/names still considered problematic rather than redoing the full pass —
the systemic issues (stacking, dedup, tier power inversion) are already fixed.
