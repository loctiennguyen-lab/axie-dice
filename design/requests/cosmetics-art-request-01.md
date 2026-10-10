# Art request 01 — Cosmetics: die skins, avatar frames, dice FX (55 items)

**From:** Axie Dice dev (Liam) · **To:** Claude Design · **Date:** 2026-10-10
**Status:** ready to hand over. This file is the single normative brief for this request.

Please read `docs/design-handoff-v2/FOR-CLAUDE-DESIGN.md` first — it is the contract for how a
delivery lands in this codebase (exact numbers, specs not code, one normative document, label
OBSERVED vs INFERRED). Everything below assumes it.

---

## 1. What this is for

Axie Dice is a turn-based dice roguelike (Godot 4.7.2, Windows + macOS first). It is growing a
cosmetic layer: players earn cosmetics from **Echo Box** (gacha), the **Battle Pass** and **class
Mastery**. Cosmetics never change gameplay. This request covers the 55 items that need **new 2D
art**; land decor, pets and Axie accessories come from an existing 3D library and are out of scope.

| Category | Count | Where the player sees it |
|---|---|---|
| Die skins | 20 | The tumbling dice in the combat **reroll tray**, and the die face on each **die card** in the deck |
| Avatar frames | 21 | Around the player avatar: account chip (40 px), profile / leaderboard row (64–96 px), result screen and Land profile (up to 256 px) |
| Dice FX | 14 | Motion layer on the reroll: trail while a die tumbles, impact on each bounce, burst when a face settles |

**Style source of truth:** `docs/design-handoff-v2/mockups-v2/` (combat-v2.html for the deck and
dice) and the v2 handoff it came from. That means: chunky **pure-black outlines**, flat solid fills,
hard "shelf" shadows (offset, no blur), Baloo 2 for every numeral and label, warm Lunacia palette.
The reroll FX you designed before (`Godot Combat Reroll FX v2`) is the motion reference — it shipped
as `godot/scenes/combat/reroll_fx/` and its README lists the six beats and their timings.

---

## 2. Tier system (applies to all three categories)

Cosmetic rarity uses **six tiers, named after the six Land biomes** — the same ladder the player's
Land climbs, so a tier reads as "where this item belongs".

| # | Tier | Biome | Existing rarity colour (`DangoTheme.RARITY_COLORS`) | Visual language to lean on |
|---|---|---|---|---|
| 0 | Common | Savannah | `#C6CEDA` | sand, straw, woven reed, sun-bleached wood |
| 1 | Uncommon | Forest | `#40CC3D` | leaf, moss, bark, berries |
| 2 | Rare | Arctic | `#33B8FF` | ice, frost, snowflake facets, cold blue |
| 3 | Epic | Mystic | `#BF6BFF` | glow runes, spores, soft violet light |
| 4 | Legendary | Genesis | `#FF9445` | gold, ancient carved stone, sunburst |
| 5 | **Mythic** | LunaLanding | **none yet — please propose one hex** | red crystal, moon, starlit dark (see the LunaLanding contact sheet) |

Reference renders of each biome: `asset-library/godot-ready/contact_sheets/HomeLand_Asset_Environment_<Biome>_1.png`
(ask Liam for the images if you cannot open the path).

**Escalation rule — what each tier is allowed to add.** Higher tiers must be visibly richer, not
just recoloured:

| Tier | Material / detail | Motion |
|---|---|---|
| Common, Uncommon | one material, simple pattern | none |
| Rare | two materials or a clear motif | none |
| Epic | ornament on the silhouette (corners, rim) | optional subtle idle (shimmer, ≤ 2 s loop) |
| Legendary | ornament + light/glow layer | idle loop required |
| Mythic | everything above + a signature element no lower tier has | idle loop required, plus a special moment (e.g. on the settle of a MAX roll) |

Every animated item must have a **static fallback** frame and must respect the game's **Reduce
flashing** setting: no full-screen flashes and no strobe in the reduced variant (say what changes).

---

## 3. Die skins — 20

### 3.1 How a die face is drawn today (OBSERVED in `godot/scenes/combat/reroll_fx/reroll_die.gd`)

The die is a real cube drawn in 2D; each visible face is a square mapped with an affine transform,
lit by a 0.72–1.0 shade factor depending on how much it faces the camera. At the reference face
size **s = 104 px**:

| Layer (bottom → top) | Geometry | Drawn by |
|---|---|---|
| Face plate | full square, corner radius 0.18 s (18.7 px), black border 4 px | **skin** (today: flat `#F3E7D3`) |
| Class band | top strip, height 0.24 s (25 px), same top radii, black border | code, class colour — **not skinnable** |
| Value + type chip | one centred row, vertical centre at +0.12 s below the face centre; value in Baloo 2 at 0.40 s, ink `#1A1206`; type chip 0.30 s square with the face-type colour and glyph | code — **not skinnable** |

So a die skin is the **face plate material, its border and the cube's edge treatment**. The class
band, the number and the type chip stay exactly as they are on every skin, because they carry
mechanics (FIX rules: a mechanic swatch always keeps its glyph; ink on fill, never white on colour).

