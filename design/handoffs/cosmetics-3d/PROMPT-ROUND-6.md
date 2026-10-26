# Cosmetics frames, round 6: prompt for Claude Design (8 new avatar frames)

**Cho Liam:** dán phần từ "## Round 6" trở xuống vào Claude Design. Nên đính kèm ảnh render 6 biome Land từ `asset-library/design-library/` (Savannah, Forest, Arctic, Mystic, Genesis, LunaLanding) và ảnh 4 khung mẫu: frame_l_sunburst, frame_r_aurora, frame_e_reef_01, frame_m_eclipse. Lý do chọn 8 khung và cách chia: `design/proposals/cosmetics-frames-round6-brainstorm.md`. Bản nháp, chờ Liam duyệt.

---

## Round 6: 8 new avatar frames (no dice this round)

Rounds 1-5 are approved and in the game. Do not touch any existing file. This round only adds new frames.

### Why
- The normal Echo Box has **0 Legendary frames** (only 2 Legendary dice), and only 1 Mythic frame.
- Land milestone rewards must be their own items, not shared with the Echo Box or the Pass. Today Vine Wreath (Pass), Snow Globe (Echo Box) and Genesis Sunburst (Echo Box season) are all reused as Land rewards. They all stay where they are (Snow Globe stays in the Rare box); Land gets three new ones.

### 1. How many and where each goes
8 frames. Ids use the folder names below for now (we rename later; use these in file names).

| # | Folder / id | Tier | Goes to | Theme |
|---|---|---|---|---|
| 1 | `frame_u_land_forest` | Uncommon | Land milestone 2 | Forest |
| 2 | `frame_r_land_arctic` | Rare | Land milestone 5 | Arctic |
| 3 | `frame_l_land_genesis` | Legendary | Land milestone 8 (top reward) | Genesis |
| 4 | `frame_l_biome_savannah` | Legendary | Echo Box | Savannah |
| 5 | `frame_l_biome_mystic` | Legendary | Echo Box | Mystic |
| 6 | `frame_l_biome_luna` | Legendary | Echo Box | Luna Landing |
| 7 | `frame_m_horizon` | Mythic | Echo Box | Event Horizon |
| 8 | `frame_r_cairn` | Rare | Echo Box | Stacked stones |

The six biome frames echo the six Land biomes, so owning a frame feels like owning a piece of that place. Biome render images are attached to this message; match their palettes and shapes, not literal scenery. If no render is attached for Genesis or Mystic, say so in the README and tell us what you assumed.

