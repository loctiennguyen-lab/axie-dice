# Làm lại art: lượt 2, pact + Gambler + glyph UI (12 món). Prompt cho Claude Design

**Cho Liam:**
- Dán phần dưới dòng `---` vào Claude Design và đính kèm `send/AxieDice-art-batch2.zip`. Bảo nó dùng skill **game-art-reskin-design** nếu có.
- Cổng quyền sở hữu như lượt 1: game của Liam làm trong Sky Mavis, kho Homeland của Sky Mavis, đi **đường R**. Các món đang dùng chỉ để hiểu slot, không chép.
- Liam duyệt 4/11: glyph vẽ khối 2 tông (kem + nâu gỗ); ô Hold / Undo trong combat thì game ép về một màu kem; Devil's Reroll dùng luôn `ore_red_raw`.
- Hình từng món do art-director chốt (4/11). Đã mở từng ảnh kho để soát. `f20b` bị loại vì là tượng con chim.
- Không gửi Claude Design (game tự lấy từ kho, theo quyết định 3/11):
  - 5 huy hiệu nhà: Volley `s2a`, Mana Mine `ore_blue_raw`, Embers `coal_pile`, Big Hand `s2c`, Kin `a7a`;
  - 4 pact: Twin Fates `gem_pink` + `gem_red`, Iron Vow `ingot_iron`, Tithe of Pips `ingot_gold`, Devil's Reroll `ore_red_raw` (Liam 4/11);
  - 4 mặt xúc xắc: face_blank `stone_block`, face_buff `gem_green`, face_debuff `gem_red`, face_mana `s16b`.
- Việc bên code khi nhận hàng (technical-artist soát brief 4/11):
  - thêm hàm chọn cỡ `_32/_64/_128` cho glyph, giống `currency_icon`, và cho `icon()` / `cream_icon()` dùng nó. Nếu không, bản 64 / 32 vẽ tay sẽ không được dùng;
  - `PactView` đang gắn cứng `ui_mooncard`: thêm map id pact → icon, gồm cả 4 pact lấy từ kho. Riêng Twin Fates thì game tự ghép `gem_pink` + `gem_red` thành một ảnh;
  - `CombatView.gd` và `UnitHeadHUD.gd` preload thẳng `icons/web/{mana,buff,debuff,blank,reroll}.svg`: đổi sang icon mới, sau đó mới xoá bản web;
  - house: chép PNG vào `ui3/icons/house_*.png` (`icon()` ưu tiên png), rồi kiểm lại `UI6Assets.needs_disc` / `light_disc` (đĩa kem chỉ dành cho SVG viền đen cũ).

---

## What this is

Batch 2 of replacing every AI-looking piece of art in Axie Dice. Same rule as batch 1:
- if the official Sky Mavis / Axie Homeland library has the thing, the game uses it as is;
- if it does not, you redraw it **traced from specific library pieces** (same shapes, materials, palette and painting style).

Batch 1 (the Core card set) is done and in the game. You drew it, and the owner approved it. Your new pieces must sit with it as one set. See `set/` in the zip.

This batch has **12 pieces**:
- 5 Boss Pact icons;
- 1 house emblem (Gambler);
- 6 small UI glyphs.

Do not reuse or restyle the current versions in `current/`. They were made by AI and rejected.

## Step 1: style test first, then STOP
Draw only these 3 pieces first:
- `pact_brittledice`: the hardest pact. It is a die, but it must not look like the batch-1 `family_dice`.
- `house_gambler`: it must sit in the same "stump + object" set as the houses taken from the library.
- `ui_lock`: sets the glyph style. It must read at 20 px and as a one-colour silhouette.

Show them next to their library references, with the measurements, and **stop**. Draw the other 9 only after the owner approves these 3.

## The library style (same as batch 1)
- **Painting:**
  - soft gouache cel shading in 2–3 tones, with one warm white highlight;
  - a thin dark outline in the darkest shade of the piece's own colour, never black;
  - rounded, chunky, toy-like proportions.
- **Light:**
  - light from the top-left on every piece;
  - the shadow is one crescent on the dark side, saturated, in the same colour family as the lit area: never grey, never purple;
  - no airbrushed gradients, no glow halos, no photo texture.
- **Highlights:**
  - small and tight, only on glossy things;
  - sparkle stars only on gems, glass or rings.
