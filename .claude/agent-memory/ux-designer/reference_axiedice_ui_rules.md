---
name: reference-axiedice-ui-rules
description: Where the Axie Dice Tactics hard UI invariants, design system, and CSS variables live
metadata:
  type: reference
---

For this project ("Axie Dice Tactics: Lunacia Mutants", browser DOM/CSS dice-combat roguelike):

- **The 8 non-negotiable hard UI rules** (closed type scale, contrast, no `--faint` token, ≥44×44 tap targets via `::before` inset expansion, no layout-shift transforms on `.unit`/`.die`/`.nodecard`/`.rcard`/`.btn`, no undefined/NaN leaking to UI, breakpoints at 1199/899/599px not zoom, phone-portrait gated behind rotate-hint) live in `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md` §4, sourced from `docs/axiedice-source/uiux/UIUX_IMPLEMENTATION_BRIEF_v1.md`. Enforced automatically by `tools/verify.mjs` — any layout proposal must be checked against these before handoff.
- **Design system** (color semantics, 6-size type scale 9/11/13/17/26/40 aka `--t1..--t6`, one border weight, two radii, 4px spacing grid): `docs/axiedice-source/uiux/UI_DESIGN_SYSTEM_v0.8.md`.
- **Original intended combat layout ASCII sketch**: `docs/axiedice-source/design/AUDIT_AND_SPEC_v1.md` §B8.
- **Real current CSS** (actual measurements, not assumptions): `src/style.css` — root vars around line 13-68 (`--unit-w:158px`, `--die-w:160px`, `--die-h:120px`, `--spr-w:100px`, breakpoint overrides at `@media max-width:1199/899/599`). Combat-specific rules from line ~301 onward (`.zone`, `.unit`, `.intent`, `.tray`, `.diebox`, `.bottombar`).
- **Combat log spec** (not yet implemented, T15): `design/ux/combat-log.md` — has the reasoning for where new combat-screen UI real estate can/can't go without violating no-reflow rules (tiered by breakpoint: dock outside board bounds ≥1200px with letterbox room, overlay drawer 900-1199/600-899, full-screen modal <600 landscape).
- **Engine/UI split**: `src/engine.js` is pure (no DOM), emits typed events via `EV()`/`s.ev`; `src/fx.js` replays them. Each party unit's die is 1:1 keyed by `data-uid` (`dieBoxEl(uid)`), useful for any redesign that wants to visually pair a unit with its die.
