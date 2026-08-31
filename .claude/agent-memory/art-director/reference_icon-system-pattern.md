---
name: reference-icon-system-pattern
description: How the pixel icon system in src/icons.js works (IC_G grid format, IC_COL, icoSvg, FT_IC/ST_IC), for authoring new icon specs that stay implementation-compatible
metadata:
  type: reference
---

`src/icons.js` defines all game icons as inline SVG generated from an 8x8
character-grid format — no image files, consistent with the DOM/CSS-only
rendering constraint (see [[project_axie-dice-tactics]]).

- `IC_G` — object keyed by icon name, each value is an array of 8 strings
  (rows), 8 chars each, `#` = filled pixel, `.` = empty. `icoSvg()` walks each
  row and emits `<rect>` runs for contiguous `#` sequences into a
  `viewBox="0 0 8 8"` SVG.
- `IC_COL` — object keyed by the same icon names, hex color used as the SVG
  `fill` attribute directly (baked into the SVG string, not `currentColor` —
  CSS `color` rules on the wrapping span do NOT recolor the icon fill).
- `ico(name, cls, col)` returns a `<span class="icow {cls}">` wrapping the
  cached SVG; `cls` selects the CSS size variant (see `.icow.t/.ii/.di/...`
  in `style.css`, roughly 11px/15px/22px/etc.).
- `FT_IC` maps face *effect type* keys (dmg/shield/heal/mana/poison/buff/
  debuff/summon/blank) to `IC_G`/`IC_COL` names (currently 1:1 identity map).
  `ST_IC` does the same for status effects (poison/burn/regen/thorns/...).
- Die-face effect color is NOT communicated via CSS border — `.die`'s
  `border-bottom:3px solid var(--cc)` is the unit's *class* color (Plant/
  Beast/etc.), unrelated to effect type. Effect type is currently
  communicated only via the icon's baked fill color and via
  `.die.t_TYPE .dv{color:...}` on the value number text.
- Any new icon set (e.g. body-part icons) should follow the exact same
  three-piece pattern: entries in `IC_G` (8x8 grid), entries in `IC_COL`,
  and a small lookup map (`FT_IC`/`ST_IC`-style) from domain key to icon
  name — keeps it implementation-compatible with `icoSvg`/`ico()` as-is,
  no new rendering path needed.
