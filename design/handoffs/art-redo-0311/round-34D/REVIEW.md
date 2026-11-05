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
2. **Skin lattice / scallop** (l_kingdom, e_s1_founder, r_aqua, r_bird, e_reef_06, r_reptile): **đang chờ Claude Design vẽ lại với hoạ tiết to hơn** (Liam tự viết prompt). Giữ bản hiện tại, không sửa tay.
3. **m_crystal core tím -> đỏ ruby**: đổi hue/saturation bằng script, giữ value, alpha, hình. Hue lấy từ base (359.5 độ, sat p75 0.70). Mean RGB trước 204/138/246 (hue ~278), sau 252/98/100. Glint giữ nguyên (255/238/242, trắng hồng ấm). Ảnh: `frames_m_crystal_before_after.png`.

## Test
- Test mới `t_art_batch34d` (170 check). Đã chạy: t_assets 508, t_art_batch2_lib 82, t_dice_skin 542, t_mockup_assets 132, t_cosmetics (sau khi thu nhỏ 6 khung), t_art_batch34d.
- Cả suite lần đầu (`AXIE_SKIP_RULES_FINGERPRINT=1`): 347 test, 346 xanh, `t_rules_version` bỏ qua theo cờ, `t_cosmetics` đỏ (6 khung thiếu viền 4 px) -> đã sửa như trên.
- Sàn mới nên +1 (t_art_batch34d).

## Chưa làm / để ý
- Sáu skin lattice chờ vẽ lại (câu 2).
- Chưa chụp riêng chỗ hiện tiền tệ (cur_*) trên HUD; tiền tệ có trong ảnh Profile / Echo Box.
- Cửa sổ 6 khung thu nhỏ (xem trên).
