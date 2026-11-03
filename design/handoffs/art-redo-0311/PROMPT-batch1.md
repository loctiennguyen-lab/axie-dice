# Làm lại art: lượt 1, thẻ Lõi (23 món). Prompt cho Claude Design

**Cho Liam:**
- Dán phần dưới dòng `---` vào Claude Design và đính kèm `send/AxieDice-art-batch1.zip`.
- Nếu Claude Design có skill **game-art-reskin-design**, bảo nó dùng skill đó. Brief này đã theo đúng skill: đường R, style Homeland, hàng thử style, ngưỡng đo, tự kiểm.

Cổng quyền sở hữu:
- Axie Dice là game của Liam, làm trong Sky Mavis.
- Kho asset là kho Homeland của Sky Mavis.
- Đi **đường R**: các món đang dùng (bản UI-06 do AI vẽ) chỉ để hiểu slot là gì (loại, cỡ, vị trí), không chép hình hay màu.

Theo các quyết định của Liam ngày 3/11:
- mọi art AI đều phải làm lại;
- món nào kho Sky Mavis không có thì vẽ lại BÁM KHO;
- Liam duyệt từng món.

Bảng tồn kho đầy đủ ở `production/art-redo-0311-inventory.md`.

---

## What this is

We are replacing every AI-looking piece of art in Axie Dice. The owner's rule: art must come from the official Sky Mavis / Axie Homeland asset library. If the library has the thing, we use it as is. If it does not, you redraw it **traced from specific library pieces**: same shapes, same materials, same palette, same painting style.

This batch is the Core card system: **23 pieces**. You drew the current versions in UI-06, and the owner rejected them because they look AI-made. **Do not reuse or restyle your UI-06 versions.** Start from the library pieces named below.

## Step 1: style test first, then STOP
Draw only these 3 pieces first:
- `frame_core_amber` (UI chrome),
- `family_stat` (icon),
- `slot_moss` (a small prop).

Show them next to their library references, with the measurements below, and **stop**. Draw the other 20 only after the owner approves the style on these 3.

## The library style (match it exactly)

Look at `library/` in the zip. Every piece there is painted the same way:
- soft cel shading in 2–3 tones;
- one warm white highlight;
- a thin dark outline in the darkest shade of the piece's own colour, never black;
- rounded, chunky, toy-like proportions;
- the light comes from the top-left;
- no gradients that look airbrushed, no photo textures, no glow halos, no noise or grain.

Your pieces must sit next to the library pieces and look like the same artist made them.

Measured style rules, taken from the owner's library (65 icons, 192 2D items):
- **Gouache, hand-painted, toy-like.** Compact shapes, flat colour areas with form, saturated warm colour. No render gloss, no smooth airbrush.
- **Shadow:**
  - one crescent on the dark side, about 12 px on a 256 canvas (5–8 px for small details), with a softly blurred edge;
  - shadows stay saturated and in the same colour family as the lit area: never grey, never purple;
  - light comes from the top-left for every piece, including rotated ones (the shadow does not rotate with the object).
- **Highlight:** small and tight, only on glossy things (metal, glass, fruit, gems). **Sparkle stars only on gems, glass and rings.** Never on wood, coins or plain metal.
- **Outline:** no black outlines.
- **Families:** draw each family's variants together (moss / amber / crystal), never one at a time.
- **Coverage:**
  - thin diagonal objects (bolt, scale arms) tend to cover too little of the canvas, so make them thicker;
  - box-like objects (die, scroll) tend to cover too much, so round the corners and add a small detail.
- **Palette (from the library):**
  - amber `#f0a047` `#e7af60` `#cc8232`
  - earth orange `#dd6e34` `#c26554` `#a1683a`
  - cream `#f3eedb` `#e5deae` `#eae5c1`
  - deep brown, small dark areas only, `#4b3930` `#715d5b`; for large dark areas use `#5a463a` or lighter
  - teal `#2f605f` `#29ab92` `#44d3a6`
  - red `#c44140` `#ca5e63`
  - sage `#7eb280` `#93dd92` `#bbd0a8`
  - green `#77b229` `#589d34` `#2a7b43` `#1f5c48`
  - stone `#b4ac9f` `#68635c`

  The palette has no ice blue, violet or pink. For the Crystal tier, extend it with the same rules (saturated, warm-leaning, shadow in the same family) and mark it "extrapolated, no sample".

