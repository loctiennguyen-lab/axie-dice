# Art lượt 3 + 4 + D: đã lắp (5/11)

Nhánh `art/batch34d`, chưa merge, chưa push, chưa deploy. Hàng giao: `AxieDice-art-batch34D` (Claude Design, vòng 2 "richer painting").

## Đã lắp
**Skin xúc xắc (part3)**
- 26 albedo hạ 1024 → 512 (Lanczos), 14 emission, 2 metallic cũng 512. Chép đè đúng thư mục `assets/cosmetics/dice/<skin>/`.
- `normal.png` sinh lại từ albedo bằng script (độ cao từ luma, blur nhẹ, Sobel có wrap, quy ước OpenGL Y lên, độ mạnh sao cho xy std ~12/255, cùng cỡ skin cũ 9-35). `plate.png` giữ cũ.
- `DiceThumb.VERSION` 4 -> 5 (thumbnail bake lại).
- Ảnh: `production/qa/art-batch34D/1280/cos3d-thumbs.png` (26 thumbnail; tờ ảnh chỉ bố trí cho 20 nên 6 cái tràn xuống dưới, không phải lỗi game), `cos3d-faces-*.png`, `cos3d-profile-dice-*`, `cos3d-echobox-*`.

**Khung avatar (part4)**
- 27 `frame_<id>_base.png` hạ 1024 -> 256. Giữ mọi layer động cũ.
- Cửa sổ giao 648-649 ở 1024 -> ~162 ở 256, khớp `window_diameter_px`.
- **Sáu khung phải thu nhỏ**: `t_cosmetics` đòi viền ngoài 4 px trong suốt, mà bản giao vươn tới r 500/512 (còn 3 px). Thu cả khung quanh tâm (từ bản 1024): c_plant, c_bird, l_sovereign 0.964; e_firefly 0.971; u_mushroom 0.979; e_reef_04 0.956. Hệ quả: cửa sổ của sáu khung này còn 155-159 px thay vì 162, viền che avatar thêm tối đa ~3.5 px mỗi bên. Cần nới/giảm thì nói.
- Ảnh: `1920/cos3d-profile-frames-1920.png`, `cos3d-profile-frame_*`.

**Icon (partD)**
- `assets/icons/hl/`: aid, attrition, boss-clock, lethal, pact, spike, mỗi cái master 128 + `_64` + `_32`. Svg cũ của sáu cái này đã xoá.
- Xoá 8 tên không dùng (gem gift skip mooncard undo lock drawback eternal) + `reroll` (grep xác nhận không ai gọi; `HudKit.icon("reroll")` giờ trả `ui_reroll`).
- `HudKit.icon(name, px)` chọn `_32` / `_64` theo cỡ; lethal / attrition / aid đã truyền cỡ.
- `cur_fragment/gem/shard/ticket`: master 128 + `_64/_32/_24`. `cur_stone` cắt từ `stone_block` kho (128/64/32/24/16). `cur_stone_reveal` 256 + 64. `UI3.currency_icon` giờ tìm được `_24/_32/_64` của gem và shard.
- `TutorialCoach._STARTER_ICONS` vẫn trỏ được; `UI6Assets.needs_disc` không có `cur_*`, không cần đổi.
- Ảnh: `ui5/ui05-b1_a_02-combat--player-turn*.png` (HUD, nút Reroll), `ui5/ui05-b23_*profile*`, `cos3d-echobox-*`. (Scene capture ui5 ghi đè evidence cũ đã commit; mình chép ảnh mới vào `ui5/` rồi khôi phục bản cũ.)

## 3 câu Liam đã trả lời (5/11)
1. **e_reef_01 glow**: kéo vào trong. Làm bằng script, ép bán kính ngoài của lớp glow về trong (giữ file, tên, tâm, vòng trong). Trước: pixel mờ trải r 382 -> 617 (đơn vị 1024), tràn ra ngoài chân quạt (quạt tới r 486) và ra khỏi canvas. Sau: r 382 -> 479, không chạm góc. Ảnh: `frames_e_reef_01_before_after.png` (base + glow trên đĩa xám, 96 và 240 px, trái trước / phải sau; ảnh ghép, không phải trong game).
2. **Skin lattice / scallop** (l_kingdom, e_s1_founder, r_aqua, r_bird, e_reef_06, r_reptile): đã giao lại ở lượt 3b, hoạ tiết to hơn (xem mục 3b).
3. **m_crystal core tím -> đỏ ruby**: đổi hue/saturation bằng script, giữ value, alpha, hình. Hue lấy từ base (359.5 độ, sat p75 0.70). Mean RGB trước 204/138/246 (hue ~278), sau 252/98/100. Glint giữ nguyên (255/238/242, trắng hồng ấm). Ảnh: `frames_m_crystal_before_after.png`.

## Test
- Test mới `t_art_batch34d` (170 check). Đã chạy: t_assets 508, t_art_batch2_lib 82, t_dice_skin 542, t_mockup_assets 132, t_cosmetics (sau khi thu nhỏ 6 khung), t_art_batch34d.
- Cả suite lần đầu (`AXIE_SKIP_RULES_FINGERPRINT=1`): 347 test, 346 xanh, `t_rules_version` bỏ qua theo cờ, `t_cosmetics` đỏ (6 khung thiếu viền 4 px) -> đã sửa như trên.
- Sàn mới nên +1 (t_art_batch34d).

