# UX Spec — World Tour Map Screen (Node-on-Path Redesign)

> **Status**: Draft, pending product-owner approval (not yet implemented)
> **Author**: ux-designer (2026-09-08)
> **Trigger**: Product owner feedback (translated) — *"the world map's UI/UX is bad
> and really ugly, I want it made into nodes along the map image... the map art
> is buggy, confined in a box, I want it to spread out fully... nodes/path should
> be a war-map style similar to other games — reference Bingo Blitz."*
> **Scope**: `scTourMap()` — the **in-map** screen only (`src/client.html:5140-5175`).
> `scTourMapSelect()` (the chapter-select grid, `4102-5139`) is a separate,
> already-reasonably-functioning screen and is **out of scope** here except
> where the BACK action hands off to it (§10). Does not reopen anything in
> `design/gdd/world-tour.md` (thresholds, `questStep()`, badge tiers, reward
> table) — this is presentation-layer only, same boundary `design/ux/echo-box.md`
> drew against its own economy doc.

## 0. Source references (traceability, current as of this pass)

| What | Where |
|---|---|
| `scTourMap(mapIdx)` (being redesigned) | `src/client.html:5140-5175` |
| `scTourMapSelect()` (unchanged, hands off to this screen) | `src/client.html:5102-5139` |
| Root cause of the "confined in a box" bug | `w.style.backgroundImage=...`+`has-bgart` on `.tourmap` (`5143-5144`), CSS `.tourmap.has-bgart{background-size:cover...}` (`1617`), inside `#app{max-width:1240px;margin:0 auto;padding:8px 12px 16px}` (`219`) |
| `#bgLayer` full-bleed precedent — **read before assuming it transfers directly, see §2** | comment block `327-335`, rule `150-157`, sibling markup `build.py:37-38`, render-time toggle `client.html:3072` |
| `TOUR_MAPS`, `TOUR_T` (tile/threshold data) | `src/data.js:918-946` |
| `tourMapDef`, `tourTileEligible`, `tourClaimKey`, `tourItemDef`, `tourClaim`, `tourClaimAll`, `tourProgress` | `src/client.html:4409-4484` |
| `tourMapUnlocked`, `tourMapAllClaimed`, `tourBadgeTier`, `tourLockReason` | `src/client.html:5086-5099` |
| `TOUR_MAP_ART['1']`/`['2']` (embedded art) | `src/art5.js` — wide landscape strips, Map 1 ≈3:1, Map 2 art was authored at a visibly different native ratio (see §2 aspect-ratio note) |
| **Master-resolution source PNGs, found 2026-09-08** — same scenes as the two rows above, uncompressed/full quality, worth re-embedding instead of the current (likely more-compressed) versions while this screen is being rebuilt anyway | product owner's supplied asset kit, `Assets/OriginsKit/PvE/UI/Chapter/map_chapter_1.png` / `map_chapter_2.png` — extracted locally at `/private/tmp/claude-501/-Users-loc-tien-nguyen-my-game/f48169e9-41e4-410a-b78f-e08b7abff470/scratchpad/origins-kit/MapUI/` |
| Reference JPGs extracted for this pass | `/private/tmp/claude-501/.../scratchpad/mapart/map1.jpg`, `map2.jpg` — viewed directly to trace path curvature for §4 |
| Reused component: `.bpbar.big`/`.bpfill`/`.bptxt` (progress bar) | CSS `1122-1125` |
| Reused component: `.citem-thumb` (22px circular reward thumb, already used in today's `scTourMap()` at `5163`) | CSS `1578` |
| Reused component: `.rchip`/`--r0..--r4` rarity ladder | CSS `683-685`, vars `114` |
| Reused component: `BOSS_ART`/`sprMon(k)` (real boss portrait art, no new asset) | `src/client.html:2916-2920`, keys incl. `gooey_king`, `agony` (`data.js:2831` mon list) |
| Reused component: `.echoshow.locked` dimming values (precedent for "state changes chrome, not just opacity") | CSS `483-485`, decided in `design/ux/echo-box.md` Open Q#1 |
| `kbAct()` (real tab order for non-`<button>` elements) | `src/client.html:2299-2314` |
| `.btn.sm.ghost` BACK-button precedent inside a custom nav row | `scCodex()`, `src/client.html:5243` |
| `--tap-min` (44px guaranteed tap target) | `src/client.html:68`, applied via `.btn::before` (`267-271`) |
| Breakpoints | 1199 / 899 / 599px (see `.menu-grid--5` `388-394` for the pattern); `--ui-scale` zoom only applies `innerWidth>=1200` |
| World Tour GDD (mechanics, thresholds, badge tiers — not touched by this spec) | `design/gdd/world-tour.md` |

Confirm current line numbers against `grep -n "function scTourMap\b"` before implementation — this doc cites the 2026-09-08 state.

---

## 1. What's actually broken (diagnosis recap, one paragraph — full root cause already on file)

Today, `scTourMap()` paints the map art as a CSS `background-image` directly on the screen's own div, which lives inside `#app` (`max-width:1240px`, padded, and — above 1200px viewport width — `zoom:var(--ui-scale)`). `background-size:cover` on a ~3:1 landscape image inside a much-narrower, non-3:1 box crops away most of the image's width to fill the box, which is the "zoomed-in vertical sliver" the product owner saw. Separately, the 10 tiles render through the exact same `.bptrack`/`.bpnode` flat-grid component the Battle Pass uses — visually unrelated to the hand-painted path in the art, which is the "not node-like, ugly" complaint. Both complaints are fixed by this spec: §2 fixes the crop, §4-§8 replace the grid with nodes threaded along the actual path.

---

## 2. The full-bleed fix — what "spread out fully" should actually mean here

**Rejected: `background-size:contain`** (shrink the whole image to fit inside the viewport width, no cropping). Both map images are extreme landscape strips (~3:1 or wider). Fitting the *full width* into frame at that ratio makes the rendered image — and every node sitting on it — very short and very small. Node tap targets would fail Fitts's Law and the `--tap-min` floor on anything but a huge monitor. Rejected for the same reason a phone's tiny "zoomed-out overview map" is never the *interactive* view in games like this — it's a fine thumbnail (which is exactly what `scTourMapSelect()`'s `.tourmaptile` already correctly uses `cover` for, at small card size, and stays out of scope here), wrong for the primary interactive board.

