# Polish plan, bản nháp v2 (art-director, 16/10/2026, sau review UX)

Chờ Liam duyệt, chưa làm gì cả. Mức độ: **S1** = đọc không được / lỗi / art giả nằm trên đường chơi chính. **S2** = lệch style rõ, ai cũng thấy. **S3** = chỉnh cho đẹp. Phạm vi: **T** = sửa ở token/theme là xong nhiều màn, **M** = sửa riêng từng màn.

Nguồn ảnh: Land v5 (`production/qa/evidence/l1-land-v5-*`), combat/arena ở `my-game-wt/C` (l6-*, c9-*), Run Setup + Profile + Result ở `my-game-wt/M`, Leaderboard/Presets ở `my-game-wt/L`, Land upgrade ở `my-game-wt/E`, và bộ smoke 13/10 (Run Map, Pass, Vault, Store, Echo Box). **Ảnh 13/10 đã 3 ngày tuổi, có thể một số lỗi đã được sửa; Batch 0 chụp lại trước khi sửa.**

**Đã xong, không nằm trong plan này:** 3 việc L6 của Liam (dải giữa màn combat, cổng xoay yaw 90° + party chạy xuyên qua, animation quái/boss) đã làm xong ở commit 0f79582, f093436, cd2ef88, 0a1e223, có trong build b615. Liam xác nhận khi test ngày 17/10.

## 1. Từng màn: 3 vấn đề tệ nhất

| Màn | 3 vấn đề | Mức | Phạm vi |
|---|---|---|---|
| **Land hub** | (1) Nút RUN dính đáy màn, chip "Enter 1" bị cắt sát mép; (2) tooltip "Start here" nền đen đặc, đè lên rương/prop, khác hẳn kem+gỗ; (3) nền vàng-cam bão hoà cùng tông với cây, nhãn LOCKED/FREE/NEW chìm giữa tán cây, chip Esc đứng trơ một mình | S2 | (1)(3) M, (2) T |
| **Run Setup** | (1) Chân dung Axie trong 5 thẻ party chỉ là ô màu phẳng; (2) dải mặt xúc xắc chỉ có số trên ô pastel, không có glyph loại mặt (trái rule 6), chữ rule A1-A6 chỉ ~12px; (3) cột Aid và Mode trống nửa dưới, nền là ảnh đầm tối chứ không phải Land mờ như R3 | S1 | (1) M, (2)(3) T |
| **Run Map** (13/10) | (1) Chữ trắng trên panel kem: "LUNACIA RUN", tên Axie, "0/18" gần như vô hình; (2) node toàn ô tối chấm "?" trên rừng tối, không phân cấp, nét đứt trắng dày; (3) subtitle nâu trên rừng tối, nửa phải màn trống | S1 | (1)(3) T, (2) M |
| **Combat** | (1) Thẻ boss + "NEXT 7" đè lên đầu boss, tab NEXT lệch cạnh panel; (2) chữ ~11px ở vùng quyết định (dải 6 mặt, "used 0 of 6", "E · 5 dice unused"), 8 ô trống góc trái không nhãn, chip "A6 v" khó hiểu; (3) sân 3D: mặt đất mảng phẳng, chân trời là dải đặc, cây/đá lơ lửng (Genesis, Mystic) | S2 | (1)(3) M, (2) T |
| **Result** | (1) Chữ trắng trên thẻ kem: tên Axie, "9 / 18", "0", "LV 4" vô hình; (2) dòng "Seed ... replayable" nâu tối trên ảnh tối; (3) thẻ chân dung chồng thẻ tên, thẻ giữa trống, số 0 tô xanh/đỏ/cam không có nghĩa | S1 | (1)(2) T, (3) M |
| **Pass** (13/10) | (1) Cắt mép phải: "Season 1 · starts 3 Nov 202…", track tràn khỏi khung; (2) chuỗi nội bộ lọt UI: "Stat unlock: U Reroll", "Fx C Leaf", "Frame U Vine"; (3) thẻ level cao ~210 nhưng nội dung chiếm nửa, không icon phần thưởng, hai banner nâu dày chồng ở đầu | S1 | (1)(2) M, (3) T |
| **Echo Box** (13/10) | (1) Rương chỉ là chữ "Gold Chest" trên ô be, trong khi ảnh rương đã có ở `godot/assets/echobox/chests/`; (2) modal Reveal rộng 430 nhưng thẻ lệch trái, nửa phải trống, kết quả bị cắt; (3) thanh pity là rãnh nâu đen đặc, 0/15 nhìn như đã đầy | S1 | (1)(2) M, (3) T |
| **Vault** (13/10) | (1) Một Label rộng 0 nên chữ bẻ dọc từng ký tự ("Y/o/u/ /a/r/e..."); (2) subtitle nâu trên đầm xanh tối; (3) không dùng shell panel + header gỗ như các màn R3 | S1 | (1) M, (2)(3) T |
| **Store** | (1) 6 thẻ Gem chỉ chữ + nút xám "Buy with USD" giống hệt nhau, không icon Gem, không giá; (2) Cosmetics: art 60px khi ô vuông khi vòng, 8 nút "need N more Gem" giống nhau; (3) banner nâu 2 dòng chữ ~11px ăn chỗ, ~35% đáy panel trống | S2 | (1)(2) M, (3) T |
| **Profile / Leaderboard / Presets / Land upgrade** | (1) Đáy panel trống 20-35% ở cả 4 màn; (2) Land upgrade: ô màu thay thumbnail, "[INF]" lọt UI ("Mastery house [INF]"); Presets: 6 ô slot trống chiếm 60% màn; (3) Profile: tab đang chọn (Overview) màu be xám tối, nhìn như bị disable; avatar chỉ là chữ "L" | S2 (Land upgrade [INF] là S1) | (1)(3) T, (2) M |
| **Settings, Account** (ảnh dark-slate, chưa chắc còn đúng) | (1) Settings là cột hẹp ~500px trên ảnh rừng, 2/3 màn trống; (2) chữ xám trên rừng sáng, contrast thấp; (3) modal "Choose a save" slate đen + thẻ kem, nút "Keep cloud" đen dẹt | S1 nếu ảnh còn đúng | T |

