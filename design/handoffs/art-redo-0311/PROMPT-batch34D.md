# Làm lại art: lượt 3 + 4 + D gộp một lần (skin xúc xắc, khung avatar, icon HUD + tiền tệ). Prompt cho Claude Design

**Cho Liam:**
- Dán phần dưới dòng `---` vào Claude Design (cùng project lượt 1–2 để nó nhớ style), đính kèm **một** file `send/AxieDice-art-batch34D.zip`. Bảo nó dùng skill **game-art-reskin-design** nếu có.
- Gộp từ `PROMPT-batch3.md`, `PROMPT-batch4.md`, `PROMPT-batchD.md` (Liam 5/11: gửi một lần, làm một lượt). Bỏ bước "vẽ thử 3 món rồi dừng" và bỏ chia đợt a/b. Nếu một lần trả không đủ chỗ, nó giao lần lượt Part D → Part 3 → Part 4, không chờ duyệt giữa chừng.
- Đường R như các lượt trước. Trong zip, mỗi phần một thư mục `part3/`, `part4/`, `partD/` (mỗi cái có `refs/ current/ set/ context/`).
- Liam đồng ý hết phần "Cho Liam" của 3 brief (5/11):
  - skin xúc xắc: `normal.png` sinh lại bằng script từ albedo mới (không bắt vẽ height); `plate.png` giữ cũ; skin rare theo class bỏ vảy / lông / vuốt / lông vũ / sứa, đổi sang hoạ tiết vật thể;
  - khung: 6 khung class đổi sang vật thể; giữ layer động cũ;
  - gói D: xoá 8 tên `icons/hl` không dùng (`gem gift skip mooncard undo lock drawback eternal`); `reroll` dùng `ui_reroll`; `cur_stone` lấy `stone_block`; `cur_gem` tím (`gem_pink` + tông `s7c`), `cur_shard` xanh ngọc khác `diamond`; `lethal` là mũi tên đá đỏ chỉ xuống.
- Chưa rõ (không chặn việc vẽ): số lần lặp texture trên mỗi mặt xúc xắc; khung nào có `glow` cộng sáng; layer `core` / `glint` cũ của `m_crystal` có tông tím không (base mới đỏ ruby).
- Việc bên code khi nhận hàng (gộp từ 3 brief):
  - skin: hạ 1024 → 512 chép đè `albedo.png` (+ `emission.png`, `metallic.png`); sinh `normal.png` từ albedo bằng script; tăng `DiceThumb.VERSION`; xem thumbnail Profile / Echo Box; `t_assets`;
  - khung: hạ 1024 → 256 chép đè `frame_<id>_base.png`; xem ở 40 / 96 / 240 px quanh `AvatarFrame.letter_preview`; kiểm `window_diameter_px` 162; kiểm layer `m_crystal`;
  - icon: `HudKit.icon("reroll")` → `ui_reroll`; xoá 8 tên hl + `.import`; chép `cur_*` (giữ hậu tố `_24/_32/_64`); cắt `cur_stone_*` từ `stone_block`; soát `UI3.currency_icon`, `TutorialCoach._STARTER_ICONS`, `UI6Assets.needs_disc`.

---

## What this is

The last big batch of replacing every AI-looking piece of art in Axie Dice, in **one pass**. Same rule as before: if the Sky Mavis / Axie Homeland library has the thing, the game uses it as is; if not, you redraw it **traced from specific library pieces** (same materials, palette, painting style).

