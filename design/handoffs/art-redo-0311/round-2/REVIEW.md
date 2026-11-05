# Art lượt 2 + 2b: kiểm bản giao Claude Design, 4–5/11

Brief: `../PROMPT-batch2.md` (12 món vẽ + 12 món lấy từ kho), `../PROMPT-batch2b.md` (6 món sửa). Bản giao giải nén ở
`round-2/_zip/` và `round-2b/_zip/` (không `git add`). Liam đã duyệt style-pass bên Claude Design (Liam xác nhận 5/11).

## Đã vào game
- Lấy từ kho (Liam chốt 3–4/11): house Volley `s2a`, Big Hand `s2c`; pact Twin Fates `gem_pink`+`gem_red`, Iron Vow
  `ingot_iron`, Tithe of Pips `ingot_gold`, Devil's Reroll `ore_red_raw`; mặt xúc xắc blank `stone_block`, buff `gem_green`,
  debuff `gem_red`, mana `s16b`. Cắt sát, đệm 4 %, LANCZOS.
- Claude Design lượt 2: pact Blood Pact, Brittle Dice, Hollow Chalice; house Gambler; 6 glyph `ui_{check,lock,menu,reroll,
  settings,undo}` bản 64 (mặc định) + `_32` + `_128`.
- Claude Design lượt 2b: pact Lone Wolf (cột cờ teal), Patient Fang (mầm trong chậu); house Embers, Mana Mine, Kin trên cùng
  gốc cây với Gambler; `ui_reroll_16`. Cả 6 nhà cắt theo khung s2a như Gambler (kiểm: cắt lại Gambler ra đúng file game).
- Xoá SVG cũ (house, face, glyph, `icons/web/*`). Kin hết SVG nên không nhà nào còn đĩa kem.

## Kiểm
- Số đo (thước của lượt 1): mọi món near-black 0 %, minV ≥ 0.31. Số màu lố ở vài món là do phóng 128 → 256 (Blood Pact đã
  duyệt cũng vậy). Mana Mine grain 2.94 (Claude Design đo 2.79), bỏ qua.
- art-director, lượt 2 trong game: Lone Wolf như bánh quy, Patient Fang như mũ phù thuỷ, Embers / Mana Mine chìm, reroll
  ở cỡ nhỏ dính cục → lượt 2b. Lượt 2b: không lỗi chặn; nên chỉnh nhẹ trứng Kin (to ~10–15 %) và cột cờ Lone Wolf (mảnh ở
  37 px). Chưa gửi sửa.
- Code (lead-programmer, godot-gdscript-specialist): sửa motion Level Up còn trỏ `face_buff.svg`, nút Settings combat dùng
  bản 32, icon reroll đổi theo cỡ cửa sổ, comment cũ.
- Ảnh: `production/qa/art-batch2/`, `production/qa/art-batch2b/` (1920 + 1280), sheet trên nền gỗ
  `art-batch2/sheet-2b-walnut.png`.

## Code
- `UI3.icon(name, px)`: chọn `_16` (px ≤ 20.5, chỉ ui_reroll có) / `_32` (≤ 32.5) / `_128` (> 64.5), còn lại bản 64.
  `cream_icon` / `flat_cream_icon` (Hold / Undo trong ô hành động ép một màu kem).
- `UI6Assets.pact(id)`: icon pact theo id, pact mới chưa có art thì về moon card.
- Nút Reroll: chọn bản theo cỡ thật trên màn (icon_m × layout scale), `expand_icon` để bản 16 và 32 cùng vẽ ở icon_m.
- Test mới `t_art_batch2_lib`. `t_ui5_daily` bỏ chữ cấm "Lakebed Fishing Rod" vì đó là tên combo thật (đỏ theo ngày 5/11).