**Acceptance metrics.** Measure each icon / prop after a tight crop, longest side 256 px:

| metric | icons |
|---|---|
| near-black pixels (V < 0.2) | ≤ 1 % |
| min V | ≥ 0.20 |
| solid-pixel coverage | 0.37–0.83 |
| grain (difference from a 1 px blur, inside the shape) | 1.1–2.8 |
| colour count (16-level RGB bins) | 16–160 |

How to read the metrics:
- Only about 70 % of the library itself passes all 5, so a miss needs a reason, not an automatic redraw.
- Near-black and min V should be fixed when they miss. The other three are warnings: look again by eye and decide.
- Frames and windows use these numbers only as a guide.
- If you cannot run code to measure, write "not measured". Do not claim a pass.

**Hard rules for all 23 pieces:**
- no text;
- no faces or eyes, including on the scale or the die;
- no creature or creature silhouette;
- no drop shadow outside the piece;
- no glow;
- no black outlines.

Where the library has no matching object (heart, die, scroll, hourglass, scale, bolt), draw **one simple silhouette**, painted like the library pieces. Add no extra details.

**Never draw an Axie or any creature.** A few library pieces have a creature inside them (`a14a` ice block, `a16a/b/c` glass orbs, `a7a/c` nesting dolls, `a10a` jester box, `m13` plush, `s12` masks). From those pieces take **only** the frame, material, colour and outer shape.

## Tiers
There are 3 tiers. They must read by **material + colour**, not by hue alone:
1. **Moss**: grey stone / plain wood + green moss.
2. **Amber**: warm brown wood + thin gold trim.
3. **Crystal**: blue-grey stone + pale blue crystals.

The library already shows this ladder: chests `s19a` / `s19b` / `s19c` and tables `a19a` / `a19b` / `a19c`.

## The 23 pieces
Sizes are in px. A nine-patch is given as [left, top, right, bottom] margins, and the margins do not change. Godot STRETCHES the edges and the centre; it does not tile them. So:
- every corner ornament stays inside its corner patch;
- the long straight edges stay plain;
- the centre of every frame and window is transparent;
- the middle of the top edge of the Core frames stays plain, because the crest sits half over it.

