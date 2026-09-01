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
