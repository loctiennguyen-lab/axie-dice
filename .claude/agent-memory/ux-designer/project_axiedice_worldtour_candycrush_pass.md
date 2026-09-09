---
name: project-axiedice-worldtour-candycrush-pass
description: Second World Tour map redesign pass (post-v6) toward a Candy Crush/Homescapes-style overworld — options doc written 2026-09-09, no decision yet
metadata:
  type: project
---

Product owner wants `scTourMap()` (already-shipped node-on-path v6, see
[[project_axiedice_worldtour_map_redesign]]) pushed further toward a
Candy-Crush-Saga/Homescapes-"Sweet Journey" look: bold per-zone-colored circle
nodes with a printed white level number, star ratings under each node, baked
decorative scenery (already have this via `TOUR_MAP_ART`), a persistent top
HUD (lives/hearts left, gold-coin-style currency + "+" right, gear icon), and
floating side-docked icon buttons (calendar/gift).

**Options written, no winner picked**:
`production/session-state/worldmap-redesign-options.md` — 4 options (A numbered
zone-badge / B hybrid ring, lowest diff / C painterly medallion re-skin,
highest cost / D chrome-only, no node change).

**Two things this game genuinely lacks, don't assume they exist**: (1) no
per-tile star/score mechanic anywhere in the data — "stars" has no backing
data, recommended fallback is reusing the existing `.rchip`/`--r0..--r4`
rarity-ladder pips instead of inventing scoring; that's a `game-designer`
question if real stars are wanted. (2) no lives/energy/stamina resource exists
in this game at all (`grep -i "lives|energy|stamina"` in `client.html` — the
only hits are unrelated code comments, e.g. "lives on `#bgLayer`"). A
lives/hearts HUD chip is a **game-design economy decision** (would need a real
resource + regen rule), not just a UI treatment — flag hard before anyone
starts implementing a hearts icon that has nothing behind it.

**Dependency, don't design it here**: a parallel task is adding a Shard
currency HUD chip to the Menu screen. Any currency HUD added to this map
screen should reuse that chip component once it exists, not invent a second
one — check whether that work landed before starting implementation.

See [[reference_axiedice_ui_rules]] for where the shared CSS design system
(`.rchip`, `--tap-min`, `wantsLessFlash()` pulse-gating) lives.
