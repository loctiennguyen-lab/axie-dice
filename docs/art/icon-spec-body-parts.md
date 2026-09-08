# Icon Spec — Body Part Icons (6 slots)

> **Status**: Designed; real asset now available — **ready for implementation**
> as of 2026-09-08, with one feasibility flag for `technical-artist` (§7).
> **Author**: art-director (2026-09-01, updated 2026-09-08)
> **Addresses**: `docs/review-2026-08-31.md` art finding #1 — die faces currently show only a text label for the body part, no icon; "lắp ráp bộ phận quái vật lên xúc xắc" is the game's central premise but is currently text-only.

## Grounding

Read before writing this spec: `IC_G`/`icoSvg()`/`IC_COL` (8x8 grid → inline
SVG; `IC_COL` bakes fill color directly into the SVG — CSS `color` does
**not** recolor it), `paintDieFace` (current face layout), `faceRow`
(info-panel row layout), die box sizing and `.icow` size variants,
`design/gdd/game-concept.md` (part table), `design/gdd/part-tier-system.md`
§2 (per-class slot flavor).

**2026-09-08 path correction**: all `src/icons.js`/`src/ui.js`/`src/style.css`
references above and elsewhere in this doc are **stale** — the 2026-09-03
file merge folded CSS+UI+FX+icons into one file, `src/client.html`. Current
locations, reverified 2026-09-08: `IC_G`/`IC_COL`/`icoSvg`/`ico`/`FT_IC`/
`ST_IC` at `client.html:1899-1955`; `paintDieFace` at `client.html:3075`;
`faceRow` at `client.html:5702`. Both functions still exist with the same
names and the layout this spec assumes (`.dp` text → `ico(FT_IC[f.t],'di')`
→ value, in that order, confirmed unchanged at `client.html:3086-3087`) — no
part icon has been wired in yet, so §"Layout change" below is still fully
valid, only the file path needed fixing.

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

## Layout change (`src/client.html` — was `ui.js`/`style.css` before the 2026-09-03 merge)

Current `paintDieFace` order (verified at `client.html:3075-3094`, 2026-09-08):
`.dp` part-name text → 22px effect icon (`ico(FT_IC[f.t],'di')`) → value number → keyword text.

1. Promote the new part icon into the primary 22px slot: `ico(PART_IC[f.p], 'di')`.
2. **Keep the existing `.dp` text label** — icon+text redundancy is deliberate until players learn the new icon vocabulary (same colorblind/redundancy reasoning as above).
3. Shrink the effect-type icon to the existing `'t'` size class (11px, already used in `.mf` mini-die summaries) — place as a small corner badge (top-right), secondary to the part icon.
4. At the two narrowest breakpoints (104px, 64px), hide the small effect badge at 64px specifically — precedent exists (`.tnode .icow{display:none}` already hides icons at a small breakpoint). Whether `.dp` text also needs hiding at 64px should be decided from an actual rendered screenshot, not blind.
5. Add a `PART_IC` lookup map next to `FT_IC`/`ST_IC` (same pattern). Prefix the six new `IC_G` keys (`p_mouth`, `p_horn`, `p_back`, `p_tail`, `p_eyes`, `p_ears`) as a distinct namespace from effect/status icon keys.

## 7. Real asset arrival (2026-09-08) — supersedes hand-drawn `IC_G` grids

The product owner supplied real part art directly into the repo:
`assets/_incoming/icon-set-2026-09-08/part/` — 6 slots × 8 class variants
(48 SVGs) plus `blank.svg`, sourced from `@axieinfinity/dango-icons`. This
is full illustrative SVG art (48×48 viewBox, multi-path, shaded — verified
by reading `part/HornBugIcon.svg` directly), not a shape simple enough to
re-encode as an 8×8 `IC_G` grid. **This changes the "out of scope" note
below**: hand-authoring `IC_G` grids for these 6 slots is no longer the
implementation task — wiring up the real files is.

### 7.1 Slot × class mapping confirmed

The 6 slots (Mouth/Horn/Back/Tail/Eyes/Ears) match this spec 1:1. Each has
8 class-suffixed files on disk (e.g. `MouthAquaticIcon.svg`,
`MouthBeastIcon.svg`, … `MouthReptileIcon.svg`) — swap the suffix per the
Axie's class to pick the file.

