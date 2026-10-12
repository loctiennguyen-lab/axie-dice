Trạng thái: REVIEW — chờ Liam

> **QUYẾT ĐỊNH LIAM (12/10):** ngày kết thúc Mùa 1 tạm 30/11/2026 · nhận 5 nhà đề xuất (Weaponsmith, Alchemy, GemStorage,
> Jeweler, Armorsmith) · làm tròn mọi số sát thương: ≥ .5 lên, < .5 xuống · ghi chú gửi Claude Design: `NOTE-TO-CLAUDE-DESIGN-R1.md`.

# Review độc lập: Dice UI R1 (Claude Design) so với brief 02

Người review: Art Director · 12/10/2026 · Không sửa file art/HTML nào.

**Cách đọc.** Tôi đã xem: contact sheet 19 khung, các screenshot (01-hub-check, 02-hub-check, 03-hub-check, 01-c2, 02-c2, 03-c2, 04-c2), 3 icon (lethal, attrition, aid), README R1, README + contact sheet Ascension v2, và đọc source `Combat.dc.html` / `Land Hub.dc.html` (giá, text, data). Tôi **chưa** đọc hết `Style Sheet.dc.html` (chỉ grep Mythic và bảng reduce-flashing) và **không render được HTML**, nên chi tiết từng pixel (căn lề, độ tương phản tính số) chưa kiểm. Nhận định về cỡ chữ nhỏ là từ source + contact sheet 0.42, cần Liam nhìn lại ở 1:1.

**Lưu ý quan trọng:** contact sheet và source HTML **lệch nhau ở 03a–03c**. Contact sheet vẫn ghi "Revive the party at 40% HP", +21/+26/+23/+18/+24, còn source HTML ghi 25% và +13/+16/+15/+11/+15 (đúng README). Tức contact sheet 03 là bản cũ, chưa export lại.

---

## 1. Verdict

| Khu vực | Verdict |
|---|---|
| Style sheet (00) | **ACCEPT WITH FIXES** |
| Land hub (01a–01d) | **ACCEPT WITH FIXES** (gần ACCEPT, chỉ là chi tiết) |
| Combat (02a–02l) | **ACCEPT WITH FIXES** |
| Defeat (03a–03c) | **ACCEPT WITH FIXES** (sai số liệu, không sai layout) |

Lý do ngắn: hướng đi đúng và nhất quán. Homeland style, viền đậm, HUD tối giản, Portal ở giữa, máu Axie chỉ ở khay, Aid xa END TURN (1.472 px), nút Continue/End run cùng cỡ, có biến thể reduce-flashing. Lỗi chủ yếu là **số liệu tự mâu thuẫn**, **một ví dụ luật không có trong game**, **cỡ chữ quá nhỏ ở vài chỗ**, và **giá cũ** (không tính lỗi của Claude Design).

---

## 2. Giá cũ phải đổi (không tính lỗi Claude Design)

Giá chốt PA-1: Continue 90 / boss 180, VIP −25%; Extra reroll 15; Delay boss clock 60; Swap pact 15; Shop refresh 18; Scout 12; Boon 38; Kit 60. Cap Aid 6 (4 từ A9), 1 Boon/run nằm trong cap. Continue hồi 25% từ A6. Quy đổi 90 Gem ≈ 1 USD.