| # | file | what | trace from (library) | size |
|---|---|---|---|---|
| 1 | frame_core_moss.png | Core card frame, tier 1 | `a19a` (carved grey stone, rounded corners), `s19a` (corner straps); moss tufts in the corners as on `f14c` | 400×600, 9-patch [100,64,100,60], centre empty |
| 2 | frame_core_amber.png | tier 2 | `a19b` / `a19c` (orange wood, straps), `s19b` (thick gold trim) | 400×600, 9-patch [56,56,56,60], centre transparent |
| 3 | frame_core_crystal.png | tier 3 | `s19c` (blue-violet chest, pale straps), crystal clusters in the corners as on `s17a` | 400×600, 9-patch [100,64,100,64], centre transparent |
| 4 | frame_run_rule.png | Run Rule card frame. It must NOT look like a Core: plain carved stone, no moss, no tier | `f14c` (swirl rune stone), `f9a` (patterned stone pillar) | 520×600, 9-patch [48,48,48,52], centre transparent |
| 5–7 | crest_moss / _amber / _crystal.png | Medallion on the card's top edge, with 2 short wings. The centre is a **flat recessed disc of the same colour, about 42 px across, centred at (80, 46)**, with NO symbol in it (no leaf, no drop, no crystal): the game places the tier gem there. In game it shows at about 76 % (64 px tall) | moss: `makerdao1` (gold swirl base) + wing shape from the flower `a20a` (shape only); amber: `makerdao3`; crystal: `makerdao2` + `a20b` / `a20c` (blue crystal flower, shape only) | 160×84 |
| 8–10 | artwin_moss / _amber / _crystal.png | Picture window inside the card: an EMPTY frame, the Core picture sits inside | moss: frame of `a14a` / `a16a`; amber: base of `a16b` / `a16c`; crystal: frame of `a14c` + `s17a`. **Frame / base only: the inside is EMPTY (transparent), with no creature, plant, eyes, face or silhouette** | 352×160, centre transparent; 9-patch moss [28,28,28,44], amber [28,28,28,28], crystal [28,28,28,40] |
| 11–13 | back_art_moss / _amber / _crystal.png | Round medallion on the face-down card back, ornament growing more elaborate by tier, **no symbol in the middle** | rim and pattern of `s18a` / `s18b` / `s18c` (footed bowls), `s3b` / `s3c` (totems) | 200×200 |
| 14–17 | slot_moss / _amber / _crystal / _empty_{128,64,32}.png | Socket ring for owned Cores. The centre is a **flat dark core** (dark brown, the same as today), where the game places the Core emblem. `slot_empty`: the same ring in plain stone, no tier colour, the core a little darker (an empty socket) | ring of `gem_ring` (icons) + stone: `s5a` (moss), `s5b` + `s19b` (amber), `s5c` + `s17a` (crystal), `s5a` with no tier colour (empty) | 128, 64, 32 |
| 18 | family_stat_{128,64,32}.png | heart | painting of `strawberry` and `peach` (icons) | 128/64/32 |
| 19 | family_dice_{128,64,32}.png | 3/4-view die, cream body, dark pips | cream colour and rounded corners of `dice_ref.png` (the game's own die face, cropped from combat) + wood from `wood_plank` | 128/64/32 |
| 20 | family_quest_{128,64,32}.png | rolled scroll / banner | cloth and folds of `s21a/b/c` | 128/64/32 |
| 21 | family_run_rule_{128,64,32}.png | hourglass | body: stone `f4b`; sand: amber of `gem_orange` | 128/64/32 |
| 22 | badge_tradeoff_{128,64,32}.png | balance scale ("gain one thing, lose another"). The only red badge | colour and gloss of `gem_red` | 128/64/32 |
| 23 | badge_convert_to_dmg_{128,64,32}.png | lightning bolt | colour and gloss of `gem_orange` | 128/64/32 |

The new family emblems (18–21) must sit as one set with the 3 we already took from the library: `family_pos` (flag `s21a`), `family_mana` (flask `s16b`), `family_rule` (rune stone `f14c`). All three are in `library/` as well.

## Context
`context/` holds screenshots of the game today, showing where each piece appears: the Core offer, the owned-Cores strip, the shop, the anchor pick, the reward screen. The current pieces are in `current/` for size and position only. **Do not copy their look.**

## Status
Every piece is `placeholder` until the owner approves it. Never mark anything final or official.

## Self-check before delivery
Report each line as pass, fail or not measured:
- No Axie, creature, face or eyes. No text, no logo.
- No black outlines. Shadows are in the same colour family, never grey or purple. One light direction across the set.
- Sparkle stars only on gems, glass or rings. List every piece that has one.
- The metrics above for each icon and prop: how many pass all 5, and the reason for each miss.
- The usual AI-art faults:
  - warped glyphs;
  - a different light direction on each piece;
  - melted shapes with no clear meaning;
  - pieces in one family drawn at mismatched scale or style.

  Check every piece at real size, not only on the shrunk sheet.
- Every slot is delivered. List any that are missing.

## Send back
- `art-batch1/` with all the PNGs:
  - PNG RGBA, sRGB, exact canvas size, no extra padding;
  - file names exactly as listed, with the `_128` / `_64` / `_32` suffix where given;
  - the 64 and 32 versions redrawn or sharpened after downscaling, so the outline still reads at 32 px.
- One nine-patch test image: each frame and window stretched to 2 different sizes, so the corners can be checked.
- One contact sheet that puts each new piece next to the library pieces it was traced from, so the owner can approve each one.
- A short README: for each piece, which library pieces it traced and what it took from each (shape / material / colour / line).
