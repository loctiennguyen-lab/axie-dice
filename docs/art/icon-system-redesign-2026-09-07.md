# Icon System Redesign — Pixel Icon Replacement Spec

Status: **READY FOR IMPLEMENTATION** as of 2026-09-08 — both §5 blockers
cleared (see §5 changelog below). 17 of 25 `IC_G` icons plus 1 new icon
(`battle`, see §5) have a real-art source now; the remaining 8 stay
procedural pixel with a documented reason. No code has been changed in this
pass — this is a spec update only, handing off to `ui-programmer`/
`technical-artist`.
Author: art-director (2026-09-07, updated 2026-09-08)
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

## 5. Asset sourcing — RESOLVED 2026-09-08

**What changed**: the product owner supplied a real icon set directly into
the repo (`assets/_incoming/icon-set-2026-09-08/`, manifest + README +
files), bypassing the Drive-access blocker entirely. No exclusion reference
image was ever provided, before or with this delivery.

**Blocker 1 (exclusion image) — resolved by absence, not by seeing it.**
Treat "no exclusion image was shared" as "no icon is deliberately excluded by
product-owner intent." This is a different situation from the 8 icons that
still stay pixel below — those are unswapped because **no source art for
them arrived**, not because anyone marked them "keep as pixel." If an
exclusion image turns up later naming one of the 17 icons below as
"keep pixel," that overrides this spec's call for that one icon; nothing
else in this pass assumed an exclusion.

**Blocker 2 (Drive access) — moot.** The delivered set did not come from the
two Drive folders named in the original §5 (Battle Status Icon / Icon
Cosmetic types) — it traces to `@axieinfinity/dango-icons` (part icons) and
the `axie-origins-asset-kit` (`Assets/OriginsKit/Textures/StatusIcons/`,
node + effect icons), per `assets/_incoming/icon-set-2026-09-08/README.md`.
The §8 pre-work (6 partial `ST_IC` name-matches against Battle Status Icon)
is superseded by this delivery for the same 9 `ST_IC` keys and is not carried
forward — this set covers all 9 directly.

### 5.1 Coverage — 17 of 25 `IC_G` names get real art, plus 1 new name

| `IC_G` name | Source file | New render format | Notes |
|---|---|---|---|
| `shield` | `effect/shield.png` (kit `buff_shield_boost.png`) | PNG | also feeds `FT_IC.shield`/`ARCH_IC.shield` — same concept (a shield), safe to share |
| `regen` | `effect/regen.png` (kit `regrow.png`) | PNG | |
| `thorns` | `effect/thorns.png` (kit `buff_spike.png`) | PNG | also feeds `ARCH_IC.thorns` |
| `undying` | `effect/undying.png` (kit `goo_revival.png`) | PNG | |
| `poison` | `effect/poison.png` (kit `debuff_poison.png`) | PNG | also feeds `FT_IC.poison` (face effect) and `ARCH_IC.poison` — all three are "poison," no conflict |
| `burn` | `effect/burn.png` (kit `burn.png`) | PNG | also feeds `ARCH_IC.burn`, `EV_IC.campfire` |
| `weaken` | `effect/weaken.png` (kit `debuff_weak.png`) | PNG | |
| `vuln` | `effect/vulnerable.png` (kit `debuff_vulnerable.png`) | PNG | **key name check**: `ST_IC.vulnerable` resolves to icon name `'vuln'` (`client.html:1954`) — swap the asset under the `vuln` key, not a literal `vulnerable` key, or it silently no-ops |
| `blind` | `effect/blind.png` (kit `debuff_fear.png`, **placeholder**) | PNG | see §5.3 — adopted, not held back |
| `stun` | `effect/stun.png` (kit `debuff_stunned.png`) | PNG | |
| `freeze` | `effect/frozen.png` (kit `debuff_sleep.png`, **placeholder**) | PNG | see §5.3; `freeze` is hardcoded outside `ST_IC` (`client.html:4265,4370`) — don't miss these 2 call sites when swapping |
| `elite` | `node/elite.png` (kit `bloodmoon.png`) | PNG | `NODE_INFO.elite.ic` only, no other consumer — safe |
| `boss` | `node/boss.png` (kit `buff_fury.png`) | PNG | `NODE_INFO.boss.ic` only — safe |
| `event` | `node/event.png` (kit `secret_card.png`) | PNG | feeds `NODE_INFO.event.ic` + `EV_IC` fallback — same "unknown event" concept at two sizes, safe |
| `shop` | `node/merchant.png` (kit `snake_jar.png`) | PNG | feeds `NODE_INFO.shop.ic`, `EV_IC.merchant`, shop-screen header — same "merchant" concept everywhere, safe |
| `chest` | `node/treasure.png` (kit `rune_neutral_hybrid_1.png`) | PNG | feeds `NODE_INFO.treasure.ic`, reward-ternary, `ucicow` fallback — same "treasure/chest" concept everywhere, safe |
| `mana` | `cost/energy.svg` (new, hand-drawn to kit rules) | SVG | see §5.2 — feeds `FT_IC.mana`, `ARCH_IC.mana`, **and** the literal `iconChip('mana',...)` MP-cost badges (`client.html:4155,5458,5787`) |
| **`battle`** *(new name, not one of the original 25)* | `node/battle.png` (kit `wolf_pack.png`) | PNG | see §5.4 — **do not** wire this to the existing `dmg` key |