| Chỗ | Đang ghi | Phải sửa thành |
|---|---|---|
| README §4 | Continue 60 / boss 120 (≈ 1.33 USD) | 90 / 180 (≈ 2.00 USD) |
| 03a (caption, nút Continue, sub-line, source dòng 419–421) | 120 Gem, "≈ 1.33 USD · boss fight price" | 180 Gem, "≈ 2.00 USD · boss fight price" |
| 03c | 90 gạch 120, "≈ 1.00 USD" | Boss: 135 gạch 180, "≈ 1.50 USD". Fight thường: 90 → **68** (monetization-v1.md khối "chốt giá": VIP −25% = 68 / 135) |
| 03b (gift) | Miễn phí, chữ chân | Giữ, nhưng xem §4 (A-level) |
| 02f offer Delay boss clock (source dòng 401) | 40 | 60 (≈ 0.67 USD) |
| 02g offer Extra reroll | 10 | 15 |
| 02h bảng Aid, hàng Extra reroll | 10 | 15. Các hàng khác cần hiện giá thật kể cả khi disabled: Delay 60, Swap pact 15, Continue 90/180 |
| 02i modal xác nhận | "10", "Pay 10", "≈ 0.11 USD", "Your Gem 35 → 25" | 15, "Pay 15", "≈ 0.17 USD", "Your Gem 35 → 20" |
| README §3 (02i) | "Cancel and Pay 10" | "Pay 15" |
| 02f, 02g, 02i, 02h | "this fight 0 of 2 / 1 of 2" trong khi HUD là A6 | A3+ chỉ 1 reroll mua/fight → "0 of 1". Hàng Aid tray: "run 0/4 · fight 0/1" |
| Cap Aid "used n of 6" | chỉ có biến thể 6 | thêm biến thể A9–A10: "of 4" |
| Aid tray (02h) và Codex/Store | thiếu dòng công khai | thêm đúng dòng: "Aid makes you stronger for one run. Players who buy more can win more. The Pure leaderboard only counts runs without Aid." (nằm cạnh bảng giá). Hiện footer chỉ ghi "Boons come from Run Setup only… 90 Gem ≈ 1 USD" |
| README §4 và 03a–c: heal | Frame trên contact sheet 40% | 25% từ A6 (HTML đã đúng; export lại) |
| 01c Moon Card popup | "Continue at −25%" | Giữ. Bổ sung ví dụ giá sau giảm cho Continue (68 và 135) nếu popup muốn nêu giá |
| 01c | "1 Boon a day" | Giữ, đã nói tính vào giới hạn 1 Boon/run. Kiểm lại câu với quy tắc "1 Boon/run trong cap Aid" |

---

## 3. Findings theo mức độ

### Cao

1. **02e, 03a–c: số intent không khớp phép tính.** README ghi 84 = 38 × 2.0 × 1.25 (nhân). Công thức đã chốt (`monetization-v1.md` §1.2, ngay dưới bảng A–F) là **cộng % rồi nhân một lần**: `dmg = base × (1 + enrage% + attrition%) × spike_mult`. Base 38, enrage MAX +100%, attrition +25%: 38 × 2.25 = **85.5** (86 hay 85 tùy làm tròn, chưa chốt, xem "Unknowns" của Ascension v2). Vậy 84 sai cả theo cách nhân (95) lẫn cách cộng (85.5). Recap 03 turn 12: "Smash 52 (incl. enrage +60%)": 38 × (1 + 0.6 + 0.25) ≈ 70, 52 không khớp cái nào. Brief cốt lõi là "một số hợp nhất, người chơi không phải cộng"; nếu mockup sai thì dev sẽ copy số sai vào test. Yêu cầu: chọn base, tính lại bằng công thức cộng cho 02e, 02f, 03 và recap, kèm bảng số trong README. (Auditor sửa 12/10: bản đầu của review dùng phép nhân, sai so với công thức chốt.)
2. **Attrition sai theo turn: 02b, 02c, 02d, 02k, 02l, 03a–c.** Luật: bắt đầu turn 6, +5%/turn, max +25%. Turn 6 = +5%, turn 7 = +10%, turn 10 = +25% MAX. Nhưng turn 7 ghi "+5%" (đúng chỉ khi bắt đầu từ turn 7), turn 14 ở 03a–c ghi "+5%" (đúng phải là +25% MAX). 02f turn 8 ghi +15% (khớp luật). Vậy cả bộ không nhất quán. Sửa cho cùng một công thức.
3. **02b, 02c, 02k, 02l: lý do "Airborne — needs a ranged face" không có trong game.** Grep design/gdd và godot/scripts: không có luật airborne, taunt, hay untargetable. Auditor xác nhận thêm trong `combat_engine.gd` (`_exec_face`, `use_die`) và `godot/tools/run_bot.gd`: chỉ có hai trường hợp từ chối thật là mặt **blank** (không dùng được) và **heal nhắm vào quái** (bị từ chối); mặt dmg/poison/debuff nhắm quái. `monetization-v1.md` §1.1 còn cấm "trait/hệ khắc chế" nên luật Airborne mâu thuẫn với luật thiết kế. README đã tự ghi là [INF]. Nếu để lại, dev và QA sẽ tưởng cần làm cơ chế mới. Xem §5 điểm 2.
4. **03b: gift chỉ áp dụng A0–A2 nhưng HUD hiện badge A6 và heal 25% (chỉ có từ A6).** Frame mâu thuẫn với chính luật của nó. Sửa: vẽ 03b ở A1 (badge A1, heal 40%, +21/+26/+23/+18/+24 là đúng cho A0–A5), giữ 03a/03c ở A6.

