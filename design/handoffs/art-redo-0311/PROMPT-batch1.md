# Làm lại art: lượt 1, thẻ Lõi (23 món). Prompt cho Claude Design

**Cho Liam:** dán phần dưới dòng `---` vào Claude Design, đính kèm `send/AxieDice-art-batch1.zip`.

Theo các quyết định của Liam ngày 3/11:
- mọi art AI đều phải làm lại;
- món nào kho Sky Mavis không có thì vẽ lại BÁM KHO;
- Liam duyệt từng món.

Bảng tồn kho đầy đủ ở `production/art-redo-0311-inventory.md`.

---

## What this is

We are replacing every AI-looking piece of art in Axie Dice. The owner's rule: art must come from the official Sky Mavis / Axie Homeland asset library. If the library has the thing, we use it as is. If it does not, you redraw it **traced from specific library pieces**: same shapes, same materials, same palette, same painting style.

This batch is the Core card system: **23 pieces**. You drew the current versions in UI-06, and the owner rejected them because they look AI-made. **Do not reuse or restyle your UI-06 versions.** Start from the library pieces named below.

## The library style (match it exactly)

Look at `library/` in the zip. Every piece there is painted the same way:
- soft cel shading in 2–3 tones;
- one warm white highlight;
- a thin dark outline in the darkest shade of the piece's own colour, never black;
- rounded, chunky, toy-like proportions;
- the light comes from the top-left;
- no gradients that look airbrushed, no photo textures, no glow halos, no noise or grain.

Your pieces must sit next to the library pieces and look like the same artist made them.

**Never draw an Axie or any creature.** A few library pieces have a creature inside them (`a14a` ice block, `a16a/b/c` glass orbs, `a7a/c` nesting dolls, `a10a` jester box, `m13` plush, `s12` masks). From those pieces take **only** the frame, material, colour and outer shape.

## Tiers
There are 3 tiers. They must read by **material + colour**, not by hue alone:
1. **Moss**: grey stone / plain wood + green moss.
2. **Amber**: warm brown wood + thin gold trim.
3. **Crystal**: blue-grey stone + pale blue crystals.

The library already shows this ladder: chests `s19a` / `s19b` / `s19c` and tables `a19a` / `a19b` / `a19c`.

## The 23 pieces
Sizes are in px. A nine-patch is given as [left, top, right, bottom] margins. Keep every corner ornament inside the corner patches, and keep the straight edges plain so they can stretch. Deliver transparent PNG.

| # | file | what | trace from (library) | size |
|---|---|---|---|---|
| 1 | frame_core_moss.png | Core card frame, tier 1 | `a19a` (carved grey stone, rounded corners), `s19a` (corner straps); moss tufts in the corners as on `f14c` | 400×600, 9-patch [100,64,100,60], centre empty |
| 2 | frame_core_amber.png | tier 2 | `a19b` / `a19c` (orange wood, straps), `s19b` (thick gold trim) | 400×600, 9-patch [56,56,56,60] |
| 3 | frame_core_crystal.png | tier 3 | `s19c` (blue-violet chest, pale straps), crystal clusters in the corners as on `s17a` | 400×600, 9-patch [100,64,100,64] |
| 4 | frame_run_rule.png | Run Rule card frame. It must NOT look like a Core: plain carved stone, no moss, no tier | `f14c` (swirl rune stone), `f9a` (patterned stone pillar) | 520×600, 9-patch [48,48,48,52] |
| 5–7 | crest_moss / _amber / _crystal.png | Medallion on the card's top edge, with 2 short wings. **Leave the centre disc EMPTY**: the game places the tier gem there | moss: `makerdao1` (gold swirl base); amber: `makerdao3`; crystal: `makerdao2`, crystal bits as on `s17a` | 160×84 |
| 8–10 | artwin_moss / _amber / _crystal.png | Picture window inside the card: an EMPTY frame, the Core picture sits inside | moss: frame of `a14a` / `a16a` (frame only); amber: base of `a16b` / `a16c` (base only); crystal: frame of `a14c` + `s17a` | 352×160; 9-patch moss [28,28,28,44], amber [28,28,28,28], crystal [28,28,28,40] |
| 11–13 | back_art_moss / _amber / _crystal.png | Round medallion on the face-down card back, ornament growing more elaborate by tier, **no symbol in the middle** | rim and pattern of `s18a` / `s18b` / `s18c` (footed bowls), `s3b` / `s3c` (totems) | 200×200 |
| 14–17 | slot_moss / _amber / _crystal / _empty.png | Socket ring for owned Cores; the centre is EMPTY | ring of `gem_ring` (icons) + stone: `s5a` (moss), `s5b` + `s19b` (amber), `s5c` + `s17a` (crystal), `s5a` with no tier colour (empty) | 128 (also give 64 and 32) |
| 18 | family_stat.png | heart | painting of `strawberry` and `peach` (icons) | 128/64/32 |
| 19 | family_dice.png | 3/4-view die, cream body, dark pips | cream colour and rounded corners of `dice_ref.png` (the game's own die face, cropped from combat) + wood from `wood_plank` | 128/64/32 |
| 20 | family_quest.png | rolled scroll / banner | cloth and folds of `s21a/b/c` | 128/64/32 |
| 21 | family_run_rule.png | hourglass | body: stone `f4b`; sand: amber of `gem_orange` | 128/64/32 |
| 22 | badge_tradeoff.png | balance scale ("gain one thing, lose another"). The only red badge | colour and gloss of `gem_red` | 128/64/32 |
| 23 | badge_convert_to_dmg.png | lightning bolt | colour and gloss of `gem_orange` | 128/64/32 |

The new family emblems (18–21) must sit as one set with the 3 we already took from the library: `family_pos` (flag `s21a`), `family_mana` (flask `s16b`), `family_rule` (rune stone `f14c`). All three are in `library/` as well.

## Context
`context/` holds screenshots of the game today, showing where each piece appears: the Core offer, the owned-Cores strip, the shop, the anchor pick, the reward screen. The current pieces are in `current/` for size and position only. **Do not copy their look.**

## Send back
- `art-batch1/` with all 23 PNGs at the sizes above, file names exactly as listed. Nine-patch margins are unchanged.
- One contact sheet that puts each new piece next to the library pieces it was traced from, so the owner can approve each one.
- A short README: for each piece, which library pieces it traced and what it took from each (shape / material / colour / line).
