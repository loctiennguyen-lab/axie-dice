# Icon System Redesign — Pixel Icon Replacement Spec

Status: DRAFT — visual direction, inventory, and format spec are decision-ready;
final per-icon asset sourcing is **BLOCKED** on two inputs not yet in this
session (see §5). Do not start swapping individual icons until §5 clears.
Author: art-director (2026-09-07)
Trigger: product owner — *"các icon trong game này vẫn là dạng pixel... hãy
tiến hành rà soát lại để biến chúng thành icon bình thường, dùng art phù hợp
có trong Drive"* (the icons in this game are still pixel-style — review them
and turn them into normal icons, using appropriate art from Drive).
Location note: docs-type home for this spec follows the precedent already set
by its sibling `docs/art/icon-spec-body-parts.md` (a different icon set, same
system) rather than `design/gdd/` or `design/ux/` — this is an asset/visual
specification (sourcing, format, sizing), not a single gameplay mechanic (no
GDD-shaped Formulas/Player Fantasy apply) and not a single-screen spec (this
icon set appears on nearly every screen in the game).

## 0. Scope, and how this revises prior findings

The system in question is the `IC_G` pixel-icon set — hand-drawn 8×8
`#`/`.` bitmaps rendered as crisp-edged inline SVG via `icoSvg()`/`ico()`.
It moved from a standalone `src/icons.js` into `src/client.html` in the
2026-09-03 file merge; the `/* ─────────── icons.js ─────────── */` comment
at `client.html:1858` is the old module boundary, kept as a marker. **This
agent's own memory (`reference_icon-system-pattern.md`) still said
`src/icons.js` — corrected as part of this pass, see the memory update.**

A prior pass this session (`design/quick-specs/real-art-adoption-plan-2026-09-07.md`
§6/§8/§9) already looked at this exact question and landed on a narrower
call: keep `FT_IC` (die-face effect icons) and `ARCH_IC`/`ARCH` (playstyle
badges) untouched on legibility grounds, but swap 6-of-9 `ST_IC` (status
badge) icons for a specific Drive icon pack that had already been found and
name-matched. **The product owner's new instruction is broader than that —
"review them and turn them into normal icons," not scoped to statuses only —
so this spec supersedes §6/§8/§9's "keep FT_IC/ARCH as-is" call for scope,
but keeps its underlying reasoning and re-applies it to the full set.** §8's
6 partial ST_IC picks are carried forward in §5 as a head start, not
re-litigated.

## 1. Full inventory (source of truth: `src/client.html`, grepped 2026-09-07)

**Count correction**: the brief this task was scoped from lists 24 names;
`IC_G` (`client.html:1860-1886`) actually defines **25** entries — `chest`
was present in code but the brief's count of "24" undercounted it by one.
Using the code as ground truth below.