### Trung bình

5. **02h: Aid tray che mất Axie 1 và cột khay 1 (Bubbles).** Rộng 520 từ left 16, đáy cao hơn khay 12 px: nó phủ hộp Axie đầu tiên và đè 12 px lên đỉnh cột Bubbles (xem screenshot 02-c2). Brief cấm UI của đội đè lên quái, không cấm đè lên Axie, nên không phải vi phạm cứng. Nhưng người chơi mất xem Bubbles đúng lúc đang cân nhắc mua. Đề xuất: đáy tray = đỉnh khay − 8 (không đè cột), hoặc thu hẹp 440, hoặc đẩy sang trái-trên nơi không có Axie. Giữ "đỉnh ≥ 16 px dưới hộp quái thấp nhất".
6. **Cỡ chữ 11–12 px quá nhiều.** README tự dùng 11 cho key hint trên shortcut, "NEXT" 11, nhãn action 12, chú thích Aid 12, status chip trong khay 14. Ở 1920×1080 trên laptop 13–15" scale xuống còn khó đọc. Brief yêu cầu đọc được trên nền 3D bận. Yêu cầu: sàn 12 px cho thông tin mà người chơi cần (action label, "used n of 6", cap, lý do disabled), 11 chỉ cho decor. Tăng face strip trong khay (6 mặt, h 34) và status chip nếu còn chỗ; nếu không, ghi rõ chúng tùy chọn hiện khi hover.
7. **Disabled quá nhạt cho thông tin quan trọng.** `#9A7650` trên `#DDBF8C`/`#E8D6B4` cỡ ~2.4:1 (tôi tính tay). Với nút bị disable thì chấp nhận được, nhưng "Reroll · 0 left" (02g, 02h) và nhãn shortcut khóa "Builds at Arctic" (01a) là thông tin phải đọc. Giữ nền xám nhưng chữ đậm hơn (đề xuất `#6E4A30` trên `#E8D6B4`).
8. **02c: chip WILL DIE thay chip spike "Big hit in 2" khi hover.** Khi hover lethal, người chơi mất thông tin big hit (radical transparency). Cho phép cả hai: spike tab giữ nguyên, WILL DIE nằm ngay dưới hoặc thay chip "−12 · 38 → 26" thôi.
9. **Reroll FX (`Dice UI R1 - Reroll FX.dc.html`) không có trong README.** Tiêu đề trong file ghi "Reroll animation · v3 / Round 1 · 04". README không nhắc, nó không phải khung trong contact sheet. Hỏi lại: là file thừa hay deliverable? Nếu giữ thì README phải mô tả. Screenshot của nó (01-rr, 03-rr) cho thấy nút Aid "used 2 of 6" trong lúc reroll, không mâu thuẫn, nhưng tôi không duyệt nó như một phần Round 1 cho tới khi README nhận.
10. **01a: ngày hết season "30 Nov 2026" là số bịa.** Brief chỉ nói "hiện bằng ngày". Ghi [INF], Liam xác nhận ngày season 1.
11. **README tự nhận [INF] nhiều tên building (Missions, Echo Box, Vault, Store, Mastery).** Xem §5 điểm 1.

### Thấp

