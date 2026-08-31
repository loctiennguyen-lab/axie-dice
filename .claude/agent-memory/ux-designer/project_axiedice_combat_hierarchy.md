---
name: project-axiedice-combat-hierarchy
description: Combat screen info-hierarchy redesign for Axie Dice Tactics, triggered by blunt PM feedback on 2026-09-01
metadata:
  type: project
---

Product owner reacted to a combat screenshot with "UI vẫn rất xấu vậy nên hãy nhờ UI Design cải thiện lại hoàn toàn" (still ugly, get UI design to completely redo it) on 2026-09-01. This is a strong, blunt, low-context signal from this PM — expect terse reactions rather than detailed critique; the ux-designer/art-director have to reverse-engineer the actual problem from the screenshot description rather than a written brief.

Root cause diagnosed (not just aesthetic): the v0.8 design system pass (`docs/axiedice-source/uiux/UI_DESIGN_SYSTEM_v0.8.md`) fixed color/glow/type-scale discipline but never established a *size/weight hierarchy* between elements of different importance. Every card (enemy, unit, die, intent chip) uses the same dark-rounded-rect-thin-border treatment, so nothing is visually subordinate/dominant despite reasonable info density. This is a layout/hierarchy problem, not (only) a color/depth problem — hence the split: ux-designer owns hierarchy/grouping/sizing, [[axiedice-art-director-pass]] owns color/depth/aesthetic, in parallel.

**Why:** the PM explicitly separated "improve the UI completely" into two concerns when briefed — ux-designer produced a layout/hierarchy brief (enemy intent dominance, unit-die pairing via shared uid, archetype badge legibility, bottom-bar primary-action isolation) without touching color, deferring visual restyle to art-director.

**How to apply:** When this PM gives blunt one-line UI feedback in future, don't ask for more written detail — go read the actual current CSS/screenshot state directly (as done here: `src/style.css`, `docs/axiedice-source/uiux/UI_DESIGN_SYSTEM_v0.8.md`, `docs/axiedice-source/design/AUDIT_AND_SPEC_v1.md` §B8) and produce a grounded diagnosis rather than waiting for elaboration.

Key structural finding worth reusing: `src/engine.js` ties each party unit's die 1:1 by `data-uid` (`u.die[u.rolled]`, `dieBoxEl(uid)` in `src/fx.js`) — the unit card and its die are *already* correlated in the DOM/data model, just not visually grouped (they render in two separate flex rows, `.zone.party` then `.tray`, which happen to align only because `--unit-w`/`--die-w` are coincidentally equal at each breakpoint). Regrouping into per-unit columns is low-risk from a data standpoint but needs confirmation from ui-programmer/game-designer on whether summoned `.unit.p.token` units (72% width, dashed border) always have a die to pair with.