| Icon | `IC_COL` (current fill) | Consumed via | Render size(s) used | Context / frequency |
|---|---|---|---|---|
| `dmg` | `#ff6b6b` | `FT_IC.dmg`, `NODE_INFO.battle.ic` | `di` 22px, `t`/`tn` 11-12px, `nic` 30px | Very High — every damage die face, every mini-die chip, and the "BATTLE" map-node icon (the single most common node type) |
| `shield` | `#7ac8ff` | `FT_IC.shield`, `ARCH_IC.shield`, literal status-row use | `di` 22px, `ii` 15px, `t` 11px | High — every shield die face, every shielded unit's HP-bar status pill, tooltip glossary |
| `heal` | `#77e895` | `FT_IC.heal`, reward-icon ternary (`ricon`) | `di` 22px, `t` 11px, `ricon` 38px | High — heal die faces, "heal" reward-node icon |
| `mana` | `#c78cff` | `FT_IC.mana`, `ARCH_IC.mana` | `di` 22px, `t` 11px | High — mana die faces (also the default effect for Ears body-part faces per `icon-spec-body-parts.md`) |
| `poison` | `#a4e05a` | `FT_IC.poison` **and** `ST_IC.poison` (same name, two different lookup tables), reward-ternary as "curse" | `di` 22px, `ii` 15px, `t` 11px, `ricon` 38px | High — one of the most common statuses in the game; also doubles as a face-effect icon (different meaning, same glyph) |
| `buff` | `#ffd76a` | `FT_IC.buff`, `ARCH_IC` fallback default, `EV_IC.shrine` | `di` 22px, `t` 11px, `evic` 40px | Moderate |
| `debuff` | `#ff9ad1` | `FT_IC.debuff`, `ARCH_IC.aoe` | `di` 22px, `t` 11px | Moderate |
| `summon` | `#c8c0f0` | `FT_IC.summon`, `ARCH_IC.summon`, `EV_IC.mutant`, reward-ternary ("face") | `di` 22px, `t` 11px, `evic` 40px | Moderate |
| `blank` | `#6b648c` | `FT_IC.blank` (no-effect face), `ucicow` fallback | `di` 22px, `ucicow` 20px | Low — deliberately the "nothing here" glyph |
| `burn` | `#ff9a4d` | `ST_IC.burn`, `ARCH_IC.burn`, `EV_IC.campfire` | `ii` 15px, `t` 11px, `evic` 40px | Moderate |
| `regen` | `#77e895` | `ST_IC.regen`, `ARCH_IC.growth` | `ii` 15px, `t` 11px | Moderate |
| `thorns` | `#ffd76a` | `ST_IC.thorns`, `ARCH_IC.thorns` | `ii` 15px, `t` 11px | Low-Moderate |
| `blind` | `#b0a8d0` | `ST_IC.blind` only | `ii` 15px, `t` 11px | Low |
| `weaken` | `#9ad1ff` | `ST_IC.weaken` only | `ii` 15px, `t` 11px | Low |
| `vuln` | `#ff9ad1` | `ST_IC.vulnerable` (key differs from icon name) | `ii` 15px, `t` 11px | Low |
| `stun` | `#ffffff` | `ST_IC.stun` only | `ii` 15px, `t` 11px | Low |
| `freeze` | `#9fe8ff` | **Not** in `ST_IC` — hardcoded literal `ico('freeze',...)` at 2 call sites (frozen-unit status pill, frozen-die reroll-lock badge) | `ii` 15px, `t` 11px | Low-Moderate, but mechanically load-bearing (gates rerolling) |
| `undying` | `#ffd76a` | `ST_IC.undying` only | `ii` 15px, `t` 11px | Low |
| `reroll` | `#5fb8ff` | Literal use on the reroll control + die reroll-select badge | `t` 11px | Moderate-High — appears on every rerollable die, every turn |
| `shard` | `#ffd76a` | Literal use (HUD currency counter), reward-ternary, `ucicow` fallback, `EV_IC.casino` | `t` 11px, `ricon` 38px, `ucicow` 20px, `evic` 40px | Very High — the HUD Shard counter is visible on nearly every combat/map screen |
| `boss` | `#ff5f5f` | `NODE_INFO.boss.ic` only | `nic` 30px | Moderate — once per boss map node |
| `elite` | `#ffa94d` | `NODE_INFO.elite.ic` only | `nic` 30px | Moderate — once per elite map node |
| `event` | `#c78cff` | `NODE_INFO.event.ic`, `EV_IC` fallback default | `nic` 30px, `evic` 40px | Moderate |
| `shop` | `#ffd76a` | `NODE_INFO.shop.ic`, literal use (shop screen header) | `nic` 30px, `evic` 40px | Moderate |
| `chest` | `#5fb8ff` | `NODE_INFO.treasure.ic`, reward-ternary, `ucicow` fallback | `nic` 30px, `ricon` 38px, `ucicow` 20px | Moderate-High |

**Size-class legend** (`.icow.<cls> svg`, `client.html:1092-1097`, plus a few
inline containers found while grepping): `t` 11px, `tn` 12px, `ific` 14px,
`ii` 15px, `di` 22px, `nic` 30px, `ricon` 38px, `evic` 40px. `ARCH_IC`'s
consuming class (`ai`, playstyle badges at `client.html:4047,4725`) has **no
explicit `.icow.ai` size rule** in the CSS I could find — flag for
`technical-artist` to confirm its actual rendered px size (likely inherits a
browser SVG default) before choosing a raster export resolution for it.