12. **Hub: 3 Axie placeholder 96×78 rất nhỏ** so với nhà (360×360 Portal). OK cho placeholder, nhưng khi 3D thật vào, tỷ lệ Axie so với nhà cần Liam xem lại. Không phải lỗi mockup.
13. **Hub: Run plate đè lên nền Portal.** Hợp lý, nhưng phần "Enter" key chip nhỏ. Ổn.
14. **01a: plot khóa Mastery/Gallery có ổ khóa và nhãn "Builds at Arctic/Genesis Land"** — đúng brief. Chỉ nhắc: hai plot này nằm sau nhãn của House ở góc trái trên (xem 02-hub-check), không chạm nhau nhưng khá sát.
15. **Mastery Hall (Armorsmith) và Missions (Weaponsmith) cùng họ "smith".** Ở 01d hai nhà khác màu nên vẫn phân biệt được. Chỉ lưu ý khi đổi biome.
16. **Violet chỉ cho bề mặt trả tiền.** Đúng ở Aid, Continue, Pay. Nút "Buy · 4.99 USD" trong Moon Card dùng cam primary (đúng vì là USD, không phải Gem). Giữ, nhưng ghi rõ quy tắc này vào style sheet để Round 3 (Store) không lẫn.
17. **Contact sheet 03a–c lệch source** (đã nêu ở đầu). Export lại.
18. **Lethal: viền đỏ `#D9472B` + chip vàng + icon sọ.** Không phụ thuộc màu, tốt. Icon sọ, hourglass, heart ở 128 px đọc được, viền đậm. Đạt.

### Bổ sung của auditor (review gốc bỏ sót)

19. **Thiếu Undo.** Game đã có free undo trong lượt (`CombatEngine.undo_last()`, nối ở `CombatView.gd` ~2836, rule spec §2). Mockup R1 không có nút hay phím Undo. Hỏi Claude Design vẽ chỗ đặt (gần Reroll, bên phải, không gần Aid) và phím, và trạng thái disabled sau reroll/turn mới.
20. **Bàn phím/gamepad chỉ mới nói ở hub.** README chỉ ghi "1–9 mở, Tab đi trái → phải" cho hub và "Focus order: column → die → target" cho combat. Chưa có: phím chọn mặt xúc xắc 1–5 (game cũ có), phím xác nhận target, phím mở Aid tray, Esc đóng modal 02i/tray, focus ring vàng ở từng trạng thái, và thứ tự Tab giữa khay, Reroll, END TURN, Aid. Checklist accessibility yêu cầu dùng được chỉ bằng bàn phím và chỉ bằng gamepad; R1 chưa đạt, cần một frame/bảng "focus map" cho combat, hub, modal.
21. **Click target.** Reroll 200 × 56, nút trong khay Aid 96 × 44, nút Gem trong offer 192 × 48, key chip 20 px đều ổn. Hàng face strip trong khay (h 34, 6 mặt) nếu bấm được thì hơi nhỏ trên touch; nếu chỉ để đọc thì ghi rõ "không bấm". Phần chữ 11–12 px đã nêu ở mục 6.
22. **Aid so với "rào niềm tin".** Layout offer đạt các rào chính (giá, cap, Not now cùng cỡ, không đồng hồ, xa END TURN). Nhưng: (a) 02f "Delay boss clock · this run 2 of 6 used" nói cap tổng, còn cap của chính món (1/boss) nằm ở chỗ khác; mỗi offer nên hiện cả hai. (b) Offer Aid hiện lúc reroll = 0 (02g) cùng lúc nút Reroll bị khóa: hợp luật "một chào mỗi khoảnh khắc" nhưng cần chốt khi người chơi bấm "Not now" thì hàng trong khay Aid vẫn mua được (đã có ở 02h, giữ). (c) Giai đoạn làm quen (5 run đầu, `monetization-v1.md` §1.6): **ẩn mọi chào Aid trả tiền, tắt attrition và clock nhẹ A0**. R1 chưa có khung/ghi chú cho trạng thái này (nút Aid ẩn hay không? card attrition ẩn hay không?). Thêm vào §7.
23. **Hub dễ đọc.** Contact sheet 0.42 cho thấy plate tên + phím số rõ, Portal là điểm nhìn đầu tiên, plot khóa đọc được. Chữ sub-line 12 px dưới plate ("Builds at…") và chip thanh trên 11 px là chỗ yếu, đã nằm trong mục 6. Badge 30 px trên nhà nhỏ đủ thấy.

