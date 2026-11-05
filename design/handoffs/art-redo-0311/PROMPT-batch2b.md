# Làm lại art: lượt 2b, sửa 6 món. Prompt cho Claude Design

**Cho Liam:**
- Dán phần dưới dòng `---` vào **cùng project Claude Design của lượt 2** (để nó còn nhớ style) và đính kèm `send/AxieDice-art-batch2b.zip`.
- Quyền sở hữu như lượt 1 và 2: đường R.
- Liam chốt 5/11: đợi vẽ lại rồi mới commit/deploy lượt 2. Mana Mine vẽ lại cùng Embers; Kin gửi vẽ. Lượt 2 Liam đã duyệt style-pass bên Claude Design.
- Vì sao sửa (soát ảnh trong game 4/11, art-director): Lone Wolf nhìn như bánh quy và gần màu Tithe; Patient Fang nhìn như mũ phù thuỷ; Embers (`coal_pile`) và Mana Mine (`ore_blue_raw`) chìm trên nền gỗ, Embers không thấy lửa; Kin trong kho (`a7a`) là búp bê có mặt người; `ui_reroll` ở khoảng 14 px dính thành cục.
- Hình và ref do art-director chốt 5/11 sau khi mở ảnh kho. Cả 6 nhà sẽ đứng trên cùng một gốc cây (như Volley, Gambler, Big Hand), để Embers / Mana Mine không còn chìm và khỏi phải thêm đĩa sáng trong Godot.
- Việc bên code khi nhận hàng (technical-artist soát 5/11):
  - chép 3 house PNG đè lên `ui3/icons/house_*.png` (không chép `_128`: các nhà khác không có, giữ một kiểu); xoá `house_kin.svg` + `.svg.import`; dọn nhánh `.svg` trong `UI6Assets.needs_disc` và comment;
  - `t_art_batch2_lib`: chuyển `h_kin` sang `LIB_HOUSES`, bỏ assert Kin là SVG, thêm assert `UI3.icon("ui_reroll", 16)` ra bản 16;
  - chép đè 2 pact;
  - thêm `ui_reroll_16.png`, cho `UI3._icon_variant` chọn `_16` khi px ≤ 16.5 (có `ResourceLoader.exists`, glyph khác rơi về `_32`). Đo cỡ thật của nút Reroll ở 1280 để chốt ngưỡng.

---

## What this is

A small fix round on batch 2. You drew batch 2 and the owner approved its style. In the game, 6 pieces did not work. Redraw only these 6, in exactly the batch-2 style:
- gouache cel shading in 2–3 tones, one warm white highlight, light from the top-left;
- shadow is one saturated crescent in the same colour family, never grey or purple;
- outline in the piece's own darkest shade, never black;
- **hard rules**: no text, no face or eyes, no creature or creature part, no drop shadow outside the piece, no glow or halo, no black outline.

**Colours.** The batch-2 palette has no blue, violet or pastel green. Where a piece needs them (Lone Wolf teal pennant, Patient Fang blue-white pot, Mana Mine crystals), take the colour from the named ref (`a13`, `a4c`, `ore_blue_raw`) and mark it "extrapolated, from <ref>" in the README.

Everything in `set/` is approved and stays. Your 6 new pieces must sit with it as one set. `current/` shows the rejected versions **only so you know what failed**. Do not rework them; start fresh.

`context/all-pacts-houses-walnut.png` shows every pact and 5 of the houses (Kin is not in the game yet) at real in-game size on the game's wood panel (`#3a2c24`). That is the test: each piece must stand out on that colour at that size.

## Step 1: one pass, then STOP
Draw all 6, show them with the self-check below, and stop for the owner's review. No second round without approval.

## A. Boss Pacts (2)
Size **128×128**, transparent, tight but not cut off. Shown at 96 px on the pact card and about 36 px in lists.