### 3.2 Requirements

- **Calm zone:** the rectangle behind the value row — x from −0.40 s to +0.40 s, y from −0.06 s to
  +0.30 s around the face centre — must stay low-contrast so the `#1A1206` number reads at a glance.
  Target ≥ 4.5:1 contrast between the number ink and the plate everywhere in that zone. If a skin
  is dark (e.g. Mythic starlit), say so and specify a **light value plate** behind the number
  instead of changing the ink.
- **Must read at three sizes:** 104 px (tray), 64 px (die card face), 36 px (small/summoned token).
- **All six faces of one skin share one plate design** (the faces differ only in code-drawn content).
- Edge treatment: today the border is pure black 4 px at 104 (3 px for the small egg die). A skin
  may change the border **colour only from Epic up**, and only if the silhouette still reads as
  outlined black at 36 px.

### 3.3 Deliverables per skin

1. Plate texture: **512 × 512 PNG**, opaque, drawn for the full face including the band area (the
   band covers the top 24 %, so detail there is mostly hidden — put the motif in the lower 76 %).
2. A spec line: border colour + width at s = 104, any second texture (e.g. glow) and its blend.
3. For Epic+: the idle animation as a short spec (layers, loop length, easing) and an HTML/CSS
   prototype if that is easier to read than prose.
4. One preview of a full die (band + value + chip drawn on top) at 104 / 64 / 36 px.

### 3.4 List

Six of the Rare skins are **class Mastery rewards** (one per Axie class); two items are **Battle
Pass Season 1** rewards and should feel "founding season". The rest go to Echo Box. Names and
themes below are suggestions — keep the ID, improve the idea.

| ID | Tier | Theme |
|---|---|---|
| `die_c_reed` | Common | woven reed basket |
| `die_c_sunwood` | Common | sun-bleached planks |
| `die_c_clay` | Common | baked clay with thumbprints |
| `die_u_moss` | Uncommon | moss-covered stone |
| `die_u_bark` | Uncommon | carved bark with rings |
| `die_u_berry` | Uncommon | berry-jam glaze |
| `die_r_plant` | Rare · Mastery | Plant class: leaves and vine |
| `die_r_beast` | Rare · Mastery | Beast class: fur tufts and claw marks |
| `die_r_aqua` | Rare · Mastery | Aquatic class: scales and bubbles |
| `die_r_reptile` | Rare · Mastery | Reptile class: scutes |
| `die_r_bug` | Rare · Mastery | Bug class: carapace segments |
| `die_r_bird` | Rare · Mastery | Bird class: feathers |
| `die_e_rune` | Epic | glowing Mystic runes |
| `die_e_spore` | Epic | bioluminescent spores |
| `die_e_s1_founder` | Epic · Pass S1 | Season 1 crest |
| `die_l_gold` | Legendary | Genesis gold with carved sunburst |
| `die_l_relic_stone` | Legendary | ancient stone with light seams |
| `die_l_kingdom` | Legendary | Lunacia royal (ties to Pass lv30 "LUNACIA SOVEREIGN") |
| `die_m_redcrystal` | Mythic | LunaLanding red crystal |
| `die_m_moon` | Mythic | starlit moon face |

---

## 4. Avatar frames — 21

### 4.1 Where they appear

The avatar today is a 40 × 40 rounded chip with the player's initial on a solid class colour
(`godot/scenes/shared/AccountUI.gd`, `build_chip`). Frames will wrap it on: the account chip
(40 px), profile and leaderboard rows (64–96 px), the result screen and Land profile (up to 256 px).

### 4.2 Requirements

- Master canvas **256 × 256**, transparent PNG. **Avatar window: a centred circle, 168 px
  diameter**, fully transparent; the frame may overlap the window edge by up to 8 px (that overlap
  hides the seam). Frame art may use the whole canvas.
- Must read at **40 px** — at that size only silhouette and colour survive, so every frame needs a
  distinct silhouette or colour block, not just fine engraving. Provide a 40 px preview.
- Black outline, flat fills, shelf shadow allowed (offset down, no blur).
- Animated tiers: separate the moving layer from the static base, give the loop as a spec.

### 4.3 Deliverables per frame

1. 256 × 256 PNG (static base), plus animated layer(s) for Epic+ as separate PNGs or a sprite
   sheet, with the motion spec.
2. Previews at 40, 96 and 256 px around a placeholder avatar.

### 4.4 List

Six Common frames are **class Mastery rewards** (one per class).

