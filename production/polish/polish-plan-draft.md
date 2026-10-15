# Polish plan, bản nháp (art-director, 16/10/2026)

Chờ Liam duyệt, chưa làm gì cả. Mức độ: **S1** = đọc không được / lỗi / art giả nằm trên đường chơi chính. **S2** = lệch style rõ, ai cũng thấy. **S3** = chỉnh cho đẹp. Phạm vi: **T** = sửa ở token/theme là xong nhiều màn, **M** = sửa riêng từng màn.

Nguồn ảnh: Land v5 (`production/qa/evidence/l1-land-v5-*`), combat/arena ở `my-game-wt/C` (l6-*, c9-*), Run Setup + Profile + Result ở `my-game-wt/M`, Leaderboard/Presets ở `my-game-wt/L`, Land upgrade ở `my-game-wt/E`, và bộ smoke 13/10 (Run Map, Pass, Vault, Store, Echo Box). **Ảnh 13/10 đã 3 ngày tuổi, có thể một số lỗi đã được sửa; Batch 0 chụp lại trước khi sửa.**

## 1. Từng màn: 3 vấn đề tệ nhất

| Màn | 3 vấn đề | Mức | Phạm vi |
|---|---|---|---|
| **Land hub** | (1) Nút RUN dính đáy màn, chip "Enter 1" bị cắt sát mép; (2) tooltip "Start here" nền đen đặc, đè lên rương/prop, khác hẳn kem+gỗ; (3) nền vàng-cam bão hoà cùng tông với cây, nhãn LOCKED/FREE/NEW chìm giữa tán cây, chip Esc đứng trơ một mình bên phải | S2 | (1)(3) M, (2) T |
| **Run Setup** | (1) Chân dung Axie trong 5 thẻ party chỉ là ô màu phẳng, không có hình; (2) dải mặt xúc xắc chỉ có số trên ô pastel, không có glyph loại mặt (trái rule 6), chữ rule A1-A6 chỉ ~12px; (3) cột Aid và cột Mode trống nửa dưới, nền sau là ảnh đầm tối chứ không phải Land mờ như R3 | S1 | (1) M, (2)(3) T |
| **Run Map** (13/10) | (1) Chữ trắng trên panel kem: "LUNACIA RUN", tên Axie, "0/18" gần như vô hình; (2) toàn bộ node là ô tối chấm "?" trên rừng tối, không phân cấp, nét đứt trắng dày; (3) subtitle "Pick the next node..." nâu trên rừng tối, không đọc được, nửa phải màn trống | S1 | (1)(3) T, (2) M |
| **Combat** | (1) Thẻ boss + "NEXT 7" đè lên đầu boss, tab NEXT lệch cạnh panel; (2) chữ ~11px ở vùng quyết định (dải 6 mặt xúc xắc, "used 0 of 6 / Hide offers: Settings", "E · 5 dice unused"), 8 ô trống góc trái không nhãn, chip "A6 v" khó hiểu; (3) sân 3D: mặt đất mảng màu phẳng, chân trời là dải đặc, cây/đá lơ lửng trên nền (Genesis, Mystic) | S2 | (1)(3) M, (2) T |
| **Result** (c7 + 13/10) | (1) Chữ trắng trên thẻ kem: tên Axie, "9 / 18", "0", "LV 4" vô hình; (2) dòng "Seed ... replayable from the main menu" nâu tối trên ảnh tối, không đọc được; (3) thẻ chân dung chồng lên thẻ tên, thẻ giữa trống, các số 0 tô xanh/đỏ/cam không có nghĩa | S1 | (1)(2) T, (3) M |
| **Pass** (13/10) | (1) Cắt mép phải: "Season 1 · starts 3 Nov 202…", track tràn khỏi khung, không có viền panel; (2) chuỗi nội bộ lọt lên UI: "Stat unlock: U Reroll", "Fx C Leaf", "Frame U Vine"; (3) thẻ level cao ~210 nhưng nội dung chiếm nửa, chỉ chữ, không icon phần thưởng, hai banner nâu dày chồng ở đầu | S1 | (1)(2) M, (3) T |
| **Echo Box** (13/10, b12) | (1) Rương chỉ là chữ "Gold Chest" trên ô be, trong khi ảnh rương đã có ở `godot/assets/echobox/chests/`; (2) modal Reveal rộng 430 nhưng thẻ nằm lệch trái, nửa phải trống, kết quả bên dưới bị cắt; (3) thanh pity/fragment là rãnh nâu đen đặc, 0/15 nhìn như thanh đã đầy | S1 | (1)(2) M, (3) T |
| **Vault** (13/10) | (1) Một Label rộng 0 nên chữ bẻ dọc từng ký tự ở góc trái ("Y/o/u/ /a/r/e..."); (2) subtitle nâu trên đầm xanh tối không đọc được; (3) không dùng shell panel + header gỗ như các màn R3, trông như màn khác game | S1 | (1) M, (2)(3) T |
| **Store** | (1) 6 thẻ Gem chỉ có chữ + nút xám "Buy with USD" giống hệt nhau, không icon Gem, không giá USD, nhìn như placeholder; (2) Cosmetics: art 60px khi ô vuông khi vòng, 8 nút "need N more Gem" giống nhau; (3) banner nâu đậm 2 dòng "Playing as a guest" chữ ~11px ăn chỗ, ~35% đáy panel trống | S2 | (1)(2) M, (3) T |
| **Profile / Leaderboard / Presets / Land upgrade** (gần Homeland nhất) | (1) Đáy panel trống 20-35% ở cả 4 màn (panel luôn cao bằng viewport, nội dung không lấp); (2) Land upgrade: ô màu thay thumbnail, ghi chú "[INF]" lọt lên UI ("Mastery house [INF]"), Presets: 6 ô slot trống chiếm 60% màn; (3) Profile: tab đang chọn (Overview) màu be xám tối, nhìn như bị disable; avatar chỉ là chữ "L" | S2 (Land upgrade [INF] là S1) | (1)(3) T, (2) M |
| **Settings, Account** (ảnh dark-slate, chưa chắc còn đúng) | (1) Settings là cột hẹp ~500px bên trái trên ảnh rừng, 2/3 màn trống, kiểu slate cũ; (2) chữ xám trên rừng sáng, contrast thấp; (3) modal "Choose a save" slate đen + thẻ kem, nút "Keep cloud" đen dẹt, khác M13 | S1 nếu ảnh còn đúng | T |