The 9 pacts now fall into three colour groups: pink/red (Twin Fates, Devil's Reroll, Blood Pact), gold/brown (Tithe of Pips, Brittle Dice, Hollow Chalice), cool grey-blue (Iron Vow). Your two new pacts take the empty slots: **teal-green** and **pale blue + cream**.

| # | file | what | trace from (`refs/`) | avoid |
|---|---|---|---|---|
| 1 | pact_lonewolf.png | "Lone Wolf Contract": one Axie gets double damage, the other four lose rerolls. Draw **one banner standard**: a tall wooden pole with **one teal-green cloth pennant** hanging from it and a small plain ball on top. One vertical shape, nothing beside it. Make the pole and pennant thick enough to read at 36 px; the coverage metric will likely miss on this tall shape, which is accepted (say so). | `a13a`, `a13b` (the pole and the hanging cloth shape only); `taiyaki_skewer` (pole wood tone) | the hat / pom on top of `a13`; any wolf head, claw, paw, tooth or animal; round flat discs (the old one read as a biscuit); gold or amber as the main colour |
| 2 | pact_patientfang.png | "Patient Fang": turn 1 deals nothing, every later turn hits harder. Draw **a seedling just sprouting** from a small round pot: two leaves, pot glazed pale blue-white with a cream band. Waiting pays. | `a4c` (the pot only, its blue-white glaze); `a1c` (leaf shape only: leave out its sword, stump and vine); `cabbage` (leaf green) | a cone or horn shape (the old one read as a witch hat); rounded leaves are fine; tooth, fang or tusk; an hourglass (that is `family_run_rule`); a pink or orange pot (Twin Fates, Hollow Chalice) |

## B. Houses (3)
All six houses stand on **the same tree stump**. The reference is the stump of your approved `set/house_gambler.png` (traced from `s2a` / `s2c`, plain ring top of `a1_base`): copy it at the same angle and pixel size, bottom-centred. Only the object on top changes.

- Canvas **384 px tall**, width as needed (Gambler is 320×384), transparent. Also deliver `house_embers_128.png`, `house_mana_mine_128.png`, `house_kin_128.png` (longest side 128, like `set/house_gambler_128.png`).
- The object must rise **at least one third of the stump's height** above the stump top, like Volley's arrow and Big Hand's axe. Otherwise the six read as six identical stumps.
- Each object has its own main colour: Volley red target, Gambler red dice, Big Hand grey axe, and now Embers orange-yellow flame, Mana Mine blue-violet crystal, Kin cream + straw.
- The stump is warm orange. Embers and Kin are warm too, so separate them by **value**: flame core pale yellow-white, coal deep red, straw nest darker than the stump top, eggs the lightest thing on the piece.
- "Glowing" and "lit" below mean colour and value only: cel-painted in 2–3 tones, no halo, no blur.

| # | file | what | trace from | avoid |
|---|---|---|---|---|
| 3 | house_embers.png | "Last Strike": the last die of the turn hits hardest. A **bright orange-yellow flame** rising from a glowing red-orange coal chunk set in the stump top. The flame is the shape that reads. | stump: `s2a`, `s2c`, `a1_base`; coal: the glowing red top of `charcoal_log`; flame: the flame wisp of `corn` | a black coal pile on a yellow patch (the old one sank); any large dark mass; sparkle stars (not a gem) |
| 4 | house_mana_mine.png | Spare mana turns into damage. A cluster of **3–4 bright blue-violet crystals** growing out of the stump top, the middle one tallest. Lit, saturated, glassy. | stump as above; crystals: colour and facets of `ore_blue_raw` only (leave out its dark rock) | dark grey rock; any dark body; grey-blue (that is Iron Vow's `ingot_iron`). Sparkle stars are allowed, on the crystals only |
| 5 | house_kin.png | "Cover": shield the weakest. **Three cream eggs** in a small golden straw nest on the stump top, the smallest one tucked in the middle. Soft, protective. | stump as above; eggs: `egg`; nest weave and colour: the basket of `a17a` | any face, eyes, blush or doll (the library `a7a` was rejected for this); any animal; speckled eggs (spots read as eyes); red (Gambler) |

## C. UI glyph (1)

| # | file | what | trace from | avoid |
|---|---|---|---|---|
| 6 | ui_reroll_16.png | A **16×16 hand-drawn** reroll glyph for buttons where it shows at 13–16 px (see `context/combat-reroll-button.png`, cropped from the 1280 combat screen). Two thick half-rings that together close a circle, each ending in a solid triangle head, with **at least 2 px gap** between them. Same cream body and brown-wood crescent as your batch-2 glyphs. Pixel-fit it by hand; do not shrink the 32. | weight and colours of `set/ui_undo_32.png`, `ui_settings_32.png` (the current reroll is in `current/` for comparison only); brown tone of `a19b` | strokes under 2 px; inner lines; a die or dot in the middle; one open loop (that is Undo); heads smaller than the stroke |

Keep the existing `ui_reroll_32/64/128` unless you find the 32 also fails at 20 px; then send a fixed 32 too and say why.

## Self-check before delivery
Report each line as pass, fail or not measured:
- no creature, face or eyes; no text; no black outlines; one light direction;
- sparkle stars: list them (Mana Mine crystals only);
- pacts and houses: the 5 metrics from batch 2 (near-black ≤ 1 %, min V ≥ 0.20, coverage 0.37–0.83, grain 1.1–2.8, colours 16–160), measured on a copy cropped tight and scaled to 256 long side; near-black and min V must pass;
- **on the wood panel `#3a2c24`**:
  - all 9 pacts in one row at 36 px (your 2 + the 7 in `set/`): can each be told apart, and does each stand out from the panel?
  - all 6 houses in one row, each scaled from its 384 canvas to 64 px tall (your 3 + Gambler from `set/`, Volley and Big Hand from `refs/s2a`, `refs/s2c`): same stump size, and each top object readable;
  - `ui_reroll_16` at 13 and 16 px, three ways (as drawn, multiplied by cream `#f3eedb`, flattened to one cream colour), next to `ui_undo_32` shrunk to 16 for comparison;
- every file delivered.

## Send back
- `art-batch2b/`: `pact_lonewolf.png`, `pact_patientfang.png`, `house_embers.png` + `_128`, `house_mana_mine.png` + `_128`, `house_kin.png` + `_128`, `ui_reroll_16.png`. RGBA, sRGB, exact sizes, names exactly as listed.
- One contact sheet: each new piece next to the refs it traced.
- The three check rows above on `#3a2c24`.
- A short README: per piece, which refs and what was taken from each, and the metrics. Status of every piece is `placeholder` until the owner approves it in the game.