- **Palette:** the same as batch 1:
  - amber `#f0a047` `#e7af60` `#cc8232`
  - earth orange `#dd6e34` `#c26554` `#a1683a`
  - cream `#f3eedb` `#e5deae` `#eae5c1`
  - deep brown, small areas only, `#4b3930` `#715d5b`; for large dark areas use `#5a463a` or lighter
  - teal `#2f605f` `#29ab92` `#44d3a6`
  - red `#c44140` `#ca5e63`
  - sage `#7eb280` `#93dd92` `#bbd0a8`
  - green `#77b229` `#589d34` `#2a7b43` `#1f5c48`
  - stone `#b4ac9f` `#68635c`

  Any colour outside it is marked "extrapolated, no sample".

**Metrics** for the pacts and Gambler. Measure on a copy of the delivered file, tight-cropped and scaled so its longest side is 256. This applies to Gambler as well, even though its canvas is larger.

| metric | target |
|---|---|
| near-black pixels (V < 0.2) | ≤ 1 % |
| min V | ≥ 0.20 |
| coverage | 0.37–0.83 |
| grain | 1.1–2.8 |
| colours (16-level bins) | 16–160 |

- Near-black and min V must pass.
- The other three are warnings: a miss needs a one-line reason.
- If you cannot run code, write "not measured".
- The glyphs (part C) are measured only for near-black and min V.

**Hard rules for all 12:**
- no text;
- no faces or eyes;
- no creature, creature part or silhouette (no wolf, no paw, no claw, no tooth, no tusk, no horn on an animal);
- no drop shadow outside the piece;
- no glow;
- no black outlines.

Some library pieces contain a creature or come from one: `a14a` (ice block with a creature), `f20b` (bird statue), `feather`, `spiky_ball_*` and `m14` (have faces), and `a10a` (jester). Most of these are not in the zip. Do not trace `f20b`, `spiky_ball_*`, `m14` or `a10a` at all. From `feather`, take **tone only**. From `makerdao2` (a horn-shaped ornament), take **shape only**.

## A. Boss Pacts (5)
A pact is a deal the player takes after a boss: a big gain plus a drawback. The icon sits:
- on the pact card, in a 96 px picture box (see `context/pact-screen.png`, where all three cards show the same moon placeholder);
- at about 36 px in the owned-items list.

All 9 pacts must tell apart at 36 px. Four of the 9 come straight from the library, and you do not draw them: Twin Fates (`gem_pink` + `gem_red` as a pair), Iron Vow (`ingot_iron`), Tithe of Pips (`ingot_gold`), Devil's Reroll (`ore_red_raw`, dark rock with red gems). They are in `library/pacts_in_game/`.

Three pacts lean red: Blood Pact (yours), Devil's Reroll (red gems in dark rock) and Twin Fates (pink + red). Make Blood Pact clearly different from both:
- Blood Pact: deep wine red;
- Devil's Reroll: small red gems set in dark rock;
- Twin Fates: pink-red.

| # | file | what | trace from (`library/refs/`) | avoid |
|---|---|---|---|---|
| 1 | pact_bloodpact.png | A blob of wine-red sealing wax with a drop stamped into it, stuck to a scrap of paper | colour and gloss of `gem_red` (cut-gem red, warm white highlight); cream paper from the palette | a heart (that is `family_stat`); a plain red drop (too close to `gem_red`, which is a die face) |
| 2 | pact_lonewolf.png | Three parallel gouges cut deep into a sawn slice of wood, as if by a blade | wood grain and cut face of `wood_plank`, ring pattern of the stump top in `a1_base` | any wolf, paw, claw or face |
| 3 | pact_brittledice.png | A warm sandstone die cracked in two, one chip fallen beside it, tilted, no base; the crack shows a lighter inner stone | the sandy carved stone of the pillar `f4b` (stone only, leave out its green vines); stone palette `#b4ac9f` `#68635c` | cream body or wooden base (that is `family_dice` in `set/`); cool blue-grey (that is `ingot_iron`, Iron Vow); a lightning bolt |
| 4 | pact_patientfang.png | One curved, carved ivory spike standing at a slant on a small stone foot: an ornament, clearly not a tooth | ivory tone and soft shading of `feather` (tone only); the curve of `makerdao2` (shape only) | a tooth, tusk, gums or any animal; an hourglass (that is `family_run_rule`) |
| 5 | pact_hollowchalice.png | A wide chalice on a low foot, open mouth, dark empty inside | terracotta colour and band pattern of `s16a` | a narrow-necked bottle (the mana flask `s16b`, and the teal bottle `s11c`); liquid or anything inside |

Size: **128×128 only**, transparent, tight but not cut off.

## B. House Gambler (1)
Houses are the six Anchor families. The other five use real library objects (`library/houses_in_game/`):
- Volley (`s2a`) and Big Hand (`s2c`) are objects on a **tree stump**;
- Mana Mine, Embers and Kin are single objects.

