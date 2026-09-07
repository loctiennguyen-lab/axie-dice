---
name: project-axie-dice-tactics
description: Axie Dice Tactics Lunacia Mutants — browser DOM/CSS game (no canvas/WebGL), art findings from the 2026-08-31 cross-agent review
metadata:
  type: project
---

"Axie Dice Tactics: Lunacia Mutants" is a browser game rendered via DOM/CSS
(no canvas/WebGL). Source lives in `src/`.

**2026-09-07 correction — the "SVG/CSS-only, no bitmap art" line above is
STALE, do not repeat it.** As of the 2026-09-03 file merge, per-file source is
now `src/client.html` (CSS+UI+FX+audio+icons+log, one file), plus 4 files kept
separate on purpose: `src/engine.js`, `src/data.js` (read server-side for
anti-cheat), `src/devtools.js` (stripped from public builds), and
`src/art.js`/`src/cosmetics.js` — **1.8MB of base64-embedded real bitmap
PNG/JPG art**, not SVG. `art.js` holds `AXIE_PIX` (64×66px pixel-art sprites,
6 classes). `cosmetics.js` holds `COSMETIC_AVATARS`, 59 **real Sky Mavis Axie
Origins asset-kit** portraits/card-art (product owner has internal access to
this IP), used today only for the player's Profile avatar. So: this project
DOES ship bitmap art, embedded as base64 data URIs in `<img>` tags — the old
"inline SVG only" framing only ever applied to the small icon system
(`IC_G`/`icoSvg`, see [[reference_icon-system-pattern]]), not to portraits/
character art. Full asset-kit review + a plan to extend real art from
Profile-only to Hero/Boss/field-monster is at
`design/quick-specs/real-art-adoption-plan-2026-09-07.md` — see
[[reference_real-art-integration-pattern]] for the reusable technical finding
from that pass.

