---
name: project-relic-system-inv1
description: Axie Dice Tactics relic balance is governed by INV-1 non-overlapping RP bands; roster is 94, implemented and green, with exSub/dead-draw work outstanding
metadata:
  type: project
---

Relic balance in Axie Dice Tactics is governed by **INV-1**: RP bands per rarity that
do not overlap by construction. `Band[r] = [C_r × 0.85, C_r × 1.15]`, `C_r = 13.2 × SIG[r]`,
`SIG = [1, 1.4154, 2, 2.8308]`. Disjointness requires `(1+τ)/(1−τ) < 1.4130`; `τ = 0.15`
gives 1.3529, while the old `±20%` gave 1.50 — overlap was arithmetically certain.

**Why:** the product owner's complaint was *"buff tier dưới mạnh hơn tier trên"* (lower-rarity
relics stronger than higher-rarity ones). INV-1 is the quantified form of that complaint,
so band violations are the highest-priority class of balance bug, above "feels wrong".

**Status as of 2026-09-04.** Roster is **94** (78 passive + 16 active), shipped in `src/data.js`,
`tools/t_relic.mjs` exits 0 `gate: GREEN`, 94/94 satisfy INV-1. Measured hero winrate 16.3%,
all-vault 24.3% — inside the framework's predicted 14–17% band for the `mload` cap, untuned.

**Doc ownership is split and must not be duplicated.** `relic-system.md` owns the framework;
`relic-roster-expansion.md` owns the 50 new relics — including their `mload`/`ex` (§3.11), whose
single source is roster **§17.2**. The framework ratifies §17.2 by reference in §6.7.9 rather than
copying 48 rows, because two copies of a balance invariant drift. Framework changes can *cancel*
previously-mandated roster changes — check for knock-ons before assuming an audit instruction holds.

**Engine constraints that repeatedly matter:** relic fields must actually be read in
`src/engine.js` (INV-9; a field nobody reads is DEAD and hard-fails). `cat` is documentation-only
and must never ship — note the trap that `r.cat` at `ui.js:967/996` is a *cosmetic* category from
`fuseCosmetics()`, a different object. The kwPure Direction Law sends keywords to the *face's
target*. Actives reset every turn (`s.usedActives=[]` after `s.turn++`) so mana is the only limiter
and `cost` is a stronger knob than `v`. Flat bonuses must be added *after* multipliers
(`thornsPlus` ENG-4, `critFlat` ENG-21) or they inflate out of band.

**`exSub` (§3.7a, ruled 2026-09-04) is the newest framework concept.** Measurement over the *real*
face population found 4 live dead-draw pairs where the docs predicted 0: `r_spines` ≡ `r_scalecrown`
(identical `thorns ≥ 2` floor → symmetric `ex`), and three strict subsets `r_pierceall` ⊂
`r_worldpiercer`, `r_gorehook` ⊂ `r_apexferal`, `r_windlash` ⊂ `r_stormcall`. Subsets need
**asymmetric** `exSub`, not shared `ex`: a shared token would let a COMMON block a LEGENDARY and
invert progression. Known unclosed limit: taking the subset first still strands it retroactively
(needs refunds = real content). `ex` tokens are mostly single-owner **on purpose** — `KW_EX` fires
them from party face keywords, and `poisonAmpFlat`/`poisonAmpPct` are a designed non-colliding
pair — so never "clean up" single-owner tokens.

See [[no-hand-tallying]] for the verification discipline (AC-25) this system now mandates.