**Cần chụp (chưa có ảnh mới):** Reward, Shop, Event, Treasure, Missions, Daily, Main Menu (và xác nhận Main Menu còn tồn tại sau Land hub), Settings + Account bản hiện tại, Vault/Pass/Run Map bản mới nhất, Result thua và thắng, Echo Box mở 10 rương. Chụp ở 1920x1080 và 1920x1240.

## 2. Sửa chung, làm trước (một lần, cả game ăn theo)

1. **Chữ trên nền.** Chữ trắng trên kem (Run Map, Result) và chữ nâu trên ảnh tối (Result, Vault, Run Map, Settings). Mọi chữ trên fill qua `ink_on()`, chữ nằm trực tiếp trên ảnh nền phải có plate riêng (token mới `photo_plate`). Sửa một chỗ, vá được ~6 màn.
2. **Thang chữ.** `godot/CLAUDE.md` rule 5 cho phép 9-11px, R3 và Land v5 đòi sàn 12/14. Chốt sàn 12 (14 cho Land) và thêm test quét cỡ chữ. Đây là nguyên nhân chính của cảm giác "chữ li ti".
3. **Panel shell + nền.** Panel hiện luôn cao bằng viewport nên đáy trống. Cho panel ôm nội dung (hoặc nội dung giãn lấp), và đưa nền về đúng R3: Land mờ 12px + scrim 55%, thay ảnh đầm tối hiện tại. Vault/Pass/Run Map/Settings chuyển vào shell này.
4. **Dev-text lọt UI.** Test quét chuỗi `[INF]`, `[OBS]`, tiền tố ID thô (`U `, `C `), "(mesh name?)" khỏi mọi label hiển thị.
5. **Trạng thái nút/tab.** Tab đang chọn phải nổi hơn tab thường (Profile hiện ngược lại); nút disabled khác nút secondary (6 nút Store giờ giống secondary), kèm lý do. Dựa trên spec đã chốt (`DangoTheme` hover/pressed/disabled).
6. **Style dùng chung còn thiếu:** banner (thay khối nâu đặc), thanh tiến trình (thay rãnh nâu đen), tooltip (thay đen đặc), `type_swatch` cho mọi chip mặt xúc xắc.
7. **Quét placeholder** bằng asset có sẵn: chân dung Run Setup (`asc/portrait`), rương Echo Box, icon Gem/Shard/Stone (`hl/icons`), thumbnail Land (ảnh render đã có ở c9/m15).

