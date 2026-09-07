---
name: project-axiedice-echobox-chest-gacha
description: Echo Box "double gacha" chest-tier redesign AND full screen/ceremony UX redesign — specs at design/quick-specs/ and design/ux/echo-box.md; naming collision resolved (Rank vs Chest)
metadata:
  type: project
---

**Status (2026-09-07, third pass): DONE, written to file.** A second spec now
exists: `design/ux/echo-box.md` — full screen-and-ceremony redesign (PM called
the current UI "cực kì xấu", asked for Genshin-wish-style ceremony). Covers:
pulling Echo Box out of `scCollection()` into its own `screen==='echobox'` +
menu tile (Collection keeps only a slim pointer row); a real-art hero banner
sampled from `COSMETIC_POOLS` (owned=full-color, unowned=same art dimmed via
CSS filter, not a "???" blackout — deliberately different from Collection's
locked-item convention, because a gacha banner's job is to create desire, not
just track inventory); a two-line `.echopull` primary button (label + cost
inside the button, not above it); re-staged (not restructured) choreography
for the EXISTING chest→cosmetic 2-step reveal, with a full rarity-tiered
FX/SFX matrix for the cosmetic reveal that deliberately mirrors the existing
Mythic-reveal precedent at `client.html:2848-2849` rather than inventing a new
one, and keeps chest-grade drama on separate SFX (`SFX.boss()` for Lunacian,
never `SFX.mythic()`) so "Chest" and cosmetic "Rarity" don't blur into one
signal; a new pull-history log (`localStorage` key `axiedice_echolog_v1`,
pattern copied from `scHistory()`); the Rank meter promoted from a sentence to
a `.bpbar.big` readout; the 5 fuse rows wrapped in a visually-demoted
`.fusepanel`. Zero new assets/canvas/WebGL/libraries — presentation-only, all
constraints held. 4 open questions left to `art-director`/`game-designer`/PM
(see file §Open questions), none blocking a first implementation pass.

**Prior pass (2026-09-07, second pass) — chest-tier "double gacha" itself: DONE,
written to file.** Full spec is at
`design/quick-specs/echo-box-double-gacha-ux.md` — read that file directly for
the odds table, copy, and flow, don't rely on this memory's summary below for
exact numbers (they may drift if the file is revised later; this memory is a
pointer + the decisions that won't change).

**Naming collision — resolved, not open anymore**: old permanent account
system (`echoTier()`/`ECHO_TIER_NAMES`) is now labeled **"Rank"** in UI copy
(code/variable names untouched). New per-pull chest-grade system is always
labeled **"Chest"/"Chest Grade"**, never bare "Tier". Two copy-line changes
needed in `client.html` (~2946, ~3066, ~3092) to apply this — not yet
implemented in code as of this pass, this was a UX/copy spec only.

**Odds finalized in the spec (recompute, not the same number as first pass)**:
blended system-wide Mythic rate **1.35%** (4.5× current flat 0.3% from
`ECHO_BOX_RARITY_ODDS`), via 6 chest-roll odds (45/28/16/7/3/1% Bronze→Lunacian)
× per-chest rarity table (Bronze/Silver reweight-only, Gold/Platinum floor
Rare+, Diamond/Lunacian floor Epic+). Flagged to `economy-designer`+PM as an
open question — not just the Mythic tail, the whole distribution shifts
upward (Common drops ~14pp) since Shard cost via `echoCost()` is unchanged.

Product owner asked (2026-09-07) to turn Echo Box cosmetic gacha into a "double
gacha": roll a **chest tier** (Bronze/Silver/Gold/Platinum/Diamond/Lunacian, 6
levels, art already downloaded to `scratchpad/drive-starters/chests/` per
`GACHA_AND_ECONOMY_ASSETS.md`) first, then open that chest for the real
cosmetic. Reason given: "art có sẵn để không sẽ phí" + wants an extra tension
beat for addictiveness. UX-only pass delivered (no code) — full design in that
conversation's final response, key points worth remembering:

**Naming collision risk (the most important catch)**: the project ALREADY has
an unrelated `echoTier()`/`ECHO_TIER_NAMES=['','Waning','Crescent','Gibbous','Full','Eclipse']`
system — a permanent, non-random, account-level meta-progression (gates
`ECHO_TITLES`) shown right in `scEchoBox()` as "Tier: Waning". The new
chest-roll layer is a per-pull RNG mechanic with zero relation to that. Both
happen to have 6 levels. **Rule going forward: any UI copy for the new chest
system must say "Chest" and never stand-alone "Tier"**, or players will read
two unrelated progress meters as one. See [[reference_axiedice_ui_rules]].

**Recommended odds structure**: 6 chest tiers paired 2+2+2 by rarity floor —
Bronze/Silver = no floor (reweighted only), Gold/Platinum = guaranteed Rare+,
Diamond/Lunacian = guaranteed Epic+. Chest-roll-odds proposed steeply decaying
like the existing `ECHO_BOX_RARITY_ODDS` shape: 45/28/16/7/3/1% for
Bronze→Lunacian. Blended system-wide Mythic rate under this table comes out
to ~1.74%, a ~5.8x increase over the current flat 0.3% (`ECHO_BOX_RARITY_ODDS`
r4) — flagged as an open question for the PM + `economy-designer`, not
decided unilaterally, since it's a real economy change, not just a UX reskin.

**Open decision left to PM**: manual "OPEN CHEST" second-tap (stronger
ceremony, costs 1 extra click per box — matters because Echo Box is an
end-game Shard sink opened repeatedly) vs. auto-chain after a ~800-900ms pause
(faster for bulk-opening, still delivers 2 visual beats via the chest-reveal
animation itself). Recommended auto-chain but did not decide for the PM.

**Implementation notes for whoever builds this** (`gameplay-programmer`/`ui-programmer`):
route all new reveal feedback through the *existing* `flashScreen()`/`hitstop()`
(already gated by `wantsLessFlash()`, see the fixed note in
[[project_axiedice_ux_qa_gate_2026-09]]) rather than a new accessibility path;
give the 6 chest tiers their own CSS color ladder distinct from `.rcard.r0-r4`
(6 levels vs. 5, reusing r0-r4 classes for chests would visually collide with
cosmetic rarity colors); make any "OPEN CHEST" control a real `<button>` like
`OPEN BOX` already is, not a clickable div (keeps it in the native keyboard
tab order for free — see the keyboard-gap note in [[reference_axiedice_ui_rules]]).