The full cross-agent review is at `docs/review-2026-08-31.md` (5 subagents:
game-designer, economy-designer, art-director, ux-designer, qa-lead, each
reading independently without shared context). The art-director section's
top finding (#1, priority 🔴 in the project-wide action list, item #6):
each die face shows only a text label (part name, e.g. "HORN"/"MOUTH") plus
an icon for the face's *effect type* (dmg/shield/heal) — there is no icon
for the body part itself, even though "assembling a monster's body parts
onto a die" is the central Axie Infinity premise. Agreed fix: add 6 new
8x8-grid icons (mouth/horn/back/tail/eyes/ears) reusing the existing
`IC_G`/`icoSvg` infra, and split the visual channel so icon=which-part,
color=effect-type (already has established semantic colors).

Other art findings from that review, not yet actioned:
- `RAR_COL` (`data.js`) and `--r0..r4` (CSS) are two different rarity color
  tables for the same concept — need to unify to one source.
- `CLASS_COLOR` (6 classes) overlaps hue-space with the semantic effect
  colors (aqua≈shield≈rare, reptile≈mana≈epic, bug≈damage, bird≈debuff≈mythic)
  — low risk today (thin borders only) but would become a real collision if
  class color is ever used for fill/glow. This is directly relevant when
  choosing colors for any new part-identity icon: do NOT reuse the six
  semantic effect colors, and be careful not to reintroduce a
  class-color/effect-color collision.
- No formal art spec yet for `art.js` (pixel grid standard, max colors per
  class, naming convention) — new content is currently copied by eye from
  existing code.

See [[reference_icon-system-pattern]] for the technical shape of the icon
system these fixes must slot into.

**2026-09-07 update — Hero mapping in the real-art plan revised to ground
truth.** The original §2 HEROES table in `real-art-adoption-plan-2026-09-07.md`
was a color/icon guess against unlabeled numeric filenames (no class
metadata). Lead later found the official `starter_axies_info` roster
(Sky Mavis internal spreadsheet) with CONFIRMED classes for all 19 starters.
Rewrote §2 around it: one character now carries all 3 tiers of its class
(Buba=Beast, Olek=Plant, Puffy=Aqua, Machito=Reptile, Momo=Bird,
Pomodoro=Bug) — tier1 uses the character's Normal portrait, tier2/3 use its
"Awaken" evolved portrait where one exists (Beast/Plant/Aqua/Reptile only;
Bird/Bug have no clean Awaken asset, so tier2/3 reuse the Normal portrait
with CSS-only escalation). This closed the prior "no Bird art" coverage gap
(Momo) and retired the Low-confidence `reptile3`/`bug3` picks entirely.
Machito (Reptile) renders purple — that's the character's real canonical
color per the ground-truth data, not a misclassification; do not recolor it,
let `CLASS_COLOR` drive the frame instead (same pattern as Vault Axie art).
Flagged but NOT fixed in this pass: §3b (MON_SPR bucketed reuse) still
references the superseded numeric-kit filenames from the old §2 and needs
re-pointing to the new character filenames in the same implementation pass.

**2026-09-01 update — third-round UI complaint, escalated to a full redesign spec.**
Two prior rounds of point-fixes (layout bugs, contrast, class-tint gradient, acting-unit glow)
were not enough — user confirmed via survey the issue is systemic across all four of
layout/spacing, information density, color identity, and typography at once. Wrote
`docs/art/visual-redesign-2026-09-01.md`, direction name "Lunacia Void": recolor the neutral
scale (`--bg/--pan*/--line*`) from blue-gray to deep violet-black (no new accent token — every
hue on the wheel is already claimed by semantic/rarity/class colors, see the hue-collision audit
in that file), keep `--acc` gold as the sole brand/hero color (pops harder on a violet backdrop),
add a display-only font (`--font-brand`, recommend "Chakra Petch" self-hosted as base64 WOFF2 —
keeps the zero-network-dependency rule) for logo/screen-titles only, keep JetBrains Mono for all
data/body text, fix 6 selectors using `--t2` for what should be `--t3` prose per the token's own
documented role, and a combat-card density pass (cap status chips to top-3+overflow, convert
spelled-out die keywords to icon chips via a new `KW_IC` map, merge the heavy-tag/rarity-dot
overlays into one top accent strip, drop the redundant "HP" text label, grow `--unit-w`/`--die-w`
modestly at ≥1200px only). Also flagged (not fixed): `RAR_COL` (data.js) / `--r0..r4` (CSS) are
still two hand-kept copies of the same 5 values, still in sync today but a real unification task.
See [[feedback_orchestrator-collaboration-mode]] for how this task was delegated.

**2026-09-08 update — Chimera monster-art curation pass (regular/elite
monsters only, bosses untouched).** Product owner supplied a Chimera asset
kit (22 creature families, `Chimeras/<name>-NN-00.png` card-art variants,
75 files) to give the 17 normal + 4 elite `MON_SPR` keys real, distinct art
instead of the `monArt2()` Hero-reskin (see main entry above). Full proposal
with per-key file + rationale is `docs/art/chimera-monster-art-mapping-
2026-09-08.md` (DRAFT, awaiting product-owner sign-off, no code changed).
**Load-bearing finding for any future pass over this same kit:** the local
extraction had heavy cross-file duplication — ~15 clusters where files under
completely different creature-family names (e.g. `daddy-bear-01` and
`mommy-bear-01`, or `alpha-wolf-01` and `aqua-alpha-wolf-01`) are byte-for-
byte the same image, and several don't even depict the creature their
filename claims. Full cluster list is in that doc's §1 — do not trust any
single filename in this kit without opening it; re-verify against the
product owner's master Drive copy before implementation, the scratchpad
extraction may not reflect the source-of-truth kit. `machito` and `shilin`
(the two "extraCatalogSkeletons" in `pve-chimeras.json`, not in
`uniqueAssets`) turned out to be all comedic/flavor vignettes (sleep, eat,
fiesta, hit-reaction) with no combat-ready pose outside the one variant each
already claimed by a boss (`mecha`=shilin-04) — excluded from the mapping
entirely, not a gap to fill later.

**2026-09-07 update — §6 "keep pixel icons as-is" partially reversed; §8/§9
added to the real-art plan.** A real Drive icon set ("Battle Status Icon",
~50 files, 3-12KB each) was found that plausibly replaces `ST_IC` (status
badges) specifically — `FT_IC` (die-face effect types) and `ARCH` (playstyle
glyphs) are unaffected and still keep the §6 "do not touch" call, the
legibility argument there still holds for those two. Added §8 (9-keyword
`ST_IC`→Drive-filename mapping, 5 High-confidence by exact/near name match:
poison/regen/weaken/vulnerable/stun; 4 unresolved — blind/thorns/burn/
undying have no confirmed name match, do not force `Zz.png` onto `blind`
without a visual check, it reads as sleep not blind) and §9 (small, optional:
"Icon Cosmetic types" folder has avatar/background/border category icons for
3 of 4 `COSMETIC_POOLS` categories, missing a `title` icon — asymmetry
decision deferred to lead/product owner). Neither section has been visually
verified — see [[reference_real-art-integration-pattern]] and the plan file
itself for the exact fetch-list of files still needed before locking in.