Gambler is the house of luck and dice, and joins the stump pair.

| # | file | what | trace from | avoid |
|---|---|---|---|---|
| 6 | house_gambler.png | The same tree stump as `s2a` / `s2c`, from the same angle, with two red lacquered dice with cream pips resting on it. Leave out the red target rings: the stump top shows plain wood rings, as on `a1_base`, so the red dice stand out clearly | stump shape, angle and painting of `s2a` and `s2c`; plain top of `a1_base` | cream dice (that is `family_dice`); a jester or box (`a10a`); many small dice; red on red |

Size and scale:
- canvas **384 px tall** (like `s2a` and `s2c`), width as needed, transparent;
- the stump is the same pixel size as in `s2a`, so Gambler lines up with Volley and Big Hand;
- also deliver `house_gambler_128.png` (longest side 128).

## C. UI glyphs (6)
These are small button icons. On screen they are 20–36 px, and as small as about 13 px on a 1280 screen. The library has no glyphs, so take only material, colour and line weight from it.

Style for all 6 (this differs from the pacts):
- **simple blocky shapes, at most 2 tones**: cream as the main colour, warm brown wood for the shadow side;
- a light gouache touch, no inner detail;
- no thin lines, rounded ends.

The game shows several of them **tinted cream**: on the combat HUD buttons, and next to the flat code-drawn glyphs in the combat action tiles. The tint multiplies every pixel by cream, so:
- cream stays cream;
- brown turns a darker brown;
- in the action tiles the game may flatten the glyph to one cream colour.

So:
- every glyph must read from its outer shape alone, with no inner dark line carrying the meaning;
- holes (the keyhole, the gear centre) must be real transparent holes.

| # | file | what | trace from | avoid |
|---|---|---|---|---|
| 7 | ui_check | A thick block tick, rounded ends | weight and line of the batch-1 pieces in `set/` | thin strokes |
| 8 | ui_lock | A block padlock: rounded square body, thick shackle, a round keyhole cut through | the cream / wood straps of the chest `s19a` | two tones so close they merge at 20 px |
| 9 | ui_menu | Three thick horizontal bars, rounded ends | the wood face of `a19b` | any extra detail |
| 10 | ui_reroll | Two curved arrows chasing each other into a closed circle | as above | a die (the Gamble action already is one) |
| 11 | ui_settings | A cog with 6 teeth and a large centre hole, in the same cream + brown as the other glyphs | the chunky block shape and soft edges of `ingot_iron` (shape and weight only, not its colour) | many small teeth; grey metal |
| 12 | ui_undo | One curved arrow turning back, an open loop | as above | anything like `ui_reroll`: the silhouettes must differ clearly (one open arrow vs two closed) |

Sizes: **128, 64 and 32** for each (`ui_check_128.png`, `ui_check_64.png`, `ui_check_32.png` ...). Redraw or sharpen the 64 and 32 after downscaling; do not just shrink the 128.

## Context
- `context/` holds game screenshots: the pact screen, the combat HUD (reroll and menu buttons, action tiles), missions (locks), daily (checks), the Land HUD (settings) and the anchor pick (houses).
- `current/` holds the current versions on the game's dark panel colour, **for meaning and size only**.
- `set/` holds the batch-1 pieces your new ones must match.

## Status
Every piece is `placeholder` until the owner approves it.

## Self-check before delivery
Report each line as pass, fail or not measured:
- no creature, face or eyes;
- no text;
- no black outlines;
- one light direction;
- sparkle stars only on gems, glass or rings (list them);
- pacts and Gambler: the 5 metrics, with the count passing all 5 and a reason for each miss;
- glyphs: near-black and min V; plus a strip of each glyph at 20 px and 13 px, shown three ways (as drawn, multiplied by cream `#f3eedb`, and flattened to one cream colour), to prove it still reads;
- all 9 pacts (your 5 plus the 4 library ones) in one row at 36 px: can each be told apart?
- `house_gambler` in one row with the 5 library houses, at the same scale;
- the usual AI faults:
  - warped shapes;
  - mixed light;
  - melted forms;
  - pieces of one family at different scale or style.

  Check each piece at real size.
- every file delivered (list any missing).

## Send back
- `art-batch2/` with every PNG:
  - RGBA, sRGB, exact canvas size;
  - names exactly as listed.
- One contact sheet: each new piece next to the library pieces it traced.
- The two rows above (9 pacts at 36 px, 6 houses at one scale) and the glyph silhouette strip.
- A short README: for each piece, which library pieces it traced and what it took from each.
