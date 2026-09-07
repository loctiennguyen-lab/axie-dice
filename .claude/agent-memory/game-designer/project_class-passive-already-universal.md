---
name: class-passive-already-universal
description: PASSIVE (class-wide archetype trait) already applies to Vault/import axies in the live combat path, not just Heroes — contrary to how the feature request was originally framed.
metadata:
  type: project
---

`PASSIVE` (`src/data.js:54-61`, one entry per class: plant BULWARK, beast FERAL,
aqua CONDUIT, reptile SCALES, bug VIRULENT, bird TALON) is commonly assumed to be
Hero-only. It is **not**, as of 2026-09-07: `buildUnit()` (`src/engine.js:60-79`)
attaches `pas:PASSIVE[h.cls]` computed fresh from `h.cls` — it never reads a
stored `pas` field. Vault/import axies get registered into the same `HEROES`
table via `ensureVaultHero()` (`src/client.html:2455-2459`, comment: "played
exactly like a T1 hero, with zero engine changes"), so `h.cls` resolves and the
class passive is attached automatically. `mapAxieClass()` (`engine.js:98-104`)
guarantees `cls` is always one of the 6 canonical keys (fallback `'beast'`), so
`PASSIVE[h.cls]` is never undefined. `archScore()` (`engine.js:1230`) reads
`PASSIVE[HEROES[e.key].cls].a` — same generic lookup, so the archetype tracker
already counts collectible axies correctly too.

The only object that truly lacks `pas` is the *raw* return value of
`axieToDie()` itself (used only for the import-preview screen and server-side
replay — never instantiated as a combat unit directly).

Corroborating evidence this is intentional, not an oversight: the relic
`r_scalecrown` (`data.js:671`, dev note at 668-670) already reasons about
SCALES applying broadly and explicitly protects against the Thorns-floor clause
becoming a dead draw — written as if the author already knew reptile-class
units (including imports) already have SCALES.

**Why**: A user request came in framed as "make PASSIVE universal across Hero
+ import" as if this needed to be built. It doesn't — it's already live
behavior, just undocumented as an explicit invariant anywhere in `design/gdd/`.

**How to apply**: Before agreeing to "add class passive to imports" work in
this project, verify current behavior first (`buildUnit`/`archScore`, or a
quick `tools/sim.js` check) rather than trusting a feature-request summary.
If asked to design a NEW "light bonus for collectible axies," treat it as
additive on top of an axie that is *already* both (a) intrinsically boosted by
partBudget/coherenceMod/geneMult and (b) already carrying its full class
passive for free — i.e. collectibles may already be ahead of same-tier Heroes
before any new bonus is added. Recommend measuring relative power
(`/balance-check`) before adding more, not after. See [[feedback-lead-vietnamese-design-consult]].