**Class-name mismatch to resolve at implementation**: this game's actual
class keys (`CLASS_COLOR` in `data.js`) are lowercase `plant`, `beast`,
`aqua`, `reptile`, `bug`, `bird` — 6 classes, no `neutral`. The asset set's
8 suffixes are `Aquatic`, `Beast`, `Bird`, `Bug`, `Neutral`, `NeutralActive`,
`Plant`, `Reptile`. Mapping for the 6 real classes is a simple table, only
`aqua` needs a name change, not a slot logic change:

| Game class key | Asset suffix |
|---|---|
| `plant` | `Plant` |
| `beast` | `Beast` |
| `aqua` | `Aquatic` |
| `reptile` | `Reptile` |
| `bug` | `Bug` |
| `bird` | `Bird` |

`Neutral` and `NeutralActive` have **no corresponding game class** — this
game has no "Neutral" class. Two options, neither blocking:
- Leave both unused for now (simplest — no code path needs them).
- `NeutralActive` is plausibly intended as a "this die/part is currently
  selected" accent variant (the naming pattern matches how `.unit.acting`
  already has a distinct visual treatment, `client.html:783`, for the
  currently-acting unit) — but no existing code path swaps a part icon
  based on selection state today, so wiring this in is new scope, not a
  drop-in reuse. Flag for `ux-designer`/`ui-programmer` as an optional
  future enhancement, not part of this pass.

`part/blank.svg` maps to the existing `blank`/`m` part-slot codes already
in `PARTN` (`client.html:2985`) — this is a **different** icon from the
general-purpose `IC_G.blank` ("no effect" glyph, still pixel per the
sibling spec's §5.5) since it lives in a new, separate `PART_IC`-style
lookup, not `IC_G`. No naming collision, but call it out explicitly during
implementation so the two "blank"s aren't merged by mistake.

### 7.2 Feasibility flag — do NOT add `@axieinfinity/dango-icons` as an npm dependency

The set's own `README.md` says "Import from the package in code; the
copies in `icons/part/` are for reference and previews." **That guidance is
incompatible with this project and must not be followed literally.**
`.claude/docs/technical-preferences.md` is explicit: no bundler, no
`node_modules` for the game itself, single self-contained HTML file
assembled by `build.py` string concatenation. Adding a real npm import
would require a module resolution/bundling step this project has
deliberately never had. **Use the on-disk copies as the actual source of
truth instead** — treat
`assets/_incoming/icon-set-2026-09-08/part/*.svg` as the asset, inline each
file's SVG markup as a string constant (same mechanism `art.js`/
`cosmetics.js` already use for other embedded art, coordinated with
`technical-artist` on which file receives them — see the sibling icon
redesign spec's §5.6 for the same "don't bloat `client.html`" reasoning).

**Before embedding, strip each file's `<metadata>...</metadata>` block** —
every file in this delivery (`part/`, `node/`, `effect/`, `cost/` alike)
carries a several-KB C2PA/provenance metadata blob with zero visual
contribution; embedding it verbatim 48 times would add real, avoidable
bloat to whichever file receives these.

### 7.3 Rendering path is separate from `icoSvg()`

These files render through a **different mechanism** than `IC_G`/`icoSvg()`
— they're already complete `<svg>` markup, not an 8×8 grid to walk into
`<rect>` runs. A `PART_IC`-style lookup (slot+class → raw SVG string) sits
alongside `IC_G`/`FT_IC`/`ST_IC` as its own small table, per this spec's
"Layout change" step 5 above (`PART_IC` naming, `p_mouth` etc.) — just note
that `PART_IC`'s values are now literal SVG markup strings, not `IC_G` keys,
since there is no shared grid format to key into.

## Out of scope for this spec

Hand-authoring `IC_G`-format pixel grid data for these 6 slots is now
**superseded by §7** — real art exists, use it. What remains genuinely out
of scope: the `PART_IC` lookup wiring itself, the `NeutralActive`
selected-state question (§7.1), and choosing which base64/string-constant
file receives the embedded markup (§7.2) — all implementation-detail or
deferred-scope calls for `ui-programmer`/`technical-artist`, not further
design decisions.
