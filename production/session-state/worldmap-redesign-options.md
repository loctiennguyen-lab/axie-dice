# World Tour Map — Candy-Crush/Homescapes Style Options (research only, no decision made)

**Correction to task brief's "verified current state":** it's stale. `scTourMap()`
(`src/client.html:5506-5597`) already shipped the v6 node-on-path redesign
(`design/ux/world-tour-map.md`, session 2026-09-08): real `<img>` full-bleed
horizontal-scroll board (`.tourboard`/`.tourboard-inner`), a dashed cream SVG
path (`.tourpath`, `non-scaling-stroke`), and 52-72px circular `.tournode` pins
showing the actual reward thumbnail or boss portrait (`sprMon()`), with a
lock/pulse/checkmark state system and an interpolated "you are here"
`.tourpawn`. The `.tnode` class the brief cites is a *different*, unrelated
component (in-combat wave-track HUD, `client.html:632`). So the gap to the
reference isn't "plain dots with no number/color" — it's zone-color-coding,
a printed number, star ratings, and the persistent top HUD/side icons, layered
onto an already-decent node-on-path base.

**Data available**: `TOUR_MAPS[].tiles[]` has `i` (1-10, usable as the printed
number) and `node:{x,y}`. **No per-tile star/score data exists anywhere** —
this game has no per-run scoring mechanic to back "stars," and no lives/energy
resource either (confirmed: no hits for lives/energy/stamina in `client.html`).
Both are flagged as game-designer questions, not something UX can invent.

## Options

**A — Numbered zone-color badge (closest to reference).** Replace the
reward-thumbnail-as-node-content with a flat-color circle (color = per-map
zone accent) + bold white `t.i` centered, per-node opacity/lock state as today;
relocate the reward thumbnail to a small corner badge (reuse `.tournode-badge`
slot) so the "what do I get" promise isn't lost. Star rating: substitute the
existing `.rchip`/`--r0..--r4` rarity ladder as a small pip row under the node
instead of fabricating stars. Medium cost — new CSS states, reflow of existing
badge slot, no new assets.

**B — Hybrid ring (lowest diff).** Keep reward-thumbnail as primary node art
(preserves the just-shipped v6 direction), add a colored ring/disc *behind*
the thumbnail per zone + a small number chip in one corner. Reuses
`.tournode`/`.tournode img`/`.tournode-badge` almost as-is — one modifier class
+ one absolutely-positioned number span. Least faithful to the reference but
cheapest and non-destructive to v6's "always show the real reward" value.

**C — Painterly medallion re-skin (highest fidelity, highest cost).** Commission
new circular badge art per zone tier from `technical-artist`, with the number
as a live CSS/SVG text overlay (not baked into the art, so it stays
data-driven). Most faithful to the reference's painterly look; requires new
asset production and art-director sign-off, largest scope.

**D — HUD/chrome only, no node change.** Skip node redesign; only add the
persistent top bar (reuse whatever Shard chip component the parallel Menu-HUD
task produces — **flagged dependency, not designed here**) + settings gear +
floating side icons (docked right edge, existing `.btn` styling). Cheapest,
but doesn't address the explicit "white number in a colored circle" ask.

## Accessibility

Per-zone color must pair with the number/shape already in the reference art
(A/C do this natively; B needs the number chip to carry the same duty since
color is on a background ring, not the whole node) — no state or zone may be
color-only, consistent with the existing `.tournode` lock/ready/got treatment.
Any new HUD pulse (side-icon "new reward" dot, etc.) must gate through
`wantsLessFlash()` like `.tournode.ready.pulse` already does. Number contrast
(white-on-saturated-color) needs a per-zone-palette contrast check once
art-director picks colors — don't assume all zone hues clear WCAG at once.

No option is recommended over another here; this is scoping input only.