### 2. Looks per frame (change if you have better; keep 8 clearly different silhouettes at 40 px)
1. **Forest (Uncommon, blue band #0094FF).** Soft leafy ring with a few hanging seed pods, warm moss green body. Must NOT look like Vine Wreath (frame_u_vine) or Lily Pond. Keep it simple, Uncommon is the lowest Land reward.
2. **Arctic (Rare, green band #2DC661).** Snow-laden fir boughs with 3 red-berry dots on the top-left. Existing Rare frames already own ice, crystal, icicle, aurora and snow globe, so **no ice crystals, no icicles, no aurora, no globe**. Pine, snow cap, berries only.
3. **Genesis (Legendary, gold band #FFB444).** Primordial growth: a seed splitting open, glowing roots curling around the ring, cream and emerald light. Must NOT use rays or a sun disc (frame_l_sunburst owns those).
4. **Savannah (Legendary).** One big acacia canopy silhouette across the top, long grass blades at the bottom, low sun-orange glow behind. Gold is the tier band; keep the body ochre and umber so gold still stands out.
5. **Mystic (Legendary).** Standing stones with a floating shard orbit, deep indigo body, pale cyan light. Do NOT use violet #B04DFF (Mythic owns it) and no runes (Lunar Echo owns them).
6. **Luna Landing (Legendary).** Grey regolith ring, a small flag or antenna on one side, blue-white earthlight crescent. No moon cap (frame_m_eclipse owns the moon).
7. **Event Horizon (Mythic, violet #B04DFF).** Dark disc seen edge-on with a thin bright accretion ring, a few light streaks bending around it. The most dramatic frame of the set. Not red crystal (Crystal), not a moon (Eclipse).
8. **Cairn (Rare, green band #2DC661).** Three or four stacked smooth stones with a small green sprout, mossy grey. Quiet, readable, different from the ice frames.

Stay away from (all already in the game): walnut + laurel + shield (Founder), runes, mushrooms, fireflies, lanterns (Lunar Echo), pearl scales, lily pad, vine wreath, snowflake and frost, red crystal, moon cap, sunburst rays, Deep Reef sea things (coral, jelly, kelp, shell).

### 3. Tier ladder (match it)
- Uncommon: flat body, one motif, blue band #0094FF, 2 studs.
- Rare: satin body, mint bezel, 4 green studs, band #2DC661.
- **Legendary: metal or light seams, gold bezel, crown pillars or a strong crest at the top, band #FFB444, one slow motion layer.** Clearly richer than Epic (Deep Reef), no white-hot glow.
- **Mythic: violet #B04DFF band and glow, the most elaborate piece, within the same 3-file limit (base + 2 motion).**
Epic stays Deep Reef; do not make anything that could be mistaken for Epic teal.

### 4. Technical spec (same as rounds 2-5, the loader needs no change)
- **The ids and file names in the table above are final.** Only the display name (README) may change later, so do not rename folders or files.
- Folder `frames/<id>/` with `<short>_base.png` (static, carries the theme alone) plus up to two motion layers `<short>_<layer>.png` (for example `_glow`, `_sweep`). Short name = id without the `frame_` prefix, like `e_reef_01_base.png` (so `l_land_genesis_base.png`, `m_horizon_glow.png`). **Max 3 files per frame including the base, Mythic too.** No 4th file.
- **Motion must be one of three types the game can play:** `spin` (whole layer rotates around (128,128)), `pulse` (opacity or scale breathing, period >= 1.4 s), `sweep` (a highlight moving across). A drifting orbit or custom path is not available: draw it as a `spin` layer. Every animated layer needs a Reduce flashing value (the still state it holds).
- **Every layer uses normal blend. No additive or screen blend** in the art: the game draws all layers with normal alpha, so a glow that relies on additive disappears in game. Paint the glow with real alpha.
- **256 x 256 PNG, RGBA, transparent.** Window centre (128, 128), window diameter 162 **erased on every layer**, ornaments from r 85 outward. The game draws the frame node at avatar size x 1.5, so nothing may depend on being exactly 256 px on screen.
- **Edge margin: the outer 4 px on all four sides must have alpha exactly 0 on every layer** (alpha 1/255 already fails our test). Alpha > 24 must end >= 5.5 px inside. Rotating layers stay inside r <= 124 so it holds at any angle. The window must also be clean: alpha 0 for r <= 70 around (128,128).
  Run this before exporting and paste the output in `_shared.md`; every number must be 0 and it must print OK:
  ```python
  # python3 check_frame.py <file.png ...> [--spin <spinning_layer.png ...>]   (needs Pillow)
  # Files listed after --spin must also keep alpha>24 inside r <= 124 (safe at any rotation angle).
  import sys, math
  from PIL import Image
  spin = False
  for p in sys.argv[1:]:
      if p == "--spin":
          spin = True; continue
      im = Image.open(p).convert("RGBA"); a = im.getchannel("A"); w, h = im.size
      px = a.load(); assert (w, h) == (256, 256), "size"
      edge = [max(px[x, y] for x in range(w) for y in range(h) if k(x, y)) for k in (
          lambda x, y: y < 4, lambda x, y: y >= h - 4, lambda x, y: x < 4, lambda x, y: x >= w - 4)]
      win = max(px[x, y] for x in range(w) for y in range(h) if math.hypot(x + .5 - 128, y + .5 - 128) <= 70)
      near = any(px[x, y] > 24 and min(x + .5, w - x - .5, y + .5, h - y - .5) < 5.5 for x in range(w) for y in range(h))
      rmax = max((math.hypot(x + .5 - 128, y + .5 - 128) for x in range(w) for y in range(h) if px[x, y] > 24), default=0)
      ok = not any(edge) and win == 0 and not near and (not spin or rmax <= 124)
      print(p, "edge T/B/L/R", edge, "window", win, "alpha>24 within 5.5px", near,
            "max r (alpha>24)", round(rmax, 1), "(spin)" if spin else "", "OK" if ok else "FAIL")
  ```
  For layers that rotate (`spin`) max r must be <= 124.
- Outline: 8 px neutral-1 (the same dark outline colour as frame_e_reef_01) plus a centred 4 px halo at 40%.
- Motion no faster than 1.4 s per loop. Reduce flashing: animated layers do not move; they stay still at the value listed in their spec.
- **Budget: <= 100 KiB per layer** (existing layers max 65 KiB), 3 files max per frame. Quantise or trim PNGs if needed.
- Hand in a table per frame, one row per animated layer: layer, type (spin/pulse/sweep), period, low/high values, Reduce flashing value. We copy it straight into the manifest.
- Tier element: a band or bezel in the tier colour at least 12 px wide in the 256 master, readable at 40 px.
- **Rasterise SVG with Chrome headless** if it uses filters (blur, glow, drop shadow); hand in PNG, never an SVG. Use a transparent background and 1:1 pixels, for example:
  `chrome --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --default-background-color=00000000 --window-size=256,256 --screenshot=out.png file:///path/layer.html` (page margin 0, SVG 256 x 256). Check the result has no bright fringe on soft edges, then run the script above. Please also hand in the rasterise script you used.
- Each frame needs its own silhouette at 40 px: one big shape beats many small details.
- Spec per frame in `frames/<id>/spec.md`, same format as `frame_e_firefly/spec.md`, plus shared notes in `frames/_shared.md`-style (edge numbers).

### 5. Names
For each of the 8 frames propose a **display name, max 2 words, plain English, max 18 characters**. Table in `README.md`: id, proposed name, one-line reason. Do not reuse names already in the game (Rune Ring, Firefly Twig, Founder's Laurel, Frost Crown, Pearl Tide, Lily Pond, Vine Wreath, Snow Globe, Genesis Sunburst, Moon Eclipse, Crystal, Aurora, Icicle, Campfire, Sovereign, and the six Deep Reef names from round 5). Liam approves names later.

### 6. Show us
One sheet `design/Cosmetics Frames R6.dc.html`: the 8 frames at 40 / 64 / 96 / 160 on a letter disc and on an Axie portrait, each next to its neighbour tier (frame_u_pond, frame_r_aurora, frame_e_reef_01, frame_l_sunburst, frame_m_crystal) to prove the ladder; the three Land frames in a mock of the Land milestone list; one 10-pull grid mock with the 3 Legendary and the Mythic card. Mark everything new **R6**. Deliver only new files.

### 7. Acceptance checklist (we check each line)
- [ ] 8 frames, 8 different silhouettes at 40 px, none looks like an item in the "stay away" list.
- [ ] The 3 Land frames (Forest, Arctic, Genesis) are not reskins of Vine Wreath, Snow Globe or Sunburst.
- [ ] Tier reads right: Uncommon blue, Rare green, Legendary gold, Mythic violet; Legendary clearly above Deep Reef Epic, Mythic clearly above Legendary.
- [ ] Every layer: 256 x 256 RGBA, window 162 erased, >= 4 px transparent margin (numbers printed).
- [ ] Reads at 40 px on letter disc and portrait without zooming.
- [ ] No white-hot glow, no loop faster than 1.4 s, Reduce flashing values listed for every animated layer.
- [ ] Budget per layer <= 100 KiB, listed; max 3 files per frame; same file naming as rounds 2-5.
- [ ] Animated layers are only spin / pulse / sweep, normal blend only, anim table handed in per frame.
- [ ] `check_frame.py` output pasted: every layer edge 0/0/0/0, window 0, OK.
- [ ] README lists the 8 names, max 2 words each.
