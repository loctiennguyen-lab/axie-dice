# Icon Spec — Body Part Icons (6 slots)

> **Status**: Designed, pending implementation
> **Author**: art-director (2026-09-01)
> **Addresses**: `docs/review-2026-08-31.md` art finding #1 — die faces currently show only a text label for the body part, no icon; "lắp ráp bộ phận quái vật lên xúc xắc" is the game's central premise but is currently text-only.

## Grounding

Read before writing this spec: `src/icons.js` (8x8 `IC_G` grid → `icoSvg()` → inline SVG; `IC_COL` bakes fill color directly into the SVG — CSS `color` does **not** recolor it), `src/ui.js:129-143` (`paintDieFace`, current face layout), `src/ui.js:1322-1331` (`faceRow`, info-panel row layout), `src/style.css:385-411` (die box sizing), `:505-510` (`.icow` size variants), `design/gdd/game-concept.md` (part table), `design/gdd/part-tier-system.md` §2 (per-class slot flavor).

**Key finding that shapes this spec**: `.die`'s `border-bottom:3px solid var(--cc)` is the unit's **class** color, not effect type — so "icon=part, color/border=effect" cannot repurpose the border (already spoken for). Effect type must stay on the existing channels (icon fill color, `.dv` number color).

## Sizing constraints (confirmed from `style.css`)

`--die-w` shrinks 160px → 140px → 104px → 64px across breakpoints (`.die{padding:6px 4px}` at smallest). Existing icon slots: `.icow.di` 22px (current effect-icon slot), `.icow.ii` 15px, `.icow.t` 11px (compact `.mf` mini-die summaries).

## 1. Mouth

**Silhouette**: horizontal fanged jaw — two flat 2-3px zigzag "tooth" bands (upper/lower jaw) separated by a 1-2px straight horizontal gap, spanning most of the 8px width.

**Why it reads at 8x8**: only horizontal, banded, symmetric-split silhouette in the set — a flat rectangle cut by one clean line, simpler than the jagged-blob icons (`thorns`, `boss`) already in use.

**Collision check**: none. Nearest neighbor `thorns` is a spiky blob, not a banded split.

## 2. Horn

**Silhouette**: single solid asymmetric curved wedge, thick at base (bottom-left) tapering to a sharp point (upper-right), slight concave leading edge (bull/rhino horn profile).

**Why it reads at 8x8**: solid single-mass, no internal bars — separates it from `dmg` (symmetric cross/burst with a bar) and `burn` (flickering flame with a waist).

**Collision check**: `dmg` (symmetric, has crossbar), `burn` (narrows-then-widens) — horn's monotonic taper is distinct from both.

## 3. Back

**Silhouette**: dorsal ridge — 3 small rounded bumps in a row along the top edge (stegosaurus-plate style), on a flat 1-2px base bar. Symmetric.

**Why it reads at 8x8**: deliberately NOT the smooth teardrop shape of the existing `shield` effect icon — avoids conflating "this is the Back part" with "this face has Shield effect," which is exactly the ambiguity this spec removes.

**Collision check**: `shield` icon is one continuous rounded silhouette narrowing to a point. Back-part icon is 3 discrete bumps on a flat base — different topology.

## 4. Tail

**Silhouette**: single tapering diagonal line across most of the grid (thick at one corner, thin at the opposite), ending in a small hook/curl at the tip.

**Why it reads at 8x8**: defining feature is a continuous diagonal taper — nothing else in the set is a thin diagonal line. Avoids tail/claw confusion: the shape is defined by length+taper, hook is only an accent at the tip.

**Collision check**: `reroll` (closest neighbor, also has curl geometry) is a closed circular loop with two arrow tips — clearly a loop, not an open tapering line.

## 5. Eyes

**Silhouette**: two small solid circles (pupils), each with a thin ring, horizontally symmetric, centered. No diagonal marks, no corner accents.