Batches 1 and 2 (Core cards, pacts, houses, glyphs) are done, in the game and approved by the owner. Your new pieces must sit with them (each part's `set/` folder). The versions in each part's `current/` were made by AI and rejected: use them only for meaning, size and position. Start fresh.

Three parts:
- **Part 3: 3D dice skins.** 26 skins: 26 albedo + 14 emission + 2 metallic maps = 42 files. Seamless body textures for the 3D die.
- **Part 4: avatar frames.** 27 frame bases (the animated layers are kept).
- **Part D: small icons.** 6 HUD icons + 5 currency icons = 11 pieces.

**Folders in the zip:** `part3/`, `part4/`, `partD/`, each with `refs/`, `current/`, `set/`, `context/`. Inside a part, a path like `refs/s2a` means that part's folder (for Part 3: `part3/refs/s2a.png`).

## One pass, no stop
The owner approved the direction for all three parts. **Do not stop for a style test.** Draw everything. If one reply cannot hold it all, deliver in this order and keep going without waiting: **Part D, then Part 3, then Part 4.** Before the first part, check your style on the hardest piece of each part (`lethal`, `die_l_gold`, `frame_m_crystal`) against its refs and fix it before drawing the rest of that part.

## The library style (all three parts)
- **Painting:** soft gouache cel shading in 2-3 tones, one warm white highlight; a thin dark outline in the darkest shade of the piece's own colour, never black; rounded, chunky, toy-like proportions.
- **Light:** from the top-left on every piece. Shadow is one crescent on the dark side, saturated, in the same colour family as the lit area: never grey, never purple. No airbrushed gradients, no glow halos, no photo texture.
- **Highlights:** small and tight, only on glossy things. Sparkle stars only on gems, glass or rings.
- **Palette** (same as batch 1): amber `#f0a047` `#e7af60` `#cc8232`; earth orange `#dd6e34` `#c26554` `#a1683a`; cream `#f3eedb` `#e5deae` `#eae5c1`; deep brown, small areas only, `#4b3930` `#715d5b` (large dark areas `#5a463a` or lighter); teal `#2f605f` `#29ab92` `#44d3a6`; red `#c44140` `#ca5e63`; sage `#7eb280` `#93dd92` `#bbd0a8`; green `#77b229` `#589d34` `#2a7b43` `#1f5c48`; stone `#b4ac9f` `#68635c`. Colours outside it must be taken from the named ref and marked "extrapolated, from <ref>" in the README.
- **Metrics** (measure on a copy, tight-cropped, longest side scaled to 256; for tileable textures measure the whole 1024 scaled to 256):

| metric | target |
|---|---|
| near-black pixels (V < 0.2) | <= 1 % |
| min V | >= 0.20 |
| coverage | 0.37-0.83 (not for textures) |
| grain | 1.1-2.8 |
| colours (16-level bins) | 16-160 |

  Near-black and min V must pass. The rest are warnings: a miss needs a one-line reason. If you cannot run code, write "not measured".
- **Hard rules:** no text; no faces or eyes; no creature, creature part or silhouette (no scale, claw, fur, feather, jellyfish, shell animal as a drawn subject); no drop shadow outside the piece; no glow halo; no black outlines. Library pieces that contain a creature (`a14a`, `a16a`, `a7a`, `a10a`, `f17b`, `f17c`, `m13`, `m14`, `spiky_ball_*`, `s12*`, `f20*`) are NOT in the zip. Do not draw them from memory.


# Part D: HUD and currency icons (folder `partD/`)

Batch D of replacing every AI-looking piece of art in Axie Dice: small **HUD icons** and **currency icons**. Same rule as before: library objects are used as is; the rest you redraw **traced from specific library pieces**.

This set must sit with the approved pieces (see `set/`: the Core card family icons, the pacts, the houses, the glyphs). The current ones in `current/` have a thick black sticker outline and were rejected. Start fresh.

The two hardest: `lethal` (danger, red, unmistakable at 28 px, no skull or face) and `cur_fragment` (must work when multiplied by moss green, amber and crystal blue).

### Technical spec
- Master **128 x 128**, RGBA, sRGB, transparent, tight but not cut off (small margin of 4-6 px). Redraw or sharpen each smaller size by hand after downscaling; do not just shrink.
- Sizes to deliver per piece:
  - HUD icons: `<name>_128.png`, `<name>_64.png`, `<name>_32.png`;
  - `cur_fragment`, `cur_ticket`, `cur_gem`, `cur_shard`: `<name>_128.png`, `_64`, `_32`, `_24`;
  - `cur_stone_reveal`: one file `cur_stone_reveal_256.png` (256 x 256), plus `_64`.
- Shown as small as 20 px: the outer silhouette must carry the meaning. No thin lines, no inner dark line that carries the meaning. Rounded ends.
- Ignore the grey ground shadow in `set/shard_*`, `family_rule`, `family_mana`: draw no shadow.
- Metrics: near-black and min V must pass; the other three are warnings (coverage and grain measured on the 128 master).


### The 11 pieces
Refs are in `refs/` (library file names).

#### A. HUD icons (6)
| file | where / meaning | what (proposed) | trace from | avoid |
|---|---|---|---|---|
| aid | the Aid panel and Aid offers ("help bought with gems") | a small wicker basket with a cream cloth tucked around the rim, and one small green leaf sprout rising out of the basket | weave of `a17a`, cloth tone of `s21a` (cloth tone only, ignore the horn and pole) | a heart (that is `family_stat`); a cross; a cooking pot |
| attrition | the "enemies grow stronger as turns pass" card, 28 px | a tall stone pillar, top half crumbling, two chunks fallen at its foot, small pebbles | `f9a` (ruin pillar; stone only, leave out any vines), palette stone `#b4ac9f` `#68635c` | an hourglass (that is `family_run_rule`); a block shape (that is cur_stone / pact_ironvow) |
| boss-clock | the boss timer band and the "Delay boss clock" Aid offer | a round stone disc timer with a cream ring, 4 chunky cream notch dots at 12/3/6/9, one thick wooden hand, no numbers; the silhouette must differ from the hourglass (`family_run_rule`) | ring of `gem_ring` (shape only), wood of `wood_plank`, stone of `stone_block` | numbers, text, a cartoon clock face with eyes |
| lethal | "Can knock out an Axie" strip, 28 px, danger = the only red in the HUD | a chunky red stone arrowhead pointing down, cream binding, one cream highlight | `ore_red_raw` (colour), `gem_red` (cut face) | skull, bones, faces, teeth; black background; a plain red gem (that is a die-face debuff) |
| pact | the "Swap pact" Aid offer | a flat folded contract sheet (flat rectangle, one torn corner), cream, with a red cord looped through a punched hole and tied in a bow | cream paper of the palette, cord tone of `s21a` / `s21b` (cloth tone only, ignore the horn and pole) | rolled scroll (that is `family_quest`), wax seal (`pact_bloodpact`), text |
| spike | the "BIG HIT IN n" notice on an enemy card | a heavy round stone-headed mallet, short wooden handle, tilted 45 degrees, head is a rounded cylinder (not a wedge) | `s2c` (handle and cord wrap only), `stone_block`, `wood_plank` | an axe (that is house Big Hand); axe wedge head (`house_big_hand`); a four-point star |

#### B. Currency icons (5)
| file | where / meaning | what (proposed) | trace from | avoid |
|---|---|---|---|---|
| cur_fragment | tier pips (1-3 per Core card tier chip, multiplied by tier colour) and Echo Box fragments | a small pale crystal chip, near-white cream, remove all orange, one flat top-left highlight; a single light tone family so it tints cleanly (the game tints it by tier) | `egg` (cream tone), `s17c` (facet cut shape only; it is orange on blue-violet rock, take the cut only) | strong colour; dark shade tones (they stay dark when tinted) |
| cur_gem | premium currency (gem violet, paid surfaces) | a cut violet gem, same cut and gloss language as `gem_pink` | `gem_pink` (cut, gloss), violet tone of `s7c` (the purple jar: tone only) | blue-white diamond (that is `diamond`, crystal shard); pink; a ring |
| cur_shard | Gene Shard, the soft currency; seen everywhere | a cluster of three teal crystal shards pointing up; the silhouette must be a cluster of 3 tips, never a single prism | `s17a` (teal crystals), `ore_blue_raw` (crystal cut) | `diamond`; a hexagon badge; text |
| cur_ticket | Echo Box ticket | a cream ticket with a notched end and a round hole in the middle, amber edge | `makerdao3` (amber), `s21c` (cloth tone only, ignore the horn and pole), palette cream and amber | a star as the picture; text; a face |
| cur_stone_reveal | Echo Box ceremony: a stone being revealed | a pile of three stone blocks, one top block cracked to show a pale blue crystal | `stone_block`, `ore_blue_raw` (crystal colour, so it does not clash with the amber tier) | a skull; the old Y-shaped crack drawing; orange crystals (amber tier) |

`cur_stone` (+ `_16/_24/_32/_64`) is **not** drawn: the game takes `stone_block` straight from the library.


### Context
- `context/` holds game screenshots: the combat HUD, the Land HUD (currency header), the pact screen.
- `current/` holds the rejected current icons, **for meaning and size only**.
- `set/` holds approved pieces to sit with.


### Self-check (Part D)
Report each line as pass, fail or not measured:
- no creature, face, skull, eyes or text;
- no black outlines;
- one light direction;
- sparkle stars only on gems, glass or rings (list them);
- 5 metrics per piece (count passing all 5, a reason for each miss);
- a strip of every piece at 28 px, 24 px and 20 px: as drawn, and multiplied by cream `#f3eedb`;
- `cur_fragment` under the moss green, amber and crystal blue tints used in `set/slot_*` and `set/frame_core_*`;
- the 5 currency icons in one row at 24 px beside `cur_stone` (`stone_block`): can each be told apart? Also beside the 3 shard tiers in `set/` (`shard_*`): is `cur_shard` clearly different from the crystal tier?
- the usual AI faults: warped shapes, mixed light, melted forms, pieces of a family at different scale or style;
- every file delivered (list any missing).


# Part 3: 3D dice skins (folder `part3/`)

The game wraps a texture on all six sides of a cube (triplanar, no tint), so each skin must read as a **material**: wood looks like wood, gold like gold. Common, uncommon and rare skins have no emission. Epic, mythic and legendary skins also need an emission map; two need a metallic map. The game builds the normal maps itself: do not draw height or normal maps. The face plate (`plate.png`) is kept: do not draw it.

### Technical spec (all skins)
- Canvas **1024 x 1024**, RGBA, sRGB, opaque (alpha 255 everywhere), **seamless in both axes**. We scale it to 512.
- **Every repeating pattern** (lattice, weave, scallop, wave arcs) must have a period that divides 1024 exactly (1024 / 2 / 4 / 8), so the 512 downscale stays seamless. Emission and metallic maps use the same grid.
- The motif must stay readable when the die is small (the 2D tile of the same skin is 56-88 px). Make motifs large and few. Avoid fine grain, thin lines and noise that vanish on downscale.
- Keep the texture calm around the middle of each tile: the game puts the face plate and value on top, so no dominant feature should sit in one fixed spot (it repeats anyway).
- Mean value (brightness) should stay mid-to-light (target mean V 0.45-0.8). The game lights it, and a dark texture goes black. Dark-ground skins (`die_e_reef_02`, `die_e_reef_04`, `die_e_reef_05`, `die_e_rune`, `die_e_spore`, `die_m_moon`, `die_m_redcrystal`, `die_l_kingdom`) may have mean V 0.30-0.55; min V >= 0.20 still applies.
- **Emission map** (`<id>_emission_1024.png`, only for the 14 skins listed as having one): same 1024 layout as the albedo, pixel-aligned. Black background, the glowing parts in their own colour. Only small bits glow (dots, seams, runes, veins), as in the old ones in `current/`. No halo in the file: the game adds the glow.
- **Metallic map** (`<id>_metallic_1024.png`, only `die_e_s1_founder` and `die_l_kingdom`): greyscale, white = metal, black = not. Aligned with the albedo.



### The 26 skins
Refs are in `refs/` (library pieces, file name = library name). `current/<id>_albedo.png` shows the rejected version: use it for **meaning and tint of the tier only**. "E" = also needs an emission map, "M" = also a metallic map.

#### Common, uncommon, rare (12)
| file (`<id>_albedo_1024.png`) | what | trace from | avoid |
|---|---|---|---|
| die_c_clay | Honey Clay: warm terracotta clay, hand-smoothed, a few shallow thumb dents, soft crackle lines | colour and band wear of `s16a` (terracotta), `ingot_copper` | glossy shine; flat orange |
| die_c_reed | Reed Basket: woven reed in a chunky over-under weave, rope-tan | weave of `s14a`, `a17a` | tiny weave (must read at 1/4 size); cloth |
| die_c_sunwood | Sunwood Block: pale sun-bleached wood, long soft grain, 2-3 knots | `wood_plank`, `a18b` (cut face and grain) | dark wood (that is bark); plank seams |
| die_u_bark | Tree Rings: bark-brown end grain, big concentric rings, a couple of cracks | `f11a` (stump top), `a1_base` | many tiny rings |
| die_u_berry | Berry Jam: glossy deep berry red-purple with a few cream seed dots and a soft wet highlight | `strawberry` (gloss, seed dots), `f5a` (grape tone) | black; photo gloss |
| die_u_moss | Mossy Stone: grey stone with patches of moss in green | `f12a` (moss), `f14a` (moss on stone), `stone_block` | a stone block shape; flat green |
| die_r_aqua | Pearl Tide: overlapping wave arcs in aqua and pearl (a seamless tile, like a wave pattern on a vase) | pattern and teal of `s11a`, `s11b`, ice tone of `a14c` | fish or mermaid scales as animal skin |
| die_r_beast | Stitched Leather: tan leather hide with a stitched seam grid and rivet dots | leather and strap of `s19a`, rope of `s15a` | claw marks, fur, paw |
| die_r_bird | Rosy Plume: soft pink scalloped petal tiles in two pinks | `gem_pink`, `f19b` | feathers, wings |
| die_r_bug | Ladybug Shell, as a material: glossy red lacquer with a pattern of round dark-red dots | `tomato` (gloss), `gem_red` | any insect, antennae, legs |
| die_r_plant | Jade Sprout: jade green with a pattern of overlapping leaves | `f13a`, `f6a`, `cabbage` (leaf shape); `s13a`, `f13c` (tone / facets only) | a single big leaf as an object |
| die_r_reptile | Scale Lord, as a material: mossy green stone with rounded diamond studs in rows | `s13a` (green facets), `ore_green_raw` | animal scales, eyes |

#### Epic, mythic, legendary (14)
| file | what | trace from | avoid |
|---|---|---|---|
| die_e_reef_01 E | Coral Bloom: coral-red ground with pale pink branching coral twigs; emission = the bead tips of the twigs | `ore_pink_raw`, `f13c`, `peach` | a literal reef scene |
| die_e_reef_02 E | Sea Glass: dark teal glass with round green floats laid in a diamond grid, no rope lines; emission = faint rim of each float | `s17a`, `milk_bottle` (glass), `a14b` | a fishing net as a detailed object; rope lines |
| die_e_reef_03 E | Kelp Braid: olive-green braided kelp ropes in vertical stripes; emission = small beads between braids | `f10a`, `f15a` | thin strands |
| die_e_reef_04 E | Jelly Lamp: deep plum ground with soft round glowing lamp orbs; emission = the orbs | `s7c` (plum jar, pearls), `gem_pink` | any jellyfish, tentacle or bell shape |
| die_e_reef_05 E | Vent Rock: near-black volcanic rock with orange vent cracks; emission = the cracks | `coal_pile`, `ore_red_raw`, `ore_orange_raw`, `charcoal_log` | black below V 0.20 (lift the rock to dark brown-grey) |
| die_e_reef_06 E | Spiral Shell, as a pattern: sand ground with carved cream spirals; emission = faint spiral centres | `f17a` (spiral cap pattern), `egg`, `s7a` | a shell outline or any animal |
| die_e_rune E | Rune Slate: dark slate with carved teal runes, 3-4 abstract spiral/zigzag shapes, never letter-like; emission = the runes | `f14c`, `f9a` (carved stone) | readable letters; text |
| die_e_s1_founder E M | Founder's Seal: warm gold diamond lattice on deep wood; emission = lattice nodes; metallic = the gold | `makerdao3`, `ingot_gold` | text, crest letters |
| die_e_spore E | Glowcap Grove: night-blue ground with tiny round-capped glowing mushrooms, caps at least 120 px wide at 1024, max 6 per tile; emission = the caps | `f17a` (cap shape only), `gem_green`, `f12a` | faces on mushrooms |
| die_m_moon E | Midnight Moon: deep blue night with soft crescent moons and star dots; emission = moons and stars | `a20a`, `a20b` (blue tone only, do not draw the plant), `makerdao2` (curve, shape only) | a face in the moon |
| die_m_redcrystal E | Heart of Luna: dark ruby ground with big cut ruby facets; emission = the facets | `gem_red`, `ore_red_raw`, `s17b` | pure black; photo shine |
| die_l_gold E | Genesis Sun: polished gold; sunburst as a repeating pattern: a grid of 2x2 small sun cells (period 512 px), rays do not cross the tile border; metal drawn in 3-4 flat gouache tones (no gradient); emission = sunburst ray tips; metallic is constant 1.0 in the game, no file | `ingot_gold`, `ore_gold`, `makerdao3` | gradients; yellow plastic |
| die_l_kingdom E M | Lunacia Crown: blue and red diamond lattice with gold lines; emission = gold lines; metallic = gold | `s19b`, `s18c` (rope-and-peg colours only, ignore the drum-top glyph), `a20c` | text; heraldic animals |
| die_l_relic_stone E | Gold Seam Relic: pale carved stone with veins of gold; emission = the veins | `f14c`, `stone_block`, `ore_gold` | glowing halo in the file |

Rows with "E" need `<id>_emission_1024.png`. Rows with "M" need `<id>_metallic_1024.png`.


### Context
- `context/` holds game screenshots: the Echo Box (skins revealed), a combat with epic and mythic dice, the Profile cosmetics tab. Look at how small the die is.
- `current/` holds the rejected albedo of each skin (and the old emission of the 14 emissive ones), **for meaning and tint only**.
- `set/` holds approved batch 1 and 2 pieces your textures must sit with in tone and line.


### Self-check (Part 3)
Report each line as pass, fail or not measured:
- no creature, face, eyes or text;
- no black outlines; the outline of any drawn motif is its own darkest colour;
- one light direction (for motifs with a highlight);
- sparkle stars only on gems, glass or rings (list them);
- 5 metrics per skin (count passing all 5, reason for each miss);
- seamless: show the 2x2 tiling of every skin and say where any seam is visible;
- readability at 56 px: a strip of all skins of the whole part scaled to 56 px;
- emission and metallic maps are pixel-aligned with their albedo (show an overlay for 3 of them);
- tier ladder: c, u, r, e, m, l skins in one row. Does rarity read from material, not only from colour?
- the usual AI faults: warped shapes, mixed light, melted forms, a family at different scale or style;
- every file delivered (list any missing).


# Part 4: avatar frames (folder `part4/`)

**27 frames** = 27 `base` images. The animated layers (glow, drift, ...) are **kept** from the old set and are not part of this batch. They are in `current/` so you can see where they sit. The current bases have a thick black sticker outline and were rejected.

### Technical spec (all frames)
- Canvas **1024 x 1024**, RGBA, sRGB, transparent outside the ring. We scale to 256 (a 4x reduction).
- **Window:** centre (512,512), a perfectly round **transparent hole of diameter 648** (= 162 at 256). The avatar shows through it. Nothing inside radius 324 except fully transparent pixels. The frame's inner edge must sit at radius 324-340.
- **Reach:** the ring and its ornaments live between radius 324 and about 480. Anything beyond 480 may be cut at small sizes. Ornaments up to radius 500 are allowed, but only small bumps (< 40 px wide); anything essential stays inside 480. Keep the 4-way balance: the frame sits centred on the avatar.
- **Small sizes:** the frame is shown as small as 60 px wide (40 px avatar). The ring band must be at least 56 px wide at 1024 (14 px at 256) and the main motif must read from its silhouette. No thin lines, no tiny beads in rows.
- Outline: the darkest shade of the piece's own colour, never black, about 10-14 px at 1024 (3 px at 256).
- **Layers (epic, mythic, legendary frames):** `current/` has the old layers per frame, each 256 px on the same canvas and centre. Keep your new base so that each old layer still sits on the matching feature: glow on the glowing parts, drift / spin layers on the same radius, stars and glints near the same places. If a layer cannot line up, say which in the README.
- Mean value (brightness) mid-to-light so the frame is not a dark ring on a dark panel (`#3a2c24`). Min V >= 0.20.


### The 27 frames (file `frame_<id>_base_1024.png`)
Refs are in `refs/` (library file names). Class frames (`c_*`) tell the class by **colour and an object**, never by an animal part.

#### Common, uncommon, rare (14): no animated layers
| id | what | trace from | avoid |
|---|---|---|---|
| c_aqua | Wave Fin, as water: aqua-teal ring with a curled wave crest at top-left and top-right | teal and pattern of `s11a`, `s11b`; glass tone of `a14c` | fins, fish |
| c_beast | warm amber ring wrapped in rope (rope colour `#e7af60` from `s15a`), with two chunky wooden pegs at the top | `s15a` (rope), `a18b` (wood) | ears, fur, tufts |
| c_bird | pink ring with a row of round pink beads and a small bead on a stalk at the top | `gem_pink`, `f19b` | feathers, wings, beak |
| c_bug | glossy red lacquer ring with round dark-red dots; two small round knobs on short stalks at top | `tomato`, `gem_red` | antennae as insect parts (knobs are plain bulbs), legs |
| c_plant | green leaf ring: overlapping leaves with one small bud at the top | `f13a`, `f6a`, `cabbage` | a face on the bud |
| c_reptile | mossy green stone ring with a row of rounded studs | `s13a`, `ore_green_raw` | spikes that look like teeth or scales |
| u_campfire | ring of small logs laid in a circle with a few small amber flames between them | `charcoal_log`, `coal_pile`, `a18a`, `gem_orange` (flame tone) | a big flame covering the window |
| u_mushroom | ring of cream swirl-capped mushrooms in red and cream, no faces | `f17a`, `s8b` | any face; yellow mushrooms with faces (`f17b`) |
| u_pond | stone-rimmed pond ring in teal water with two flat lily pads and a bud | `s9a` (stone pond), `f12a` | fish, frogs |
| u_vine | green vine wreath with a few grapes in purple | `f15a`, `f5a` | thorns that look like teeth |
| r_aurora | cold arch ring with a green-teal band across the top | `s11a`, `a14c` | glow halo (the band is solid colour) |
| r_frost | pale blue ice crown ring: chunky ice crystals pointing outward | `s17a` (crystal clusters), `a14c` (ice) | figures or snowmen |
| r_icicle | ice-blue band with short, wide icicles hanging from the lower half, clearly NOT the same shape as `r_frost` | `a14b` (pale ice), `a14c` | spikes outward (that is `r_frost`) |
| r_snowglobe | glass-ring globe frame: clear blue ring with a small wooden or gold base nub at the bottom | `milk_bottle` (glass), `a14b` (glass-like ice sphere), `wood_plank` (base) | anything inside the globe |

#### Epic, mythic, legendary (13). Layers kept: listed in brackets
| id | what | trace from | avoid |
|---|---|---|---|
| e_firefly [fireflies, flicker] | dark green twig ring with small round lantern buds; the old layers are the lights | `f15a`, `f10a`, `gem_orange` | insects |
| e_reef_01 [glow] | Coral Fan: pink and red coral fan ring | `ore_pink_raw`, `f13c`, `peach` | a literal reef scene |
| e_reef_02 [glow, drift] | Glass Floats: teal ring with two round green glass floats at the top | `s17a`, `milk_bottle`, `gem_green` | nets as detail |
| e_reef_03 [glow, drift] | Kelp Sway: braided olive kelp ring with beads | `f10a`, `f15a` | thin strands |
| e_reef_04 [glow, drift] | Jelly Bell, as a lamp: plum ring with a round lamp bulb at the top and small orbs | `s7c`, `gem_pink` | any jellyfish, bell or tentacle |
| e_reef_05 [glow, embers] | Vent Ring: dark brown-grey rock ring with orange vent cracks | `coal_pile`, `ore_red_raw`, `ore_orange_raw` | pure black |
| e_reef_06 [glow] | Anemone Bed: cream ring with soft rounded petal clusters | `f7b` (petal-cluster shape only), `egg` (colour: cream) | anemone tentacles |
| e_runering [runes, glow] | slate ring with carved teal runes (the old layers carry the runes) | `f14c`, `f9a` | readable letters |
| e_s1_founder [stars] | Founder's Laurel: gold laurel ring | `makerdao3`, `ingot_gold` | text |
| m_crystal [core, glint] | Luna Heart Crown: ruby ring with cut ruby crystals at the top, a bigger one in the middle; the core layer is the red gem centred at the top (12 o'clock), keep a flat seat of about 70 px for it | `gem_red`, `s17b`, `ore_red_raw` | pure black; photo shine |
| m_eclipse [shadow, corona] | dark plum ring with a round gold disc at the top (the eclipse); old layers are the shadow and the corona | `a20a`, `makerdao3` | a face in the disc |
| l_sovereign [glints] | gold royal ring with a small crown peak at the top | `ingot_gold`, `s19b`, `a20c`, `makerdao3` | text, animals |
| l_sunburst [rays, glow] | gold sun disc ring with wing-like blades; the rays layer rotates behind it | `ingot_gold`, `makerdao3`, `s19b` | flat yellow; gradients |


### Context
- `context/` holds game screenshots: the Profile cosmetics tab and Land HUD with frames in use, and the avatar at small sizes.
- `current/` holds the rejected bases and the old layers, **for meaning, size and layer positions only**.
- `set/` holds approved batch 1 and 2 pieces: match their outline weight and tone.


### Self-check (Part 4)
Report each line as pass, fail or not measured:
- no creature, creature part, face, eyes or text;
- no black outlines;
- one light direction;
- sparkle stars only on gems, glass or rings (list them);
- 5 metrics per frame (count passing all 5, reason for each miss; coverage target is not applied to rings);
- window: the hole is a perfect circle of 648 px at 1024, fully transparent (state the measured diameter);
- readable at 60 px: a strip of all 27 at 60 px around a grey disc, and at 240 px;
- layered frames: overlay of each old layer on your base, with notes on any mismatch;
- tier ladder: c, u, r, e, m, l in one row, does rarity read from material and richness?
- the usual AI faults: warped shapes, mixed light, melted forms, a set at different scale or style;
- every file delivered (list any missing).


# Status
Every piece is `placeholder` until the owner approves it in the game.

# Self-check for every part
Report each line of the part's self-check as pass, fail or not measured. On top of that, for the whole batch:
- one light direction and one outline weight across all three parts;
- every file delivered (list any missing, per part).

# Send back
One folder `art-batch34D/` with three subfolders:
- `art-batch34D/part3/`: every PNG, RGBA, sRGB, 1024 x 1024, named `<id>_albedo_1024.png`, `<id>_emission_1024.png`, `<id>_metallic_1024.png`.
- `art-batch34D/part4/`: every PNG, RGBA, sRGB, exactly 1024 x 1024, named `frame_<id>_base_1024.png`.
- `art-batch34D/partD/`: every PNG, RGBA, sRGB, exact sizes, names exactly as listed in Part D.
- `art-batch34D/_review/`: per part one contact sheet (each new piece beside the refs it traced) and the strips the self-checks ask for (Part 3: tier ladder, 56 px strip, emission overlays; Part 4: 60 px and 240 px strips, tier ladder, layer overlays; Part D: 28 / 24 / 20 px strips, tint test, currency row).
- One short `README.md`: for each piece, which library pieces it traced and what it took from each; list "extrapolated" colours; the self-check results per part.
