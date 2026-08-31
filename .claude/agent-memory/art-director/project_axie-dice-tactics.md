---
name: project-axie-dice-tactics
description: Axie Dice Tactics Lunacia Mutants — browser DOM/CSS game (no canvas/WebGL), art findings from the 2026-08-31 cross-agent review
metadata:
  type: project
---

"Axie Dice Tactics: Lunacia Mutants" is a browser game rendered via DOM/CSS
(no canvas/WebGL) — all visual assets must be inline SVG or CSS, not sprite
sheets or bitmap art. Source lives in `src/` (`icons.js`, `ui.js`, `style.css`,
`data.js`).

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