**Recommended: render the art at a fixed height, native aspect ratio, and let it be wider than the viewport — horizontal scroll to see the rest.** This is *literally* Bingo Blitz's own board pattern (the explicitly-named reference): a big hand-painted board wider than any one screen, panned horizontally, with nodes fixed to specific points on it. Concretely:
- The art renders as a real `<img>` (not a CSS background — see why below), `height:100%` of its containing stage, `width:auto` (browser preserves native ratio).
- The stage container is `overflow-x:auto; overflow-y:hidden`, native scrollbar/trackpad/touch-swipe, no custom drag-to-pan JS (see §12 — this project deliberately has no drag-and-drop pattern anywhere else; native scroll is the lower-risk, already-idiomatic-to-the-web choice here).
- Because nothing is ever cropped and the render height is fixed, **node `{x%, y%}` coordinates authored against the image (§4) always line up with the path**, regardless of viewport width — this is the actual mechanism that makes "nodes convincingly on the path" possible at all; `cover` cannot give this guarantee (crop origin shifts with viewport width) and `contain` can but at the cost of usable node size.
- **Why an `<img>` element and not a CSS background**: percentage-based node positions need to be relative to the *rendered image's own box*. A real `<img>` gives a concrete, measurable box to anchor a `position:relative` node-overlay layer to; a `background-image` on an arbitrarily-sized div does not have this property without extra `background-size`/`background-position` math duplicated in JS. Use it as content, not decoration.
- **Aspect ratio — do not hardcode one shared ratio for both maps.** The task brief's ~3.2:1 figure describes the currently-shipped `TOUR_MAP_ART` assets as directly viewed; the GDD's own source-PNG dimensions (`Map1-new.png` 3014×985 ≈3.06:1, `Map2-new.png` 3176×1339 ≈2.37:1) suggest the two maps were never guaranteed to share one ratio. Read `naturalWidth`/`naturalHeight` off the loaded `<img>` at runtime per map rather than assuming a constant — a hardcoded shared ratio is exactly the kind of silent mismatch this project's own comments (`cxTable`'s column-width story, `client.html:5181-5211`) warn against.

**Does this need `#bgLayer`'s sibling-of-`#app` trick, or not?** Read the actual bug (`client.html:327-335`) closely before assuming it transfers: that bug was specifically a background painted on `body` (an *ancestor* of `#app`) desyncing where it showed through `#app`'s own transparent areas, at the zoomed box's boundary. It is not, on its own text, a claim that *any* content fully **inside** a zoomed `#app` subtree seams — a normal descendant zooms uniformly with the rest of its subtree, which is the entire point of the `zoom` property. That means the likely-simpler fix may work:

- **Option A (recommended starting point)** — a CSS "full-bleed breakout" on the stage element itself, staying a normal descendant of `#app`: `width:100vw; position:relative; left:50%; margin-left:-50vw;` (classic technique for escaping a centered max-width parent from the inside, no changes to `#app`, no new DOM sibling, no `build.py` change). Simpler, smaller diff, keeps the header/back-button (§3) zoom-scaled consistently with every other screen in the game.
  **Must be screenshot-verified** (per this project's own "verify UI changes with screenshots" standard) at both `--ui-scale:1` and a triggered non-1 scale (resize the window past 1200px width) before shipping — `100vw` interacting with an ancestor's `zoom` is exactly the class of subtle cross-browser quirk that produced the original bug, and nothing here proves in advance that it's clean.
- **Option B (fallback if A visibly seams)** — mirror `#bgLayer`'s proven pattern exactly: a new persistent sibling `<div id="tourStage"></div>` added next to `#app` in `build.py` (`build.py:37-38`), populated by a small hook mirroring the existing `#bgLayer` toggle at `client.html:3072`, guaranteed safe against the zoom bug because it's the identical, already-shipped fix for the identical class of problem — at the cost of needing the header block to also either live in this sibling (breaking its zoom-consistency with the rest of the game) or be positioned against it via a fixed per-breakpoint offset / `ResizeObserver` (more moving parts). Only reach for this if A fails verification; don't pre-emptively take on B's extra complexity.

This decision (A vs. B) is a `ui-programmer`/`lead-programmer` call once tested against the real build — flagged, not mine to force from a spec.

---

## 3. Screen layout, top to bottom

No vertical page scroll for this screen at all — the *board* (art+path+nodes) is the only thing that scrolls, and only horizontally. Two-row header, unchanged screen-level structure otherwise:

```
┌─────────────────────────────────────────────────────────┐
│ ‹ WORLD MAP                          "Lovely Forest I"   │  row 1: back + title
│ ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░  62/110 runs   [CLAIM ALL (2)]  │  row 2: progress + action
├─────────────────────────────────────────────────────────┤
│ ░░░ (full-bleed, horizontally-scrollable painted map,    │
│      path + 10 nodes threaded along it, §4-§8)      ░░░  │  the board
└─────────────────────────────────────────────────────────┘
```

- **Row 1**: a small `.btn.sm.ghost` "‹ WORLD MAP" (same component `scCodex()`'s nav already uses for BACK, `5243` — not a new pattern) at left, `mapDef.name` as the existing `h1.logo.sm` at center/right. Replaces today's separate full-width `BACK TO WORLD MAP` button at the very bottom (§10 explains why the bottom position stops working once the board is a fixed-height scroll region rather than a long page).
- **Row 2**: `.bpbar.big` (unchanged component) + `CLAIM ALL (N)` button (unchanged logic, `tourClaimAll`), same as today — just relocated to a persistent header instead of floating above a long grid. Reasoning in §9.
- **Board**: everything in §4-§8. Stays visible without scrolling the *page* — only the board's own internal horizontal scroll moves.

---

## 4. Node positioning — data shape and per-map coordinates

**Data shape**: add a `node:{x,y}` (percent, 0-100, relative to the rendered image's own box, top-left origin) directly onto each tile object in `TOUR_MAPS` (`src/data.js:919-946`), e.g.:

```js
{i:4, landmark:{type:'boss',boss:'gooey_king'}, reward:{cat:'decor',key:'tour_gooeytrophy'}, node:{x:40,y:58}},
```

**Why embed on the tile object, not a parallel indexed array**: this codebase already has a named failure mode for "two arrays that must stay index-matched" (see the `cxTable` column-count comment, `client.html:5181-5211`, and the whole reason `head.length`-driven grids exist). A 10th map added later, or tiles reordered, silently desyncs a parallel `TOUR_MAP_NODES[mapIdx][i]` array from `TOUR_MAPS[mapIdx].tiles[i]`. Embedding removes the failure mode entirely — `t.node` travels with `t.reward`/`t.landmark` as one unit, same as those two already do.

**Proposed coordinates** — visually traced against the actual art (`map1.jpg`/`map2.jpg`, read directly for this spec). These are a **starting placement, not pixel-locked truth**: nudge ±3-5% per point once rendered live against the real `<img>` box in a browser (a designer eyeballing a static JPG and a programmer eyeballing the live DOM element will not land on identical numbers, and the live one wins).

**Map 1 — "Lovely Forest I"** (grass hill → river → tree/torii shrine → bushes → mossy mountain peak):

| Tile | x% | y% | Note |
|---|---|---|---|
| 1 | 6 | 87 | Path entry, bottom-left grass |
| 2 | 13 | 58 | Climbing the left grassy hill |
| 3 | 19 | 26 | Near the hilltop |
| 4 (landmark, boss `gooey_king`) | 40 | 58 | At the big tree / torii shrine — thematically the "guardian" location |
| 5 | 50 | 76 | At the torii gate's base |
| 6 | 60 | 64 | Past the torii, rising into bushes |
| 7 | 69 | 45 | Climbing through the small evergreens |
| 8 | 78 | 30 | Approaching the mossy mound |
| 9 | 87 | 18 | Climbing the moss mountain |
| 10 (landmark, `ascMax>=1`) | 95 | 9 | The summit — "reach Ascension" landing on the literal peak is a deliberate, free thematic pairing, keep it |

**Map 2 — "Lovely Forest II"** (lotus ponds → stone dam → lake edge → wooden bridge → dense pines):

| Tile | x% | y% | Note |
|---|---|---|---|
| 1 | 5 | 62 | Small lotus ponds, bottom-left |
| 2 | 13 | 38 | Climbing toward the dam |
| 3 | 21 | 14 | Crossing the stone dam |
| 4 | 31 | 30 | Descending the main lake's left edge |
| 5 | 41 | 50 | Lake edge, past the small tree island |
| 6 | 50 | 68 | Approaching the wooden bridge |
| 7 | 59 | 80 | Crossing the wooden bridge |
| 8 | 69 | 64 | Entering the pine forest, rising |
| 9 | 80 | 42 | Climbing deeper into the pines |
| 10 (landmark, boss `agony`) | 93 | 16 | Exiting through the darkest, densest pines — fitting for the capstone final boss |

---

## 5. Path/connector line

A thin dashed/dotted line joining the 10 nodes in order, reusing the *same* `{x,y}` points nodes use (guarantees the line and the nodes can never drift apart from each other, even if §4's numbers get tuned later).

- Implementation: one SVG `<polyline>` (or `<path>`, if a softer curve through the points is wanted as later polish — not required for v1, straight segments between 10 points read fine at this density) absolutely positioned over the image, `viewBox="0 0 100 100"`, `preserveAspectRatio="none"`, points supplied as the same percent pairs.
- **Must set `vector-effect="non-scaling-stroke"` on the line** — `preserveAspectRatio="none"` maps x and y through different scale factors (image is ~3:1, not square), so without this the dashed stroke renders visibly thicker on one axis than the other.
- Color: a warm off-white/cream dashed stroke with a subtle dark outline or drop-shadow (`filter:drop-shadow(...)` or a doubled stroke), specifically because it needs to read against **both** maps' very different palettes (Map 1 green/earth tones, Map 2 blue/teal) — a single flat color tuned for one map may vanish against the other. Exact color/opacity is `art-director`'s call; the requirement is "must pass a contrast check against both map backgrounds," not a fixed hex.
- This directly answers the brief's "a line/dotted trail... echoing the path" ask.

---

## 6. Node visual states — locked / ready / claimed

Reuse the state *logic* already computed in today's code (`got`/`ready`/else-locked, `client.html:5157-5158`) — only the *rendering* changes, from a rectangular `.bpnode` card to a round pin. Per the accessibility checklist, **no state may be color-only** — each gets a distinct icon/shape, not just a border-color swap:

| State | Shape/icon | Notes |
|---|---|---|
| **Locked** | Grayed pin, padlock glyph | Not clickable (no `onclick` assigned at all, matching the existing "never `kbAct()` a dead card" convention, `client.html:2295-2298`) |
| **Ready to claim** | Full-color pin, small pulsing glow, distinct "!"/gift glyph | Clickable, `tourClaim()` unchanged; the pulse must gate through the same reduced-motion path as `.echopull.glow` (`client.html:502-504`) — same precedent, same requirement, do not skip the off-switch this time either |
| **Claimed** | Full-color pin, checkmark badge overlay, slightly muted (not grayed — still legible as "part of my path") | Not clickable |

All three keep their existing tap-min-guaranteed clickable area (`--tap-min`, same as every other interactive control) even though the *visual* pin can be smaller.

---

## 7. "You are here" marker

A separate marker element (not a 4th mutually-exclusive tile state) — a pawn/flag icon sitting **on the path itself**, at a point interpolated between the two nearest tile anchors using the exact same math `tourProgress()`/`TOUR_T` already expose:

```
t = (progress(map) − T(i)) / (T(i+1) − T(i))     // 0..1 between the last-claimed tile i and the next tile i+1
pos = lerp(node[i], node[i+1], t)
```

This turns "how many runs until my next tile" into a literal visual position along the path, not just a number — reinforcing the "I am walking this path" fantasy the GDD's own Player Fantasy section describes. **Fallback if this is judged too much math for v1**: snap the marker to the last-claimed tile instead (no interpolation) — strictly simpler, loses the "in-between" feel. Recommend the interpolated version; flagging the fallback so this isn't an all-or-nothing gate on shipping the rest of the redesign.

**On screen entry, auto-scroll the board so this marker starts in view** (`scrollIntoView({inline:'center', block:'nearest'})` once, after mount) — without this, a returning player is dropped at the literal left edge of a wide board every time and must manually scroll to find where they actually are, which is exactly the kind of avoidable friction a UX pass is supposed to remove.

---

## 8. Landmark tiles

Bigger pin (matches today's intent behind `.bpnode.big` for `t.landmark`, `client.html:5158`) plus a **distinct icon per landmark type**, using **real art already in the codebase, no new asset**:

- **Boss landmarks** (Map 1 tile 4 `gooey_king`, Map 2 tile 10 `agony`): show the actual boss portrait via `sprMon(boss)` / `BOSS_ART[boss]` (`client.html:2916-2920`) inside the bigger pin frame. This is strictly stronger than a generic "boss skull" icon — it tells the player exactly which fight they're walking toward, and it's a zero-new-asset reuse of the real-art pass already shipped for this game (`production/session-state/active.md` item on Hero/Boss real art).
- **`ascMax` landmark** (Map 1 tile 10, "reach Ascension"): has no boss to borrow art from. Needs a generic marker (mountain-peak / summit-flag reads well given §4's placement at the literal art peak). Source TBD — see §14's open question on marker-chrome art sourcing.

---

## 9. Node content — reward thumbnail vs. generic marker (the open question, handled honestly)

The product owner pointed at a Drive folder ("map items," 10 numbered files, sampled `1.png` = a painted acorn) as a possible source for node art. **Do not commit to that folder's contents sight-unseen** — the one sampled file reads as generic decorative-collectible art from an old, unrelated map iteration (2021 "Items Chap 1.psd"), and nothing confirms the other 9 files (or the `Map 2` sibling folder, contents not yet checked) actually correspond to the *current* tile-reward table (`tourItemDef()`, e.g. Tile 1 Map 1 = Slime avatar, Tile 4 = Gooey King Trophy). Showing it, not assuming it, is the honest move here — same posture `design/ux/echo-box.md` took toward its own locked-chip filter values before a real look confirmed them.

**Recommendation: both, in the roles they're each already good at (option "c" from the brief)**:
- **Marker chrome** (the pin shape itself — the round/teardrop outline, the lock/checkmark/glow overlays from §6, the boss-portrait frame from §8) is *generic per node TYPE*, not per specific reward. This is exactly the kind of asset the Drive folder might be a good fit for, once actually reviewed in full (all 10 files + the Map 2 folder) against art-director's eye — but that review hasn't happened yet, so treat it as a candidate, not a decision.
- **Node content for regular (non-landmark) tiles** reuses the existing reward thumbnail (`item.src||item.img` via `tourItemDef()`, already rendered today via `.citem-thumb` at `client.html:5163`) inset inside the pin — same visual language `.echoshow` already uses (real art in a small circular frame, not a "???" blackout, not a mismatched decorative icon). This guarantees the node visibly promises the *correct*, current reward, which the acorn-style Drive art cannot yet guarantee.

**This whole section is pending a real look at the Drive art (all of it, not just tile 1) — flagged again in Open Questions.**

---

## 10. CLAIM ALL + progress bar placement

Moves from "above the grid, its own block" to the persistent header (§3, row 2) — unchanged logic (`tourClaimAll(mapIdx)`, `tourProgress(mapIdx)`), only relocated. Reasoning: once the board is a horizontally-scrolling region rather than one long vertical page, "above the grid" stops being a meaningful position — a player scrolled to tile 8 would no longer see it. A persistent header keeps the map's single most valuable bulk action (claim everything ready at once) reachable with zero scrolling from anywhere on the board, which is the same Fitts's Law reasoning `echo-box.md` §3 already applied to its own primary action (biggest, most central, never below a scroll).

---

## 11. BACK TO WORLD MAP

Moves from a full-width button below the grid to the small `.btn.sm.ghost` "‹ WORLD MAP" in the header's row 1 (§3), reusing `scCodex()`'s own nav-row BACK precedent (`client.html:5243`) rather than inventing a new floating-corner-button pattern. Forced by the same layout change as §10 — there is no natural "bottom of the page" left to put a full-width button once the board doesn't scroll vertically.

---

## 12. Responsive behavior

- Applies at all 3 existing breakpoints (1199/899/599px) — no new breakpoint needed.
- Board height should be a viewport-height-relative value with sensible min/max clamps per breakpoint (exact px values are `art-director`/`ui-programmer`'s call — the requirement is "large enough that node tap targets stay comfortably above `--tap-min`," not a specific number).
- Landscape-only touch behavior is unchanged from the rest of the game (per `technical-preferences.md`, phone portrait already shows the existing rotate-device prompt) — this screen doesn't need its own portrait handling.
- No custom drag-to-pan on touch — native horizontal swipe-scroll on the board container is sufficient and keeps this screen consistent with the project's existing "no drag-and-drop" posture (`technical-preferences.md`), rather than introducing the one place in the game that has custom pointer-drag logic.
- Optional (not required for v1): a small fading "← scroll to explore →" hint on first view of a given map, dismissed after the first scroll interaction — there's no existing first-time-hint component in this codebase to reuse, so treat this as new, low-priority polish, not a blocker.

---

## 13. Accessibility pass

Run against this project's own checklist:

- [x] **Keyboard only**: every node keeps a real `onclick` + `kbAct()` (or becomes a real `<button>`) exactly as today (`client.html:5169`) — no new clickable-div-without-focus-handling pattern. DOM order should match path order (tile 1→10), so native Tab order already walks the path correctly with no extra work. Add `tabIndex=0` to the scrollable board container itself so a keyboard user can also scroll it directly (arrow keys/Home/End) before or between tabbing through individual nodes. **Verify**: Tab-cycling from node 1 to node 10 auto-scrolls the board horizontally via the browser's default scroll-into-view-on-focus behavior, reaching node 10 without ever touching a mouse.
- [x] **Gamepad only**: N/A, this project has no gamepad support (`technical-preferences.md`).
- [x] **Text readable at minimum font size**: reuse existing type scale (`--t1`..`--t6`) for any label/tooltip text on nodes — no new smaller-than-`--t1` text.
- [x] **Functional without color alone**: §6 already specifies icon/shape differences per state, not color-only. §5's path line should not be the *only* way a locked node's position relative to progress is legible — the pin's own lock glyph carries that.
- [x] **No flashing content without warning**: the ready-state pulse (§6) and any per-tile claim flash reuse existing `flashScreen()`/`wantsLessFlash()`-gated primitives, same as `tourClaim()`'s current `flashScreen('gold')` call (`client.html:5169`) — unchanged, still gated.
- [x] **Subtitles for dialogue**: N/A, no dialogue on this screen.
- [x] **UI scales correctly at all supported resolutions**: covered by §12; the one new risk is §2's zoom-interaction question, which is exactly why that section mandates a screenshot verification step rather than assuming either fix option is automatically safe.

---

## 14. Implementation notes for `ui-programmer`

- **Data**: add `node:{x,y}` to every tile object in `TOUR_MAPS` (`src/data.js:919-946`) per §4's tables. No change to `TOUR_T`, `tourProgress()`, `tourTileEligible()`, `tourClaim()`, `tourClaimAll()`, or any threshold/formula — this spec is presentation-only, per the scope note at the top.
- **`scTourMap(mapIdx)`**: restructure per §3 — two-row header (`.btn.sm.ghost` back + `h1.logo.sm` title; `.bpbar.big`/`.bpfill`/`.bptxt` + `CLAIM ALL` button) unchanged in logic, relocated in layout; replace the `.bptrack`/`.bpnode` loop (`5154-5171`) with the node-on-path board (§4-§8).
- **Full-bleed mechanism**: attempt §2 Option A first (CSS breakout, no structural change) and screenshot-verify at both zoom states before falling back to §2 Option B (new `build.py` sibling + `client.html:3072`-style toggle hook). Remove `w.style.backgroundImage`/`has-bgart` (`5143-5144`) and `.tourmap.has-bgart` (CSS `1617`) — replaced by the real `<img>` element per §2.
- **New CSS classes** (names proposed here, palette/spacing is `art-director`'s call): `.tourboard` (scroll container), `.tourboard-inner` (the `position:relative` layer sized to the `<img>`'s rendered box, holding the `<img>`, the SVG line, and the node buttons), `.tournode` (+ `.tournode.locked`/`.ready`/`.got`), `.tournode.landmark` (bigger variant), `.tourpawn` (§7's "you are here" marker), `.tourmap-header` (wraps the two header rows). Reused as-is: `.bpbar`/`.bpfill`/`.bptxt`, `.citem-thumb`, `.btn.sm.ghost`, `.echopull.glow`'s reduced-motion pattern (for `.tournode.ready`'s pulse).
- **Boss-landmark art**: reuse `sprMon(t.landmark.boss)` (`client.html:2916`) directly — do not introduce a second boss-art lookup.
- **SVG path line**: `vector-effect="non-scaling-stroke"` is required, not optional — see §5 for why (`preserveAspectRatio="none"` scales x/y differently since the art isn't square).
- **Pawn interpolation** (§7): `lerp` between `t.node` of the last-claimed tile and the next tile, using the same `progress`/`T(i)` values `tourTileEligible()` already computes — no new data dependency, just new math in `scTourMap()`.
- **No new assets required** for anything in §4-§8 except the still-open ascMax-landmark marker icon (§8) and whatever marker-chrome art §9 ultimately draws from the Drive folder, if any — everything else (reward thumbnails, boss portraits, progress bar, buttons) is existing art/components.

---

## Open questions (need PM / other-agent decision, not mine to make)

1. **§2 — Option A vs. Option B for the full-bleed fix.** Needs a real screenshot test against a built `AxieDiceTactics.html` at both `--ui-scale:1` and a triggered non-1 scale before either is locked in. `lead-programmer`/`ui-programmer` call.
2. **§9 — node icon source — RESOLVED (2026-09-08), negative result.** Both `Map Items/Map 1` (10 files) and `Map Items/Map 2` (6 files) were reviewed in full. Map 2's folder is even more telling than Map 1's: only 6 files exist for a 10-tile map, and both folders' source PSDs are literally named `"Stage Item.psd"`/`"Stage Item 2.psd"` — this is generic background-scenery clutter (rocks/props scattered around the painted map for visual richness), not one-marker-per-tile art, and was never meant to key 1:1 against tile indices. **Do not use this folder for node markers.** Separately, the product owner supplied two more asset kits this session; a full master-resolution version of both map backgrounds was found (`PvE/UI/Chapter/map_chapter_1.png`/`map_chapter_2.png` — pixel-identical scene to the currently-embedded `TOUR_MAP_ART`, but uncompressed/higher-quality) worth swapping in as a free visual upgrade regardless of the node-marker question, and a `flag_location.png` (a location-nameplate ribbon banner, not a path pin) which doesn't fit the "you are here" pawn role either. **No ready-made node-marker/pin asset was found in any supplied source.** §6/§9's original recommendation stands as the fallback: marker chrome (pin shape, lock/checkmark/glow overlays) should be built as new, simple CSS/vector shapes rather than sourced art, since nothing supplied actually fits: The reward-thumbnail-inside-a-pin approach for node *content* is unaffected by this and should proceed as designed.
3. **§8 — ascMax-landmark icon** (Map 1 tile 10, "reach Ascension," no boss to borrow art from). No existing real-art asset covers this; needs either a new small icon (art-director) or confirmation the Drive folder (once reviewed per Q2) has something usable.
4. **§4 — node coordinates are a starting placement, not final.** Explicitly flagged in §4 itself; needs a pass with the real rendered `<img>` in a browser before being treated as locked values.
5. **§7 — interpolated pawn vs. snap-to-tile fallback.** A scope/complexity call for whoever implements this, not a design disagreement — recommend interpolated, fallback is explicitly acceptable if time-constrained.