### Điểm tốt đáng giữ

- Layout chốt đúng: monster trên (nameplate top 96), party dưới (không UI trên đầu), khay 5 cột thẳng hàng với Axie, Aid ở góc đối diện END TURN, offer card Aid không chạm Axie.
- Intent một số, có tab boss clock và spike tab cùng một vị trí. Phase mark 66/33. Attrition card ở góc phải không đè quái (x 1594–1904, quái tới x 1440).
- 1920×1240: neo trên/dưới, thêm 160 px khoảng trống giữa quái và party. Đúng ý "expand".
- Reduce-flashing có ở 02l và bảng motion, mọi hiệu ứng có bản tĩnh.
- Nút decline cùng cỡ nút mua (192×48, 268×60, 302×72, 352×60). Không có đồng hồ đếm ngược.
- Mythic `#FF3D6E` chỉ dùng cho chip, viền tên tier, ink tối `#2A0F2E`: đúng quyết định cosmetics-01.

---

## 4. Đối chiếu từng yêu cầu của Liam

| Yêu cầu | Kết quả |
|---|---|
| Homeland style, nét nâu đỏ | Đạt. Nền cream/gỗ, bóng một kiểu, không neon, không trắng tinh. Giống ngôn ngữ cosmetics-01 |
| Viền đậm cỡ nhỏ | Đạt (2 px dưới 24 px, 3 px chip/nút, 8-way outline cho số trên cảnh 3D) |
| HUD tối giản | Đạt. HUD chỉ ở rìa; giữa cảnh chỉ có banner enemy turn/victory |
| Camera cố định, Portal giữa | Đạt. Portal 360×360 lớn nhất, nằm giữa |
| Shortcut bar + phím 1–9 | Đạt. Chữ key hint 11 px hơi nhỏ (finding 6) |
| VIP popup + badge | Đạt. Nút Close và Buy cùng 352×60, không đếm ngược, "shown at most once a day" |
| Máu party chỉ ở khay, không gì trên đầu Axie | Đạt (số damage nổi từ Axie là hiệu ứng, không phải thanh máu) |
| Không UI party đè quái | Đạt (finding 5 là đè Axie, không phải quái) |
| Aid xa END TURN | Đạt, 1.472 px |
| Mục bắt buộc: enrage clock, spike, phase mark, attrition, một số damage, preview + lethal, badge Ascension | Đủ hình, **sai số** (finding 1, 2) |
| Defeat recap + Continue | Đạt layout; sai số (finding 1, 4) |
| Reduce flashing | Đạt |
| 1920×1080 + cửa sổ cao | Đạt (01d, 02k) |
| Godot-buildable | Đạt về nguyên tắc: nine-slice, gradient 2 stop, một blur 12 px cho Land. Lưu ý với dev: outline 8-way cho chữ là khó với Label thường, dùng `outline_size` + font outline, hoặc dựng bằng shader/LabelSettings. Hỏi `technical-artist` trước khi chốt |

---

## 5. Trả lời 4 điểm mở của README §5