| ID | Tier | Theme |
|---|---|---|
| `frame_c_plant` | Common · Mastery | Plant: leafy ring |
| `frame_c_beast` | Common · Mastery | Beast: fur ring with ears |
| `frame_c_aqua` | Common · Mastery | Aquatic: wave ring |
| `frame_c_reptile` | Common · Mastery | Reptile: scaled ring |
| `frame_c_bug` | Common · Mastery | Bug: antennae ring |
| `frame_c_bird` | Common · Mastery | Bird: feather ring |
| `frame_u_vine` | Uncommon | vine wreath |
| `frame_u_mushroom` | Uncommon | mushroom ring |
| `frame_u_campfire` | Uncommon | campfire logs |
| `frame_u_pond` | Uncommon | lily pond |
| `frame_r_frost` | Rare | frost crown |
| `frame_r_snowglobe` | Rare | snow globe |
| `frame_r_aurora` | Rare | aurora band |
| `frame_r_icicle` | Rare | icicle fringe |
| `frame_e_runering` | Epic | rotating rune ring (idle) |
| `frame_e_firefly` | Epic | fireflies orbit (idle) |
| `frame_e_s1_founder` | Epic · Pass S1 | Season 1 laurel |
| `frame_l_sunburst` | Legendary | Genesis sunburst (idle) |
| `frame_l_sovereign` | Legendary · Pass S1 lv30 | "LUNACIA SOVEREIGN" crown frame |
| `frame_m_crystal` | Mythic | LunaLanding red crystal |
| `frame_m_eclipse` | Mythic | moon eclipse |

---

## 5. Dice FX — 14

### 5.1 What an FX is

One FX = a **set of three effects** applied to the reroll, on top of the existing sequence (do not
replace its beats or stamps):

| Effect | When (existing beats, at 1x) | Constraint |
|---|---|---|
| Trail | while a die tumbles (~0.8 s toss) | behind the die, never over its visible face |
| Impact | each time a die hits the felt | replaces or decorates the current dust puff |
| Settle burst | when a face locks (0.3 s per die) | must clear the face within 0.25 s so the value is readable |

The existing bits (`fx_bits.gd`) are coloured by face type and have black outlines; an FX may
re-skin the bits but must keep the face-type colour visible somewhere in the settle burst, because
that colour tells the player what they rolled.

### 5.2 Requirements

- Performance budget: **≤ 40 live particles per die**, 5 dice at once.
- Reduce flashing: provide the reduced variant (no screen flash, no strobe, bursts ≤ 50 % brightness).
- Higher tiers add layers per the escalation table (§2). Mythic gets a unique MAX-roll moment.

### 5.3 Deliverables per FX

1. An **HTML prototype** of trail + impact + settle on one die (like the Reroll FX v2 file).
2. Written spec: layers, particle shapes (PNG sprites if any, black outline), counts, colours,
   durations, easing.
3. Sprites: PNG with transparency, ≤ 128 × 128 each.

### 5.4 List

| ID | Tier | Theme |
|---|---|---|
| `fx_c_dust` | Common | sand puff |
| `fx_c_leaf` | Common | falling leaves |
| `fx_c_pebble` | Common | pebble skip |
| `fx_u_petal` | Uncommon | petal swirl |
| `fx_u_splash` | Uncommon | water splash |
| `fx_u_ember` | Uncommon | campfire embers |
| `fx_r_frost` | Rare | frost trail, snow impact |
| `fx_r_bubble` | Rare | bubble trail |
| `fx_r_spark` | Rare | electric sparks |
| `fx_e_rune` | Epic | rune circle on settle |
| `fx_e_spore` | Epic | glowing spores |
| `fx_l_sunfire` | Legendary | golden comet trail |
| `fx_l_starfall` | Legendary | shooting stars |
| `fx_m_lunar` | Mythic | red-crystal shards + moon halo on MAX |

---

## 6. Counts check

| Category | C | U | R | E | L | M | Total |
|---|---|---|---|---|---|---|---|
| Die skins | 3 | 3 | 6 | 3 | 3 | 2 | **20** |
| Avatar frames | 6 | 4 | 4 | 3 | 2 | 2 | **21** |
| Dice FX | 3 | 3 | 3 | 2 | 2 | 1 | **14** |
| **Total** | 12 | 10 | 13 | 8 | 7 | 5 | **55** |

(The per-tier split differs slightly from the design proposal's table so the six class-Mastery
die skins and six class frames fit; the totals per category are unchanged.)

---

## 7. Package and naming

```
cosmetics-01/
  README.md                 one normative spec for everything below
  die/<id>/plate.png        512x512 + glow.png etc. if any, preview_104_64_36.png
  frame/<id>/base.png       256x256 + anim/ (layers or sheet), preview_40_96_256.png
  fx/<id>/prototype.html    + sprites/*.png
  contact-sheet.png         every item, grouped by category then tier
  mythic-colour.md          the proposed Mythic hex and why
```

IDs exactly as in the lists (lower case, underscores). If you rename a theme, keep the ID.

## 8. Acceptance (how we will check the delivery)

- 55 items present with the IDs above; counts per tier match §6.
- Every die preview shows the code-drawn band, value and chip untouched and readable at 36 px.
- Every frame reads at 40 px (silhouette or colour distinct from its tier neighbours).
- Every animated item has a static fallback and a Reduce-flashing variant.
- FX prototypes keep the face value readable within 0.25 s of the settle.
- A proposed Mythic colour, checked against the five existing rarity colours.

## 9. Open points you may decide or push back on

1. Whether die-card faces in the deck should show the skin, or only the tray dice (we lean: both).
2. Whether frames should be circles or follow the current rounded-square chip (we lean: circle
   window, frame shape free).
3. Any item where the theme does not work — propose a replacement with the same ID and tier.
