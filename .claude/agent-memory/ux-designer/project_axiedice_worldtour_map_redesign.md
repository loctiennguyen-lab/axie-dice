---
name: project-axiedice-worldtour-map-redesign
description: World Tour in-map screen (scTourMap) node-on-path redesign — spec at design/ux/world-tour-map.md; v1 SHIPPED 2026-09-08, a further Candy-Crush-style pass is now under research (see project_axiedice_worldtour_candycrush_pass)
metadata:
  type: project
---

**UPDATE 2026-09-09: this spec's v1 (node-on-path, per §4-§8) is IMPLEMENTED,
not just drafted** — confirmed by reading `scTourMap()` directly
(`src/client.html:5506-5597`, CSS `.tournode`/`.tourboard`/`.tourpath`/
`.tourpawn` ~1702-1730) and `production/session-state/active.md`'s 2026-09-08
entry #19. Full-bleed board, dashed SVG path, circular reward-thumbnail/boss-
portrait pins, lock/ready/got states, interpolated pawn — all real. Don't
re-derive this from scratch next time; only the items still flagged open below
(node coordinate fine-tuning, ascMax landmark icon) remain outstanding. A
*second*, later redesign pass (product owner now wants Candy-Crush/Homescapes
style: numbered zone-colored circles, stars, persistent currency HUD) is
tracked separately in [[project_axiedice_worldtour_candycrush_pass]] — do not
conflate the two asks.

**Status (2026-09-08, historical — see update above): DRAFT spec written to file, NOT yet implemented/approved.**
Full spec: `design/ux/world-tour-map.md`. Product owner (translated complaint):
current `scTourMap()` UI is "bad and ugly," wants tiles turned into nodes
positioned along the actual painted path in the map art (war-map style),
explicit reference **Bingo Blitz**. Also separately complained the map art
itself is "confined in a box" / badly cropped.

**Root cause of the crop bug, and an important correction to how I first
framed it**: today's code paints the ~3:1 landscape map art as a CSS
`background-image` + `background-size:cover` on a div nested inside `#app`
(`max-width:1240px`). The task that spawned this spec pointed me at `#bgLayer`
(the game's existing full-bleed-art fix, a `position:fixed` sibling of `#app`
outside its zoomed subtree) as "the established pattern for exactly this bug"
— **but on close reading of `#bgLayer`'s own bug comment (`client.html:327-335`),
that documented bug was specifically about a background painted on an
*ancestor* of `#app` (body) desyncing where it showed through `#app`'s
transparent areas at the zoom boundary — not a general claim that any content
fully *inside* a zoomed `#app` subtree seams.** A plain descendant (a real
`<img>`, not an ancestor background) zooms uniformly with the rest of its
subtree. So the spec recommends trying the much simpler fix first — a CSS
"full-bleed breakout" (`width:100vw;left:50%;margin-left:-50vw`) on a normal
`#app` descendant, no new DOM sibling, no `build.py` change — with a mandatory
screenshot-verify at both zoom states before falling back to the heavier
`#bgLayer`-mirroring sibling approach if that breakout is found to seam.
**Remember this distinction next time a "the art looks boxed/cropped" bug shows
up here — don't reflexively reach for the `#bgLayer` sibling pattern just
because a background-art bug rhymes with the old one; re-derive which half of
that bug (ancestor-showing-through vs. contained-descendant) actually applies.**

**Bingo Blitz reference resolved to**: fixed-render-height, native aspect
ratio, horizontal-scroll board (not `background-size:contain` shrink-to-fit) —
contain would make nodes too small to hit `--tap-min` given how extreme the
maps' aspect ratios are (~3:1 / ~2.4:1). Percent-based node coordinates only
stay glued to the path if the image is never cropped AND never non-uniformly
scaled — fixed-height+native-ratio+scroll is the only one of the three options
that guarantees both.

**Node icon source — explicitly NOT resolved, don't treat as settled**: PM
pointed at a Drive folder ("map items," `.../Map Items/Map 1`, 10 numbered
files) as a possible node-marker source. Only 1 file sampled (`1.png`, a
generic painted acorn from an old 2021 PSD) — it does not obviously match
current tile rewards (e.g. Tile 4 Map1 = "Gooey King Trophy"). Spec
recommends: reward thumbnails (existing `tourItemDef()`/`.citem-thumb` art,
already correct-and-current) for node *content*, Drive folder as an unconfirmed
*candidate* for generic marker *chrome* only, pending an actual full review of
the folder (all 10 files + the unreviewed `Map 2` sibling folder) by
art-director/PM. Landmark boss nodes get real `BOSS_ART`/`sprMon()` portraits
instead (zero new asset, stronger fit than any generic icon).

**Node coordinates**: proposed as hand-traced `{x%,y%}` per tile (10 per map,
both tables in the spec §4), visually estimated directly from the extracted
map JPGs — explicitly flagged in the spec as a starting placement to be
nudged once rendered against the real `<img>` box in-browser, not pixel-locked
truth.

See [[reference_axiedice_ui_rules]] for where the CSS design system / kbAct /
breakpoint conventions this spec reuses actually live.