1. **Chọn nhà (Missions, Echo Box, Vault, Store, Mastery).** Khuyến nghị: **chấp nhận cả 5 như đề xuất**, vì Liam là người nhìn render. Lưu ý: nhà tím cho Store khớp màu Gem, tốt; **tránh ConsumableStall** như họ đã nói. Brief ban đầu gọi Vault là "warehouse", nên nếu Liam thấy GemStorage không giống kho thì thử GreenWarehouse. Việc này không chặn, đổi nhà chỉ là thay ảnh.
2. **Ví dụ lý do target illegal.** **Bỏ "Airborne"**: game không có luật đó, và `monetization-v1.md` §1.1 cấm trait khắc chế, nên Liam không cần quyết, tài liệu đã trả lời. Dùng lý do có thật (đã kiểm trong code): "Heal face: allies only" (heal nhắm quái bị từ chối), "Blank face: nothing to use" (mặt blank không dùng được). Mặt Shield nhắm quái: chưa kiểm thấy trong code, đừng ghi cho tới khi game-designer xác nhận. Trạng thái "illegal" của quái vì vậy hiếm; giữ trạng thái dim + lý do nhưng đổi frame ví dụ.
3. **Boss clock nhẹ (A0–A3, 3 pip).** Khuyến nghị: **đồng ý dùng cùng tab, 3 pip**, bắt đầu turn 14, +10%/turn, tối đa +30%. Yêu cầu Round 2 vẽ đủ trạng thái (ENRAGE IN n / NEXT TURN / +10%, +20%, +30% MAX). Màu pip theo 3 nấc, nấc cuối `#C9302B` khi MAX. Lưu ý: ở Ascension v2 (3.3) tab chỉ có từ A4; cần cập nhật để A0–A3 cũng hiện tab clock nhẹ (radical transparency).
4. **Cập nhật `godot/CLAUDE.md`.** Khuyến nghị: **chưa sửa bây giờ.** Đợi Claude Design gửi lại style sheet đã sửa (cỡ chữ, màu disabled) rồi Liam duyệt, mới viết mục "UI v3 Homeland" thay luật cũ. Làm sớm quá thì sheet đổi lại phải sửa hai lần. Theo CLAUDE.md gốc, tôi không tự sửa khi Liam chưa bảo.

---

## 6. Ascension v2 (request 01 cũ): dùng lại gì cho Round 2

Tôi chỉ xem contact sheet + README, chưa xem từng file HTML.

**Dùng lại được (nội dung, logic, số):**
- Rule list A1…A10 (cumulative, overrides được viết lại, không giấu), cùng bảng nhân HP/DMG.
- Boss clock: các trạng thái đã gộp vào R1, giữ.
- Eternal sticker (reward card, relic chip, sell flow, giới hạn 2/2), weaken pre-warning (map node + fight intro), màn pact (3 card, GAIN/COST khác màu, forced variant, slot full không có cancel), giá shop +15% (gạch giá gốc + giá cuối, một cách dùng ở mọi chỗ), reward 2 card, A10 không reroll, slot 8 khóa ở A8.
- 5 icon mới: `boss-clock`, `eternal`, `pact`, `drawback`, `lock`.

**Phải vẽ lại cho hợp Homeland:**
- Toàn bộ nền tối (`#10131A`, `#262C36`, `#1B1F27`), viền đen tuyền, chữ sáng trên nền tối. Đây là style cũ mà brief đã bỏ. Chuyển sang cream/wood/dusk, viền `#24140B`, theo R1. Màu badge Ascension `#C9302B` + `#FFF8EA` giữ (R1 đã dùng).
- Icon: đổi viền đen tuyền thành `#24140B` và kiểm ở 24 px.
- Màn map và pact đang nằm trên nền 2D `6-river.jpg`; Round 2 phải đặt trên cảnh 3D / diorama theo brief.

**Việc còn mở từ v2 README "Unknowns"** (Liam cần trả lời hoặc đọc code): tên title ở A5 và A10; giá trị weaken và target khi bắt đầu fight; làm tròn intent khi enrage; làm tròn sell ở A0 (50%); trigger của reroll bị grey ở A10; nhóm pact của `brittledice`.

**Nhắc cho Round 2:** số giá phải theo PA-1 (shop refresh 18, Scout 12, Swap pact 15, Boon 38, Kit 60), cap Aid 6 (4 từ A9), 1 Boon/run nằm trong cap; boss clock nhẹ A0–A3.

---

## 7. Ghi chú gửi Claude Design (tiếng Anh, sẵn sàng gửi)

