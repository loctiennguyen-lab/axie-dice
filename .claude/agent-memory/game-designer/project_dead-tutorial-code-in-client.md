---
name: dead-tutorial-code-in-client
description: A 5-slide text-only tutorial overlay already exists in client.html but is unreachable (dead code) — nothing sets tut=1. META.tut (0/1) already exists in DEF_META and is reusable as the new mandatory-tutorial-completed flag.
metadata:
  type: project
---

`src/client.html` already contains a tutorial system, but it is orphaned/dead:
- `const TUT=[...]` (~line 5028) — 5 static title+paragraph slides (exactly the
  "screen full of text" format the 2026-09-08 tutorial task explicitly said to avoid).
- `function tutOverlay()` (~line 5035) renders one slide at a time with NEXT/SKIP/PLAY,
  incrementing module-level `let tut=0` (~line 2355) and writing `META.tut=1` on
  finish/skip.
- Only call site: `if(tut&&screen!=='menu') document.body.appendChild(tutOverlay());`
  in `postRender()` (~line 3164). Nothing else in the codebase ever sets `tut=1` —
  grepped the whole file. So this overlay can never actually open for a real player.
- A comment at ~line 3958-3959 claims "the tutorial ... now lives in CODEX, reachable
  from the menu" — this is **stale/inaccurate**: `scCodex()`/`CX_BODY` (a genuinely
  good, but purely voluntary, text reference screen — "Every rule in the game.
  Nothing is hidden.") has no button wiring `tut=1` anywhere. Same misleading-comment
  pattern as [[dawn-dusk-mech-identity-gap]].

**Why this matters:** the 2026-09-08 tutorial-design task briefing said "game currently
has NO tutorial" — true in effect (no real player ever sees one), but not literally
accurate, and there is real cleanup debt here (dead `TUT`/`tutOverlay`/`tut` local var,
stale comment) that should be called out to whoever implements the new mandatory
tutorial, separately from the new feature itself.

**Reusable asset:** `DEF_META` (~line 2360) already has `tut:0` in its schema. The
new mandatory-tutorial design (draft discussed 2026-09-08, not yet written to a GDD
file) recommends **reusing `META.tut`** (0=not completed, 1=completed) as the gate
flag rather than inventing a new field name — it already has the right semantics.
Recommend renaming the *local* step-counter variable (currently also called `tut`)
to something like `tutStep` to avoid the same name meaning two different things.

**How to apply:** before assuming "no tutorial exists" or trying to wire into the
existing `TUT`/`tutOverlay`, read this memory first — the old system is dead weight,
not a foundation to build on. Any new tutorial GDD/implementation should either
delete this dead code or explicitly repurpose it, not leave two orphaned systems
sharing the name "tutorial."

**Resolved 2026-09-08**: GDD written at `design/gdd/onboarding-tutorial.md`
(Status: Draft — chờ implement). Decision locked in: DELETE `TUT[]`/`tutOverlay()`/
module-level `tut` entirely (no dual-system), reuse `META.tut` as the completion
flag, rename the step counter to `tutStep`. Gate is `!META.tut && META.runs===0`
with no exception for Vault-import-only accounts. Mock battle uses the full 5-Axie
party strip via `newGame(TUT_SEED, TUT_TEAM, opt)`. Implementation not yet started
— next owners are `ui-programmer` (client.html screen/overlay/gate wiring) and
`gameplay-programmer` (any engine.js touch, `tools/t_tutorial.mjs`).