## 3. Thứ tự làm (mỗi batch ship được)

| Batch | Nội dung | Công | Nguồn frame |
|---|---|---|---|
| **0** | Chụp đủ + chụp lại ảnh cũ, một contact sheet, cùng Liam chốt 5 câu bên dưới | 0,5 ngày | không cần |
| **1** | Mục 2.1-2.6 (token, thang chữ, shell, nền, state, dev-text lint) | 2 ngày | có sẵn: R1 Style Sheet + R3 Shared Components |
| **2** | Hết S1: Run Map, Result, Pass (cắt + ID), Vault (chữ dọc), Echo Box rương, Run Setup chân dung, Land upgrade [INF], Settings/Account vào shell | 2-3 ngày | có sẵn: R3 (M1, M3, M4, M5, M11, M13), Run Flow v2 |
| **3** | Combat HUD + sân 3D (boss card, chữ nhỏ, mặt đất/chân trời) | 2-3 ngày | Combat R1 có sẵn; sân 3D dùng asset-library, chưa cần Claude Design |
| **4** | Land hub (nút RUN, tooltip, độ tách toà nhà, Esc chip) + Run Setup + Presets | 2 ngày | có sẵn: Land v5. **Cần Claude Design:** 5 mục leftover trong `REVIEW-land-hub-v5.md` (Gallery mesh, slot Leaderboard, newcomer lock) |
| **5** | Store, Missions, Daily, Profile, Leaderboard | 3 ngày | có sẵn: M6-M9, M12. **Cần Claude Design:** art item cho Store/Echo Box (R3 chỉ để "labelled slot"), icon gói Gem, avatar Profile |
| **6** | Reward, Shop, Event, Treasure, Main Menu | 2 ngày | Run Flow v2 có sẵn, nhưng **chưa có ảnh hiện trạng**, nên làm sau Batch 0. Main Menu chưa có frame nào |

Tổng ~14 ngày một làn. Batch 3, 4, 5 sửa file khác nhau nên chạy song song 3 worktree được, còn ~9 ngày; vẫn phải qua `with_lock.sh` và tối đa 4 agent. Mốc 3/11 rất chặt với phương án này, nên Batch 6 là thứ đầu tiên rớt nếu trễ. Số công là ước lượng thô, chưa tính vòng review độc lập mỗi batch.

**Cosmetics round 2 (21 khung avatar + sửa die plate):** gửi brief cho Claude Design **sau Batch 2** khi cỡ slot đã khoá (avatar 96/40 ở Profile, 52 ở Run Setup; die 104/64/36 ở preview, ~36px trong combat), vì vẽ trước thì phải vẽ lại khung cho đúng cỡ. Nhận về trong lúc Batch 3-4 chạy, lắp vào ở Batch 5 (Profile, Store, Echo Box). Die plate cần kiểm tra đọc được ở 36px sau Batch 3.

## 4. Câu hỏi cho Liam

1. "Xấu" nặng nhất là gì: chữ nhỏ khó đọc, màu/nền, hay thiếu hình (placeholder)? Và 3 màn Liam thấy tệ nhất là màn nào? Câu này quyết thứ tự Batch 2-5.
2. Giữ Homeland v3 (kem + gỗ + viền nâu) làm hướng cuối cùng, hay muốn đổi hẳn một phần (ví dụ combat tối hơn)?
3. Nền các màn meta: Land mờ + scrim như R3, hay giữ ảnh đầm tối hiện tại (dễ đọc hơn nhưng lệch spec)?
4. Sàn chữ: 12px (R3) hay 14px cho mọi thứ người chơi phải đọc? 14 dễ đọc hơn nhưng nhiều màn phải bỏ bớt dòng.
5. Cho Claude Design vẽ thêm frame mới (art item Store/Echo Box, avatar, Main Menu) trong Polish, hay chỉ dùng asset sẵn có để kịp 3/11?