**Chụp ở Batch 0 (chưa có ảnh mới):** Reward, Shop, Event (làm ở Batch 2 nên chụp đầu tiên), Treasure, Missions, Daily, Main Menu, Settings + Account hiện tại, Vault/Pass/Run Map mới nhất, Result thua và thắng, Echo Box mở 10 rương. Chụp ở 1920x1080 và 1920x1240.

## 2. Sửa chung, làm trước (mỗi mục kèm cách kiểm)

1. **Chữ trên nền.** Mọi chữ trên fill qua `ink_on()`; chữ nằm trực tiếp trên ảnh nền phải có plate riêng (token `photo_plate`). *Kiểm:* test quét contrast, chữ thường >= 4,5:1, chữ lớn >= 3:1, trên ảnh chụp lại của Run Map, Result, Vault, Settings.
2. **Thang chữ.** Chốt sàn 12px (14px cho Land), sửa `godot/CLAUDE.md` rule 5. *Kiểm:* test quét `font_size` trong `godot/scenes/`, không còn giá trị < 12 (Land < 14); thêm vào `run_tests.sh`, đổi số floor cùng commit.
3. **Panel shell + nền.** Chọn **panel ôm nội dung**, căn giữa dọc, không giãn theo viewport; nền Land mờ 12px + scrim 55% (R3) thay ảnh đầm. Vault/Pass/Run Map/Settings chuyển vào shell. *Kiểm:* ở 1920x1080 và 1920x1240, khoảng trống dưới nội dung <= 5% chiều cao panel; ảnh chụp 6 màn meta cùng một nền.
4. **Dev-text lọt UI.** *Kiểm:* test quét chuỗi `[INF]`, `[OBS]`, tiền tố ID thô (`U `, `C `), "(mesh name?)" trong mọi label hiển thị; 0 kết quả.
5. **Trạng thái nút/tab.** Tab chọn nổi hơn tab thường; nút disabled khác secondary, kèm lý do. Theo spec `DangoTheme` đã chốt. *Kiểm:* mở rộng `t_button_states` (72) thêm case tab selected và disabled-có-lý-do; chụp Profile + Store.
6. **Style dùng chung:** banner, thanh tiến trình, tooltip, `type_swatch` cho chip mặt xúc xắc. *Kiểm:* mỗi cái có 1 ảnh chụp ở 3 trạng thái (rỗng, nửa, đầy / có và không icon); không còn StyleBox đặc nâu/đen ở 4 chỗ cũ (grep).
7. **Quét placeholder** (làm ở Batch 2, đúng màn):
   - Run Setup: `asc/portrait`, ảnh 52px trong mỗi thẻ party.
   - Echo Box: `godot/assets/echobox/chests/`, ảnh rương thay chữ.
   - Land upgrade: thumbnail render c9/m15, thay ô màu.
   - Store: icon Gem từ `hl/icons`, làm cùng Store ở Batch 5.
   *Kiểm:* 0 ô màu phẳng còn lại trong các màn trên; `t_assets` vẫn xanh.

