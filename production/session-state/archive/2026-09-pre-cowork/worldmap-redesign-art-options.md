# World Tour Map — Node/Path Visual Options (scratch, no decision made)

**Confirmed from code** (`src/client.html` `scTourMap()` ~5506, CSS ~1712-1728;
`src/data.js` `TOUR_MAPS` ~924): `.tournode` is a plain 52px circle (`.landmark`
72px), no printed number anywhere — only a lock emoji, reward thumbnail, or a
✓/! corner badge. States are `locked`/`ready`/`got`, colored via `--line`
(default), `--acc` (gold, ready+pulse), `--heal` (green, got) — no "zone" color
exists. `.tourpath` is a single dashed `#fef6d8` SVG stroke. Only 2 maps exist
today (`TOUR_MAP_ART['1']`,`['2']`), both single-biome ("Lovely Forest I/II") —
**the art has no baked-in multi-zone coloring to key off**, so a Candy-Crush
zone palette would have to be invented, not read from the art. `t.i` (1-10)
already exists per tile — free step-number source, no data change needed.
Precedent for a per-node CSS-var color already exists elsewhere (`nodecard`
sets `--nc` inline per encounter type) — same trick works here for a state
or zone color.

## Node redesign options
1. **State-color badge, CSS-only (Recommended to explore first).** Bigger
   circle (68-76px), gradient fill keyed by state (gold/green/gray via
   existing `--acc`/`--heal`/`--line`), `t.i` printed as bold white number
   centered (absolutely-positioned `<span>` over the thumbnail, or replacing
   it pre-unlock), drop-shadow + inset ring for depth. Zero new assets, zero
   data changes. Doesn't yet give "zone" identity since the art has none.
2. **Synthetic zone banding, CSS-only.** Split each map's 10 tiles into
   2-3 arbitrary bands (e.g. tiles 1-4/5-7/8-10) and assign each band a hue
   (via `--nc`-style custom prop), independent of art content. Gets the
   Candy-Crush "world sections" read without touching art, but the color
   change won't line up with any real visual landmark in the background —
   risk of looking arbitrary/disconnected from the illustration.
3. **New badge-frame asset (small cost).** A single small PNG/SVG "frame"
   (gem-shape or coin-shape) with a transparent number-safe center, tinted
   per state via CSS `filter:hue-rotate`. More casual-game polish than pure
   CSS gradients but needs technical-artist to produce + `art.js`/icon-system
   integration.
4. **Reuse `IC_G`/`ico()` for a corner state-glyph instead of/alongside the
   number.** Keep number as primary, drop emoji lock/✓ for a crisp `IC_G`
   icon (already the established pattern) — cheap, consistent, but doesn't
   by itself solve "no number today."

## Path upgrade options
- **A. Thicker gradient stroke, CSS-only.** Widen `.tourpath` stroke (2.5px
  to ~10px), switch flat dash color to an SVG `<linearGradient>` id, keep
  `stroke-dasharray` for a "steps" read. No asset cost.
- **B. Solid-behind-claimed, dashed-ahead.** Two `<path>` elements sharing
  the same `d`, one solid+bright up to `lastClaimedNode`, one dashed+dim
  beyond it — reuses data already computed for the pawn position. CSS/JS
  only, no new asset.
- **C. Footprint/stone-tile motif.** Needs a small repeating SVG/PNG tile
  pattern (`stroke-dasharray` can't fake footprints) — a genuine new-asset
  ask, higher fidelity but real production cost.

No option chosen; flagging cost only, per task instructions.