## 2. The reuse pattern a replacement must not break

The same 25 shapes are not each single-purpose — four different lookup
tables reuse them for four different meanings:

- `FT_IC` — die-face effect type (9 keys)
- `ST_IC` — status-effect badge (9 keys, `freeze` handled outside this map)
- `ARCH_IC` — playstyle-archetype badge (10 keys, all reusing `FT_IC`/`ST_IC`
  shapes — e.g. the `poison` glyph doubles as the "poison-build" trophy icon)
- `EV_IC` / `NODE_INFO.*.ic` — world-map event/node-type icon (11 keys total
  across both, again reusing the same shape pool)

This reuse existed because hand-drawing a new 8×8 pixel grid had a real
authoring cost — reusing `poison` for both "this face poisons" and "you built
a poison-focused run" was a deliberate economy, not a design intent that the
two contexts must look identical forever. **§7 flags this as an open scope
question** now that sourcing real Drive art removes the original cost
constraint, but this spec's core deliverable (§3, §4) assumes the reuse
pattern stays as-is unless the product owner says otherwise, since collapsing
it back to 1:1 would roughly triple this task's asset count.

Whatever replaces the render internals, **the call surface must not change**:
`ico(name, sizeClass, colorOverride)` / `icoSvg(name, color)` is called from
~35 sites across `client.html`. A replacement that keeps this exact function
signature (swapping what happens *inside* `icoSvg()`/`ico()` from "draw an
8×8 grid as inline SVG" to "return an `<img>`/different `<svg>` for that
name") needs zero call-site edits anywhere else in the file.

## 3. Visual direction — options and recommendation

**Option A — Painterly Axie-art thumbnails, matching the Hero/Boss real-art
style.** Rejected. These icons render inline at 11-40px, frequently several
at once on one card (a unit's status row alone can show up to 4 simultaneous
chips). A photographic/painted texture reads as an indistinct colored blob at
that size — a straight legibility regression, not an upgrade. This is the
same reasoning the prior pass (`real-art-adoption-plan-2026-09-07.md` §6B)
already established for `FT_IC`; it applies with equal or greater force here
since several of these render even smaller (11px) than a die-face icon (22px).

**Option B — Clean flat/line icon set, sourced from Drive's existing flat-
icon folders (not its character-art folders). RECOMMENDED.** Same functional
role, same size range, same one-flat-fill-color-per-icon convention `IC_COL`
already uses — just smooth/vector-quality edges instead of a blocky 8×8
pixel grid. This is the most literal reading of "icon bình thường" (normal
icon): the complaint is the *blockiness*, not that the icons aren't
photographic. It is also a direct, low-risk extension of work already done
this session — the "Battle Status Icon" Drive folder found in §8 of the
real-art plan is itself a flat icon pack, not painted character art,
confirming this is what "appropriate art in Drive" already looks like for
this specific system.

**Option C — Small painted "badge" icons, matching Hero/Boss painterly
style but simplified into a coarse circular badge (mobile-gacha-game
convention).** A real middle ground, but rejected as the *primary* direction:
it needs bespoke simplification work (the Chimera/Avatar Drive assets are
full illustrations, not pre-simplified badge art), and legibility at 11-15px
is still a real risk even simplified. Worth keeping as an optional *future*
upgrade for only the 3 largest slots (`nic` 30px, `ricon` 38px, `evic` 40px —
`boss`/`elite`/`event`/`shop`/`chest`/`heal`/`summon`/`buff`/`burn`), where
there is enough pixel real estate for a painted badge to read cleanly, but
not for this pass.

**Option D — Same as B, methodology explicitly extended from §8.** Not a
separate direction, just naming the connection: §8 already ran this exact
process (name-match against a Drive folder, flag confidence, keep the
procedural icon where no confident match exists) for the 9 `ST_IC` keys.
**Recommendation: reuse that exact methodology for the remaining 16 icons**
(`FT_IC`'s 9, plus `reroll`/`shard`/`boss`/`elite`/`event`/`shop`/`chest`
which have no `ST_IC` overlap), rather than inventing a new evaluation
process.

**Decision: Option B/D — flat icon art, sourced from Drive's flat-icon
folders, using §8's name-match-and-confidence-flag methodology extended to
all 25 entries. Painterly art (Option A) is out. A painted-badge future
upgrade (Option C) stays optional and scoped to the 3 largest size classes
only, not part of this pass.**

## 4. Target size & format spec

**Size targets** — export at minimum 3x the largest size class that icon
actually renders at, so a single source asset stays crisp at every size it's
used (no per-size art needed):

| Render tier | Icons that hit it | Min. export resolution |
|---|---|---|
| 40px (`evic`) | `buff`,`summon`,`burn`,`shard`,`event`,`shop`,`chest` | 120×120px source |
| 38px (`ricon`) | `heal`,`poison`,`reroll`,`shard`,`chest`,`summon` | 114×114px source |
| 30px (`nic`) | `dmg`,`elite`,`boss`,`event`,`shop`,`chest` | 90×90px source |
| 22px (`di`) | all `FT_IC` members (`dmg,shield,heal,mana,poison,buff,debuff,summon,blank`) | 66×66px source |
| 11-15px (`t`/`tn`/`ii`/`ific`) | all 25, this is the floor every icon must also read at | still export from the same source above, downscaled — do not author a separate tiny-only asset |

Every icon must be legible at its *smallest* used size (11px) even though
several also render larger elsewhere — design each glyph for the 11px case
first, the way the original 8×8 `IC_G` grids were.

**Format fork — SVG vs. raster PNG (needs technical-artist + actual Drive
file inspection to close):**

- **If the source Drive folder offers (or can export) vector/SVG art**:
  prefer SVG. It fully preserves the current `IC_COL`-recolor mechanic —
  `icoSvg()` bakes one hex fill directly into the SVG markup per call
  (`client.html:1893-1908`), which is how the same icon shape currently
  renders in different colors in different contexts (e.g. `shield` icon
  color differs from its border elsewhere). A raster PNG **cannot** be
  recolored this way without either (a) pre-baking one file per color
  variant needed, or (b) fragile CSS filter tricks (hue-rotate/drop-shadow
  hacks) that this project's own Hero/Boss pass (session-state item 8) just
  spent effort *removing* elsewhere — do not reintroduce that pattern here.
- **If only PNG/raster is available** (the §8 "Battle Status Icon" folder is
  confirmed PNG, 3-12KB/file): accept losing the per-instance CSS-recolor
  mechanic. Each icon then needs to be pre-colored close to its current
  `IC_COL` hex (table in §1) at source, and any context that currently
  recolors the *same* icon name differently (rare — mostly `ARCH_IC` badges
  pass an explicit `col` override) needs its own pre-baked variant or must
  accept losing that override.
- **Embedding mechanism either way**: base64-embed following the exact
  precedent already in the codebase (`cosmetics.js`'s `COSMETIC_AVATARS`,
  or the proposed non-badge `houseArtWrap()`-style wrap from
  `real-art-adoption-plan-2026-09-07.md` §1) — **not** the `⛓ "Real Axie NFT
  art"` badge treatment, since these are functional UI chrome, not a player-
  owned asset claim (same reasoning that plan already established for
  Hero/Boss art). `ico()`'s return type changes from "a `<span>` containing
  inline SVG" to "a `<span>` containing either a re-colorable inline SVG or
  an `<img src="data:...">`" — an implementation detail for whoever codes
  this, not a call this spec needs to make now.

**Naming convention** (per this project's asset-naming rule): `ui_icon_
<name>_<size>.svg` / `.png`, e.g. `ui_icon_poison_22.png`.

## 5. BLOCKING dependencies — asset-selection phase cannot start without these

This spec is decision-ready (inventory, direction, size/format target are all
locked); **picking the actual final file per icon is blocked** on two inputs
that have not reached this session:

1. **Exclusion reference image.** Product owner separately mentioned an image
   showing which icons should be **excluded** from this replacement (kept as
   the current pixel style) — that image has not been shared in this session.
   Do not assume "all 25" is the final scope until this is seen; it may carve
   out a subset the same way §8 already carved out `blind`/`burn`/`undying`
   from `ST_IC` for a *different* reason (no matching art existed, not a
   deliberate style choice).
2. **Drive folder access.** `art-director` has no Drive access in this
   session (per standing note in this agent's memory) — `lead`/product owner
   needs to fetch candidate files. Two folders are already known-good
   starting points from the prior pass, both flat-icon-style (Option B),
   not character art:
   - "Battle Status Icon" (`1OPxS21x_0miVFkEUcUM6kkssqsQ8_yQ5` → PNG subfolder
     `1vnmfXmaUfMhpXulkPWeNBp9CFi-bLACK`) — **head start, not new work**:
     6 of 9 `ST_IC` keys already have a High/Medium-confidence name match
     (`poison→Poison.png`, `regen→Regen.png`, `weaken→Weak.png`,
     `vuln→Vulnerable.png`, `stun→Stunned.png`, `thorns→Spike.png`,
     medium confidence) — see full table and reasoning in
     `real-art-adoption-plan-2026-09-07.md` §8, not repeated here. That
     folder's complete 48-title listing has already been enumerated and
     confirmed to have **no** match for `blind`/`burn`/`undying` — keep the
     procedural pixel icon for those 3 permanently unless a different folder
     turns up a real match; do not force a mismatched icon onto a status
     just to hit 25-for-25.
   - "Icon Cosmetic types" (`1Velct3Q5kKHrNFbbYKG24IlbcjZG_vKj`) — not
     applicable to this spec's 25 icons (it's category glyphs for the
     cosmetic wardrobe, see §9 of the same prior-pass doc); noted here only
     so it isn't confused with a source for this task.
   - The remaining 16 icons (all of `FT_IC` plus `reroll`/`shard`/`boss`/
     `elite`/`event`/`shop`/`chest`) have **not** been searched against
     Drive yet — this is the bulk of the remaining work, and needs the same
     name-match-plus-confidence-flag pass §8 already modeled, run against
     whatever folder(s) the exclusion image and Drive access reveal.

**Recommended next step once both unblock**: re-run §8's exact methodology
(name/visual match, confidence flag, explicit "keep procedural icon"
fallback when no confident match exists) against the 16 not-yet-searched
icons, then a single visual-confirmation pass (view the actual candidate
files, not just filenames) across all 25 before any implementation starts.

## 6. Implementation notes (for `technical-artist` / `ui-programmer`, not scoped here)

- Keep `ico(name, cls, col)` / `icoSvg(name, col)`'s call signature
  unchanged — swap only what happens inside them. Zero edits needed at any
  of the ~35 call sites listed in §1/§2.
- Rollout can be incremental, one icon at a time, since nothing else depends
  on all 25 shipping together — there's no reason to block this behind a
  single big-bang swap.
- Per-icon fallback rule (already established by §8, restated for the full
  set): if no confident Drive match exists for a given icon, **keep its
  current procedural `IC_G` grid** rather than substituting a mismatched
  image. A wrong-semantic icon actively misleads the player about what a
  status/effect does — worse than a consistent legacy pixel icon standing
  out among newer flat ones for a handful of hold-outs.
- `freeze` is not in `ST_IC` (hardcoded literal call sites, §1) — don't miss
  it when auditing coverage; it's still one of the 25.
- Re-verify `tools/verify.mjs`'s icon/contrast checks after any swap — this
  is the same UI-rule gate every other visual change in this project runs
  through.

## 7. Open question, non-blocking (flag for game-designer / product owner)

Should `ARCH_IC` (playstyle badges) and `EV_IC`/`NODE_INFO` (event/map-node
icons) keep reusing the same 25 shapes 1:1 with `FT_IC`/`ST_IC`, or should
some of them get **distinct** art now that hand-drawing a new pixel grid is
no longer the cost constraint that originally justified the reuse (§2)? For
example, a "poison-build" playstyle trophy badge could look meaningfully
different from the in-combat "poison" status pill once both are sourced from
a large Drive library instead of hand-authored. **Not a blocker for this
spec** (§3/§4 already work for either answer — this only changes how many
*additional* Drive files need sourcing beyond the 25 in §1), but worth a
product/design call before implementation locks in, since saying "yes, give
these contexts distinct art" could roughly double or triple this task's
asset-sourcing scope beyond §5's 25.