## 3. Thứ tự làm và lịch

Freeze 29/10, còn ~9 ngày làm việc. **Vạch cứng nằm sau Batch 2.** Mỗi batch có 1 ngày review độc lập (agent cao cấp khác), tính vào công.

| Batch | Nội dung và cách kiểm | Công | Nguồn frame |
|---|---|---|---|
| **0** | Chụp đủ + chụp lại ảnh cũ, một contact sheet, Liam chốt 3 câu bên dưới. *Kiểm:* contact sheet có đủ màn ở 2 cỡ | 0,5 + 0,5 review | không cần |
| **1** | Mục 2.1-2.6 (kiểm ở trên). **Cuối batch: chốt cỡ slot avatar/die, gửi brief cosmetics cho Claude Design** (xem dưới) | 2 + 1 review | R1 Style Sheet + R3 Shared Components |
| **2** | Hết S1 + Reward/Shop/Event, mỗi màn một lần: Run Map, Result, Pass (cắt + ID), Vault (chữ dọc), Echo Box (rương + modal), Run Setup (trọn màn, gồm chân dung), Land upgrade (trọn màn, gồm [INF] + thumbnail), Settings/Account, **Reward, Shop, Event**; cộng quét placeholder 2.7. *Kiểm:* ảnh chụp mỗi màn 2 cỡ, 0 chữ cắt mép, Vault không bẻ dọc (Label rộng > 0, test), `run_tests.sh` xanh | 4 + 1 review | R3 (M1, M3, M4, M5, M11, M13), Run Flow v2 |
| --- | **VẠCH FREEZE 29/10: ngoài đây là "nếu kịp / sau freeze"** | | |
| **3** | Combat HUD + sân 3D. *Kiểm:* thẻ boss không chồng đầu boss (ảnh chụp), chữ vùng quyết định >= 12px, mặt đất không còn mảng phẳng đơn sắc | 2-3 + 1 review | Combat R1 có sẵn |
| **4** | Land hub + Presets. Land hub *kiểm:* nút RUN cách đáy >= 24px, khoảng hở giữa 2 toà liền kề >= 48px ở 1920x1080, không toà nào bị cây/prop che quá 20% diện tích, nhãn toà nằm trên plate kem, chữ >= 14px. Presets: slot trống <= 2 ô hiện cùng lúc | 2 + 1 review | Land v5. **Cần Claude Design:** 5 mục leftover `REVIEW-land-hub-v5.md` |
| **5** | Store, Missions, Daily, Profile, Leaderboard. *Kiểm:* thẻ Gem có icon + giá, tab Profile selected nổi hơn, đáy trống <= 5% | 3 + 1 review | M6-M9, M12. **Cần Claude Design:** art item, icon gói Gem, avatar |
| **6** | Treasure, Main Menu (chỉ khi Main Menu còn tồn tại). *Kiểm:* ảnh chụp 2 cỡ | 1,5 + 1 review | Main Menu chưa có frame |

Batch 0-2 ~ 8,5 ngày, vừa freeze nếu không trượt. Batch 3-5 sửa file khác nhau nên chạy song song được 3 worktree (qua `with_lock.sh`, tối đa 4 agent), nhưng chỉ làm khi Batch 2 xong đúng hạn.

**Cosmetics round 2 (21 khung avatar + sửa die plate):** gửi brief **cuối Batch 1**, khi cỡ slot đã khoá (avatar 96/40 ở Profile, 52 ở Run Setup; die 104/64/36 ở preview, ~36px trong combat). Nhận về trong lúc Batch 2 chạy, lắp ở Batch 5 (Profile, Store, Echo Box). Die plate kiểm đọc được ở 36px sau Batch 3.

## 4. Câu hỏi cho Liam

Giữ Homeland v3 (kem + gỗ + viền nâu) làm hướng cuối cùng, coi như đã chốt.

1. "Xấu" nặng nhất là gì: chữ nhỏ khó đọc, màu/nền, hay thiếu hình (placeholder)? Và 3 màn Liam thấy tệ nhất là màn nào?
2. Cho Claude Design vẽ thêm frame mới (art item Store/Echo Box, avatar, Main Menu) không, và Main Menu còn tồn tại sau Land hub không?
3. Có/không: đồng ý sàn chữ 12px + nền Land mờ theo R3?
