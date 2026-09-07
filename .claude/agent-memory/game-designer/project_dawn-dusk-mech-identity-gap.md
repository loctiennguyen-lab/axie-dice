---
name: dawn-dusk-mech-identity-gap
description: Dawn/Dusk/Mech (Axie Origin's 3 secret classes) already have a documented, implemented, product-owner-mandated design (keep mapped passive, compensate via signature parts) — the real unshipped gap is a UI identity badge, not a missing passive/buff.
metadata:
  type: project
---

`design/gdd/part-skill-identity.md` §3.10 ("Secret class — dawn / dusk / mech",
Revision 3, 2026-09-03, author `game-designer`) already answered the question
"should Dawn/Dusk/Mech get their own identity/passive?" — and reached the
**opposite** conclusion from a later request (2026-09-07) to give them one
shared new passive:

1. **Class mapping is a hard constraint from the product owner**: `ORIGIN_CLASS_MAP`
   (`dawn:'beast', dusk:'reptile', mech:'bug'`, `src/data.js:230`) stays so the
   Axie's "bản sắc class vẫn đọc được" (class identity stays legible) — a Dawn
   Axie keeps FERAL, Beast HP curve, Beast color. This is not an oversight,
   it's a decision already signed off.
2. Compensation instead happens at the **part** level: the 18 real Dawn/Dusk/
   Mech part identities across the whole game get hand-designed **Signature**
   faces (not generic family variants), bucket `X` (`S.X = 1.467` in
   `assets/data/part_faces_tuning.json:12`, vs `S.C = 1`), `r=3`, and are
   explicitly tuned to synergize with the *mapped* passive (with "one allowed
   off-axis deviation" per part for flavor, e.g. a Beast-mapped part with
   Shield even though Beast normally never has Shield).
3. This is **already implemented**, not just designed: `src/part_faces.js` +
   `assets/data/part_faces.json` exist and are read live by
   `resolveFace()`/`coherenceMod()` in `src/engine.js`.

**The actual shipped gap is presentational, not mechanical**: §3.10 point 3
calls for a UI label "◈ SECRET" on these parts/axies — grepped `src/client.html`
for `◈`/`SECRET`, **zero matches**. It was designed but never wired into any
screen. Worse, `src/client.html:2519` (Vault import note, added 2026-09-07)
reads `die.cls` (the mapped class) and will literally tell the player
`"This is a real Beast Axie — it already carries full FERAL"` for an Axie that
is actually Dawn — a factually misleading line for exactly the population
§3.10 tried to protect.

Also noted: `ORIGIN_TIER3_MULT = 2.2` (`src/data.js:231`) is **dead/stale
code** — not referenced anywhere in `engine.js`'s actual value computation
(`partBudget`/`resolveFace`/`axieToDie`), only in a stale comment and an
export. `part-skill-identity.md:60` already flags it for deletion, superseded
by `S[bucket]`. It does not currently double-count with bucket X.

**Why this matters**: before agreeing to design a NEW passive for Dawn/Dusk/
Mech (a real ask that came in 2026-09-07), check whether the actual complaint
is (a) players not seeing Dawn/Dusk/Mech's real identity anywhere — already
decided against a new passive, fixable by shipping the existing §3.10 UI
label + fixing the client.html:2519 line — or (b) a genuine mechanical power
gap — which the data does not support, since these axies already get full
mapped passive + a ~47% part-value premium + guaranteed r3 signature faces.
See [[class-passive-already-universal]] for the related prior finding that
collectibles may already be ahead of same-tier Heroes on power alone.

**How to apply**: If a future request proposes touching Dawn/Dusk/Mech
identity or power, read §3.10 in full first and ask the requester whether
they are aware of it / intend to reverse the product-owner hard constraint,
rather than treating the request as a green-field design problem.