**Why it reads at 8x8 — highest collision risk in the set**: the status icon `blind` is ALSO two eye-shapes but deliberately closed/obscured, with two isolated corner dots at bottom-left/bottom-right (blindfold-knot accent). **The Eyes body-part icon must omit those corner marks and keep both pupils solid/open** — that presence/absence of corner accents is the entire distinguishing feature between "this face has the Eyes part" and "this unit is Blinded," and these appear right next to each other in the UI (die face vs. status row).

**Collision check**: deliberately differentiated from `blind` per above; not diamond/blob-shaped like most of the set, so no secondary collisions.

## 6. Ears

**Silhouette**: symmetric pair of tall pointed triangles in top-left/top-right corners, pointing outward/upward, empty negative space in the middle/bottom (fox/bat-ear style).

**Why it reads at 8x8**: only icon defined by two separated shapes with a deliberate gap, rather than one connected mass. `mana` (the effect icon both Ears faces default to) is a single diagonal zigzag bolt — no shape-family overlap despite sharing a default effect type.

**Collision check**: none — no existing icon uses a two-piece corner-pair composition.

## Summary table

| Slot | Silhouette | Distinguishes from | Default effect type |
|---|---|---|---|
| Mouth | Horizontal fanged jaw, split band | `thorns` (blob w/ spikes) | dmg (lifesteal) |
| Horn | Solid curved wedge, single taper | `dmg` (cross/bar), `burn` (flicker) | dmg (pierce/heavy) |
| Back | 3-bump dorsal ridge on flat base | `shield` effect icon (smooth teardrop) | shield |
| Tail | Diagonal tapering line + tip curl | `reroll` (closed loop) | dmg/poison |
| Eyes | Two open solid pupils, no accents | `blind` status icon (shut/corner marks) | heal/debuff |
| Ears | Two corner triangles, gap between | `mana` effect icon (single diagonal bolt) | mana |

## Color/composition rule

**Part icon = one flat, desaturated neutral color (bone/ivory tone), always — never tinted with an effect-type hue.** Tinting a part icon with an effect color would recreate the `CLASS_COLOR`-vs-semantic-color collision already flagged in the original art review (finding #3): two independent signals sharing hue-space.

Three independent, non-colliding channels:
- **Icon shape** → which body part (constant across all instances of that part)
- **Icon color** → always neutral/bone (identity, never varies)
- **Number color** (`.dv`, existing `.die.t_TYPE .dv{color:...}`) + **small effect badge icon** → effect type. Both, not just color alone — color-only encoding of effect type would regress the still-open colorblind-mode accessibility item.

## Layout change (`ui.js` / `style.css`)

Current `paintDieFace` order: `.dp` part-name text → 22px effect icon (`ico(FT_IC[f.t],'di')`) → value number → keyword text.

1. Promote the new part icon into the primary 22px slot: `ico(PART_IC[f.p], 'di')`.
2. **Keep the existing `.dp` text label** — icon+text redundancy is deliberate until players learn the new icon vocabulary (same colorblind/redundancy reasoning as above).
3. Shrink the effect-type icon to the existing `'t'` size class (11px, already used in `.mf` mini-die summaries) — place as a small corner badge (top-right), secondary to the part icon.
4. At the two narrowest breakpoints (104px, 64px), hide the small effect badge at 64px specifically — precedent exists (`.tnode .icow{display:none}` already hides icons at a small breakpoint). Whether `.dp` text also needs hiding at 64px should be decided from an actual rendered screenshot, not blind.
5. Add a `PART_IC` lookup map next to `FT_IC`/`ST_IC` (same pattern). Prefix the six new `IC_G` keys (`p_mouth`, `p_horn`, `p_back`, `p_tail`, `p_eyes`, `p_ears`) as a distinct namespace from effect/status icon keys.

## Out of scope for this spec

Hand-authoring the actual `IC_G`-format pixel grid data for each icon — that's an implementation task for whoever codes against this spec. This document describes each silhouette precisely enough that implementation should not require further design decisions, only translation into the grid format.