That is 11 (`effect/`, minus `shield`+`freeze` already counted, i.e. the
full 11-file folder) + 5 (`node/`, excluding the new `battle`) + 1 (`mana`)
= **17 of the original 25**, plus 1 new name (`battle`) = 18 icon slots
touched total.

### 5.2 `mana` ← `cost/energy.svg` — full reuse, with a recolor caveat

The manifest's `cost/energy.svg` slot is named "ENERGY" and the README calls
it a from-scratch SVG (no shipped Axie asset matched "mana cost"). But
tracing where a lightning-bolt-shaped mana glyph is actually *used* in this
codebase shows it already is this exact concept: `IC_G.mana` is described
in `icon-spec-body-parts.md` as "a single diagonal zigzag bolt," its
`IC_COL.mana` is `#c78cff` (purple), and `energy.svg`'s two flat tones are
`#9970F7`/`#C3A7FF` — also purple, a close match. And the die-face Mana
effect and the Lunacia Card MP cost are **the same game resource** per
`design/gdd/game-concept.md` ("Mana is a shared party resource... you spend
it on active cards... some faces grant Mana"), not two different resources
that happen to share a color. **Decision: `energy.svg` replaces the `mana`
`IC_G` entry outright**, covering all 3 of its current reuse sites
(`FT_IC.mana` die-face icon at `di` 22px, `ARCH_IC.mana` playstyle badge,
and the literal `ico('mana',...)`/`iconChip('mana',...)` MP-cost badges at
`t` 11px) — not a separate new icon key.

**Recolor caveat — flag for `technical-artist`/`ui-programmer`, not a
blocker:** `energy.svg`'s two fills (`#9970F7`/`#C3A7FF`) are baked into the
file as literal hex, not `currentColor`. The MP-cost badge currently uses
`icoSvg`'s per-call `col` override for a real gameplay signal — green
(`#66e08a`) when the player can afford the active card, red (`#ff8f8f`)
when they can't (`client.html:5787`). Two ways to handle this, either is
acceptable:
- **Option A (simplest, recommended for first pass)**: accept that the
  icon *shape* stays fixed purple; the afford/can't-afford signal still
  reads via `iconChip`'s independent `s2.style.borderColor`/`color` on the
  chip's border and cost number (`client.html:5340`) — that styling is
  separate from the SVG fill and is untouched by this swap. Net effect:
  slightly less redundant signaling than today, not a broken one.
- **Option B (preserves the mechanic exactly, small extra work)**: since
  `energy.svg` is SVG text (not a raster PNG), a thin wrapper can do a
  string substitution of the 2 literal hex values for a requested
  `(base, light)` color pair before inlining — 2 known-fixed strings to
  replace, not a generic recolor system. Worth doing if `technical-artist`
  has ~20 minutes; not required to ship.
Recommendation: ship Option A first (zero extra engineering, no regression
in practice), revisit Option B only if a playtest shows the afford/deny
signal got harder to read.

### 5.3 `blind`/`frozen` placeholders — ADOPT, do not hold back to pixel

`effect/blind.png` borrows `debuff_fear.png` and `effect/frozen.png` borrows
`debuff_sleep.png` — both flagged by the README itself as "the right look
for the wrong mechanic" (fear ≠ blind, sleep ≠ freeze). §6's existing
fallback rule says: *if no confident match exists, keep the procedural
icon rather than substitute a mismatched image, because a wrong-semantic
icon actively misleads the player.* That rule was written for the case of
**zero candidates** (force-fitting an unrelated shape just to hit 25-for-25).
This is a different case: a real character-emotion asset that is visually
*in the right neighborhood* (fear → wide/distressed eyes reads as
"perception impaired," adjacent to blind; sleep → closed eyes/Zzz reads as
"incapacitated," adjacent to frozen) and, more importantly, both statuses
sit in the same UI row as the other 9 status pills that **are** getting the
new flat-art treatment (§1 status row). Leaving 2 of 11 status icons as the
old blocky pixel style right next to 9 new flat ones is its own legibility
problem — Gestalt similarity says a broken pattern in one shared row reads
worse to the player than one icon being a slightly loose metaphor for its
mechanic. **Decision: adopt both placeholders now.** Track them as flagged
debt (the README's own "Open items" §1 already does this) — swap to
purpose-built blind/freeze art the moment it exists, no design sign-off
needed to do that swap later since it's a pure asset substitution under an
unchanged key.

### 5.4 `battle` — new key, NOT a reuse of `dmg`

`NODE_INFO.battle.ic` currently resolves to `'dmg'` (`client.html:3965`) —
the BATTLE map-node icon and the "this die face deals damage" icon are
today, incidentally, the *same* pixel shape. `node/battle.png` (kit
`wolf_pack.png`) is real, detailed scene art sized for a 30px map-node
thumbnail — exactly the kind of asset Option A (§3) already rejected for
small die-face icons on legibility grounds, and `dmg` is one of the
**highest-frequency** icons in the game (`FT_IC.dmg` renders on every
damage die face at 22px, `ARCH_IC.pierce` also aliases it). Reusing
`node/battle.png` for `dmg` would silently replace the crosshair "you deal
damage" glyph everywhere with a wolf-pack illustration — a legibility
regression at high frequency, for a context this asset was never meant to
serve. **Decision: introduce a new icon key, `battle`,** used only for
`NODE_INFO.battle.ic`; change that one table entry from `ic:'dmg'` to
`ic:'battle'`. `dmg` itself is untouched and stays procedural pixel (it's
already one of the 8 in §5.5, for the same "no source art for *this*
context" reason). This is the one place this pass breaks §2's shape-reuse
pattern — flagged here rather than silently decided, since §7's open
question about giving `NODE_INFO`/`EV_IC`/`ARCH_IC` distinct art is
otherwise still open and non-blocking everywhere else.

### 5.5 The 8 that stay pixel — no source yet, not excluded on purpose

`dmg`, `heal`, `buff`, `debuff`, `summon`, `blank`, `reroll`, `shard`. No
file in this delivery targets any of these 9 names (`dmg` is spoken for
only in its new `battle`-node role, §5.4 — its `FT_IC`/`ARCH_IC` role is
still unsourced). Reason: **no matching art exists yet in this delivery**,
not a deliberate "keep these pixel" call — the distinction matters because
if a future delivery brings matching art for any of these 8, swapping it in
needs no new design discussion, just the same mechanical process this spec
already used for the 17. Do not read this list as final/permanent the way
§5.3's placeholder decision is.

### 5.6 Format fork — resolved

Per §4's already-anticipated fork: the 17 `node`/`effect` files are **PNG**
(confirmed via `assets/_incoming/icon-set-2026-09-08/README.md`, ~128×135px
source, comfortably over the 90–120px minimums §4 set for the `nic`/`evic`
tiers) → **accept losing per-instance `IC_COL` recolor** for all 17; each
must render pre-colored close to its current `IC_COL` hex, and any context
that currently recolors one of these 17 names differently via an explicit
`col` override (mainly `ARCH_IC` badges) either gets its own pre-baked
variant or accepts the shared color — `technical-artist` to confirm per
name, not a blocker. `cost/energy.svg` and all `part/*.svg` files are true
SVG (verified by reading the files directly) → keep as recolorable/parametric
SVG per §5.2's Option B where worth the effort, plain inline SVG otherwise.

**Embedding location — do not inline these into `client.html` directly.**
This project deliberately keeps large base64 payloads (`art.js`,
`cosmetics.js`) out of the hand-edited `client.html` specifically so that
file stays cheap to read/edit (`.claude/docs/technical-preferences.md`).
The 17 new PNGs (base64) should follow that same precedent — land in a new
or existing base64-payload file alongside `art.js`/`cosmetics.js`, not as
inline data URIs inside `client.html`'s icon section. `ico()`'s call
signature stays unchanged either way (§6); only where the encoded bytes
physically live changes. Exact file choice (new file vs. appending to
`cosmetics.js`) is `technical-artist`'s call, coordinated with whoever owns
`build.py`'s file-concatenation order.

**Recommended next step**: hand this spec + `assets/_incoming/icon-set-2026-09-08/`
to `ui-programmer`/`technical-artist` for implementation. No further
design decisions are needed for the 17+1 covered names; §7's broader
`ARCH_IC`/`EV_IC` distinct-art question remains open and non-blocking as
before.

## 6. Implementation notes (for `technical-artist` / `ui-programmer`)

This spec is now implementation-ready for the 17+1 names in §5. Concrete
steps:

1. **Source files**: read directly from
   `assets/_incoming/icon-set-2026-09-08/` (`node/`, `effect/`, `cost/`) —
   see §5.1's table for the exact per-name file. Do not move/delete
   anything in that folder; this pass doesn't touch it.
2. **Keep `ico(name, cls, col)` / `icoSvg(name, col)`'s call signature
   unchanged** — swap only what happens inside them. Zero edits needed at
   any of the ~35 existing call sites, **except** the one described in
   §5.4 (`NODE_INFO.battle.ic:'dmg'` → `NODE_INFO.battle.ic:'battle'`,
   `client.html:3965`) — that is the single required call-site/data edit
   this pass introduces.
3. **PNG names (17, §5.1)**: base64-embed following the `cosmetics.js`
   `COSMETIC_AVATARS` precedent, landing in a separate base64-payload file
   per §5.6 — not inlined into `client.html` directly. `ico()`'s internals
   change from "emit inline `<svg>` from `IC_G`" to "emit `<img
   src="data:image/png;base64,...">`" for these 17 names specifically;
   `IC_G`/`IC_COL` entries for names not yet covered (§5.5) are untouched.
4. **`mana` (§5.2)**: swap to `cost/energy.svg`, inlined as raw SVG markup
   (small file, no need to base64 it — it's already text). **Strip the
   `<metadata>...</metadata>` C2PA/provenance block first** — every file in
   this delivery (PNG and SVG alike) carries one; it's several KB of inert
   provenance data with zero visual contribution and would otherwise bloat
   whichever file receives the embed for nothing.
5. **Rollout can be incremental**, one icon at a time — nothing else
   depends on all 18 shipping together.
6. **Fallback rule for anything not in §5.1's table** (i.e. the 8 in
   §5.5): keep the current procedural `IC_G` grid. Do not force a
   mismatched image onto these just because §5.3 accepted 2 imprecise
   placeholders elsewhere — §5.3's reasoning (same-row consistency) doesn't
   apply to `dmg`/`heal`/`buff`/`debuff`/`summon`/`blank`/`reroll`/`shard`,
   none of which sit in a row where the other members just went flat.
7. `freeze` is not in `ST_IC` (hardcoded literal call sites at
   `client.html:4265` and `client.html:4370`) — both need the same swap as
   any `ST_IC` member; don't miss them auditing coverage.
8. Re-verify `tools/verify.mjs`'s icon/contrast checks after any swap — the
   same UI-rule gate every other visual change in this project runs
   through. Pay particular attention to the `vuln`/`vulnerable` key-name
   mismatch (§5.1) and the `battle`/`dmg` split (§5.4) — both are easy to
   get backwards during implementation.

## 7. Open question, non-blocking (flag for game-designer / product owner)

**Partially resolved 2026-09-08**: §5.4 already forced this exact call for
one pair (`NODE_INFO.battle` vs. `FT_IC.dmg`/`ARCH_IC.pierce`) because real
art arrived that made the existing 1:1 reuse actively harmful — that one
split is decided, not open. The broader question below is otherwise
untouched by this delivery; none of the other 16 covered names needed a
similar split (§5.1's per-name notes confirm each reused context is still
the same underlying concept, e.g. `shop`/`chest`/`event` across `NODE_INFO`
and `EV_IC`).

Should `ARCH_IC` (playstyle badges) and `EV_IC`/`NODE_INFO` (event/map-node
icons) keep reusing the same 25 shapes 1:1 with `FT_IC`/`ST_IC` everywhere
else, or should some of them get **distinct** art now that hand-drawing a
new pixel grid is no longer the cost constraint that originally justified
the reuse (§2)? For
example, a "poison-build" playstyle trophy badge could look meaningfully
different from the in-combat "poison" status pill once both are sourced from
a large Drive library instead of hand-authored. **Not a blocker for this
spec** (§3/§4 already work for either answer — this only changes how many
*additional* Drive files need sourcing beyond the 25 in §1), but worth a
product/design call before implementation locks in, since saying "yes, give
these contexts distinct art" could roughly double or triple this task's
asset-sourcing scope beyond §5's 25.