## Chưa làm / để ý
- Sáu skin lattice đã vẽ lại ở lượt 3b (xem dưới).
- Chưa chụp riêng chỗ hiện tiền tệ (cur_*) trên HUD; tiền tệ có trong ảnh Profile / Echo Box.
- Cửa sổ 6 khung thu nhỏ (xem trên).

## Bằng chứng trong game cho icon mới (`production/qa/art-batch34D/extra/`, mỗi cái có bản 1920 và `--1280`)
Mình chỉ xem kỹ 2 ảnh (attrition, Echo Box); các mục còn lại ghi theo tên file, chưa nhận xét độ đọc, cần mắt người xem.
- lethal: `b_selected_lethal_hover_1920x1080.png` (dải lethal trên chân dung khi hover). Chưa xem kỹ.
- attrition: `02-combat--attrition-upcoming|active|max.png`. **Rủi ro đúng như dự đoán**: thẻ "ATTRITION +10%" nền gỗ nâu, icon xám nhỏ ~28 px, tương phản thấp, đọc được nhờ chữ bên cạnh chứ không nhờ icon. Cần Liam/art-director quyết có làm sáng không.
- boss-clock: `02-combat--boss.png`, `e_boss_enraged_max_1920x1080.png`. spike: `02-combat--bighit.png` (chip "BIG HIT IN n"). Chưa xem kỹ.
- aid / boss-clock / pact: `c_aid_tray_1920x1080.png` (khay Aid), `02-combat--aid-offer` đã có trong `../ui5/`. Chưa xem kỹ.
- tiền tệ: Land `01-land--first-visit-*.png` (Ui5CurrencyPlate), Missions `40-missions--*.png` (cur_shard), Defeat `ui3-defeat-paid|short-*.png`. Chưa xem kỹ.
- khung m_crystal / e_reef_01 trên avatar thật (ProfileView): `profile-frame_m_crystal-1920|1280.png`, `profile-frame_e_reef_01-1920|1280.png`.
- Tờ thumbnail 26 skin chia 2 ảnh: `dice-thumbs-1-of-2.png`, `dice-thumbs-2-of-2.png` (bản mới nhất ở `3b/`, tức đã có skin 3b).

## Lượt 3b (6 skin lattice / scallop vẽ lại, hoạ tiết chu kỳ 512)
Cài giống 34D: 1024 -> 512, ghi đè `albedo/emission/metallic`, `normal.png` sinh lại cùng độ mạnh, `.import` không đổi và không có file nào `valid=false`. `DiceThumb.VERSION` 5 -> 6.

Số đo (README 3b; grain, mean V, min V, near-black %, colours), trước -> sau:
| skin | trước | sau |
|---|---|---|
| l_kingdom | 6.99 · 0.79 · 0.36 · 0 · 165 | 2.59 · 0.55 · 0.29 · 0 · 55 |
| e_s1_founder | 6.39 · 0.61 · 0.33 · 0 · 107 | 2.64 · 0.58 · 0.33 · 0 · 68 |
| r_aqua | 6.05 · 0.79 · 0.33 · 0 · 131 | 1.89 · 0.76 · 0.50 · 0 · 52 |
| r_bird | 6.22 · 0.82 · 0.46 · 0 · 183 | 2.53 · 0.74 · 0.52 · 0 · 96 |
| e_reef_06 | 6.14 · 0.81 · 0.49 · 0 · 91 | 2.71 · 0.80 · 0.64 · 0 · 30 |
| r_reptile | 6.11 · 0.59 · 0.28 · 0 · 95 | 2.56 · 0.60 · 0.34 · 0 · 34 |

Ảnh trong `production/qa/art-batch34D/3b/`: `cos3d-thumbs.png`, `dice-thumbs-1-of-2|2-of-2.png`, `echobox-ten-*`, `echobox-single-die_l_kingdom-*` và `die_l_gold-*`, `cos3d-faces-die_l_kingdom|r_bird|r_aqua.png`.
- Câu cho Liam: l_kingdom có quá tối không? Trong Echo Box 10-pull (`echobox-ten-1920x1080.png`) kingdom (đỏ thẫm + xanh navy, viền vàng) đứng cạnh l_gold: tối hơn rõ nhưng vẫn đọc được là xúc xắc legendary, không bị chìm. Liam xem lại bằng mắt.
- Trong tờ thumbnail 6 skin giờ thấy hoạ tiết to, không còn mịn như vải. Phần mặt (cos3d-faces) chưa xem kỹ.
- Echo Box 10-pull chỉ hiện xúc xắc 3D ở 2 thẻ đầu, các thẻ sau chỉ có tên; đây là cách capture hiện có (thumbnail bake lười), không phải lỗi 3b.

## Test cuối
t_art_batch34d (44337 check), t_dice_skin 542, t_assets 508 xanh sau 3b. Suite đầy đủ lần 2 (trước 3b và trước sửa test quét): 347/347 xanh, `t_rules_version` bỏ qua theo cờ.