```
Round 1 review — thanks, the direction is right and consistent. Verdict: ACCEPT WITH FIXES for the style sheet, hub, combat and defeat. Please send a corrected Round 1 before Round 2.

A. Fixes for Round 1

1. Numbers must reconcile (02e, 02f, 03a-c, README). Our rule: enrage % and attrition % are ADDED, then multiplied once: intent = base x (1 + enrage% + attrition%) x spike_mult (spike_mult = 1 when no spike is due). "84 = 38 x 2.0 x 1.25" is wrong either way (38 x 2.25 = 85.5; rounding is not decided yet, so show 86 and mark it [INF]). The recap line "Smash 52 incl. enrage +60%" at turn 12 also matches neither (38 x (1 + 0.6 + 0.25) = about 70). Pick a base, compute once with this formula, and put the table in the README. The intent on the plate, on the clock tab ("incl. in N") and in the recap must be the same number.
2. Attrition is +5% on turn 6, +10% on turn 7, ... +25% MAX on turn 10. Frames at turn 7 show +5% and 03a-c (turn 14) show +5%. Fix 02b, 02c, 02d, 02k, 02l, 03a-c.
3. Illegal-target reason (02b, 02c, 02k, 02l): "Airborne - needs a ranged face" is not a rule in our game (and we do not use counter-traits by design). Use a real reason, for example "Heal face: allies only" or "Blank face: nothing to use", and keep the dim-with-reason treatment.
4. 03b (free gift) is only for A0-A2, but the frame shows the A6 badge and the A6 heal. Redraw it at A1 (badge A1, heal 40%) and keep 03a / 03c at A6 (heal 25%). Re-export the contact sheet: tiles 03a-c still show the old "40%" text; the HTML source already says 25%.
5. Prices changed after the brief was sent (final, PA-1):
   - Continue 90, boss fight 180, VIP -25% (so 68 and 135). 180 Gem is about 2.00 USD, 135 about 1.50 USD, 90 about 1.00 USD.
   - Extra reroll 15 (02g, 02h, 02i; Pay 15, about 0.17 USD, "Your Gem 35 -> 20").
   - Delay boss clock 60 (02f, 02h). Swap pact 15, Shop refresh 18, Scout 12, Boon 38, Run Kit 60.
   - Show the real price on disabled rows in the Aid tray too.
   - Extra reroll cap from A3 is 1 per fight (you drew "of 2" on an A6 run). Aid cap is 6, and 4 at A9-A10: add an "of 4" variant. At most 1 Boon per run, and it counts toward the cap.
6. Add this line plainly next to the Aid price list (Aid tray footer, and note for Store/Codex in Round 3): "Aid makes you stronger for one run. Players who buy more can win more. The Pure leaderboard only counts runs without Aid."
7. 02h: the Aid tray covers Axie 1 and the top of the first tray column. Keep the panel off the tray (bottom >= 8 px above the tray top), or narrow it, and keep its top >= 16 px below the lowest monster box.
8. Text size: too many things at 11-12 px (shortcut key hints, NEXT label, intent action label, Aid footer, tray status chips and face strip). Use 12 px as the floor for anything a player must read (action label, "used n of 6", caps, disabled reasons), and say in the README which items are decorative-only. Disabled ink #9A7650 on #DDBF8C / #E8D6B4 is about 2.4:1. That is fine for a disabled button, not for "Reroll - 0 left" or the locked-building labels, so use a darker ink there (e.g. #6E4A30).
9. 02c: the lethal chip replaces the "Big hit in N" tab while hovered. Keep both visible; the player must not lose the spike information when previewing a hit.
10. The "Reroll FX" file is not in the README. Say whether it is part of the delivery. If yes, document it; if no, remove it.
11. "Season 1 - ends 30 Nov 2026" is invented. Mark it [INF] in the README; we will give the real date.
12. Missing: Undo. The game has a free undo inside a turn (until reroll or a new turn). Please draw where it sits (right side, near Reroll, far from Aid), its key, and its disabled state.
13. Missing: keyboard and gamepad map for combat (die select, target confirm, Aid tray open, Esc to close the tray and the 02i modal, focus ring on every state, Tab order across tray, Reroll, END TURN, Aid). Keyboard-only and gamepad-only must work.
14. Each Aid offer should show both caps: the item cap (e.g. 1 per boss) and the run cap ("used n of 6"). In 02f only the run cap is shown.

B. Reminders for Round 2

- Use the Round 1 style sheet only. The Ascension v2 mockups are dark slate with pure black outlines: keep their content and logic, redraw them in the Homeland cream/wood/dusk look with #24140B outlines. Re-outline the five new icons (boss-clock, eternal, pact, drawback, lock) and check them at 24 px.
- Map and pact screens go on the 3D diorama / shared arena frame, not on a 2D background.
- Light boss clock for A0-A3: same tab, 3 pips, starts turn 14, +10% per turn, max +30%. Draw all its states, and show the clock tab at A0-A3 as well.
- Cap of 6 Aid uses (4 from A9), 1 Boon per run counted in it. Remaining Aid offers: Scout 12 (3/run), Shop refresh 18 (2/run), Swap pact 15 (1/pact), Kit 60 / Boon 38 in the Run Setup strip. Every offer shows price and "used / cap", decline button the same size as buy, no countdown.
- Seasonal items are only from the seasonal Echo Box; never show a direct price for them.
- New accounts (first 5 runs created) have no paid Aid offers, no attrition and no light boss clock. Show that state: no Aid button, no attrition card, no clock tab. Do not draw a dead or greyed Aid button there.
- Keep reduce-flashing variants for every animated element.
- Keep README tags [OBS] / [INF] and mark invented rules and dates.
```

---

## 8. Câu hỏi Liam cần trả lời

Chỉ còn những câu docs chưa trả lời. Các câu cũ đã có đáp án trong docs, bỏ khỏi danh sách Liam:
- Làm tròn Continue VIP: **68** / 135 (monetization-v1.md, khối "chốt giá").
- Lý do target illegal: bỏ Airborne, dùng lý do thật (§5.2); không cần Liam.
- Gift Continue có tiêu hao Continue không: **có**, nó "dùng làm Continue của run" (monetization-v1.md §2.6 chỉ nói gift ở A0–A2, lần thua đầu ở boss/elite; việc "tiêu hao" là mock suy ra, trần Continue 1/run nên hợp lý, ghi [INF] là đủ).
- Attrition: "mỗi lượt kể từ lượt 6, +5%, tối đa +25%" (§1.2-D) và README 02f/02e đã dùng turn 6 = +5%, turn 10 = MAX; chỉ cần Claude Design sửa cho nhất quán. Lưu ý: attrition và clock nhẹ tắt trong 5 run đầu.
- Boss clock nhẹ A0–A3, 3 pip, turn 14, +10%/lượt: Liam đã duyệt 11/10 (OQ-B).
- `godot/CLAUDE.md`: theo quy trình, chờ bản R1 sửa xong rồi mới viết; không cần hỏi.
- "Reroll FX": hỏi thẳng Claude Design (§7 mục 10), không cần Liam.

Thực sự cần Liam:
1. Ngày kết thúc Season 1 (docs chỉ ghi "mùa Pass 8 tuần", không có ngày lịch). Có thể để [INF] tới khi gần ra mắt.
2. Chọn nhà: Weaponsmith (Missions), Alchemy (Echo Box), GemStorage (Vault, hoặc GreenWarehouse), Jeweler (Store), Armorsmith (Mastery). Đây là chuyện nhìn render, Liam quyết.
3. Làm tròn cường độ intent (85.5 hiển thị 85 hay 86?): docs chưa chốt, thuộc nhóm "Unknowns" của Ascension v2; game-designer/systems-designer đề xuất, Liam duyệt (hoặc cho Claude Design dùng 86 [INF]).
4. Gửi ghi chú §7 cho Claude Design như đã sửa, hay Liam muốn đổi trước.

Chưa commit gì. File này đã được auditor độc lập kiểm lại 12/10 (xem báo cáo của auditor).
