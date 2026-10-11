Trạng thái: ĐÃ ÁP SỬA (11/10) — chờ Liam trả lời 2 câu OPEN rồi khoá

> **QUYẾT ĐỊNH LIAM SAU REVIEW (11/10):** Q1 BỎ `tithepurse` · Q2 trần nhân G tính theo từng Axie, chỉ áp mặt sát
> thương (đúng code `oc`) · Q3 pact "mỗi PACT một lần/run" (không phải mỗi nhóm) · Q4 `linkstone` dùng điều kiện kề
> nhau cố định · Q5 giữ −Max HP ở event `gamble_legend`/`bet_small` · Q6 **KHÔNG** thêm trần mềm cho sát thương cộng
> thẳng. Chưa trả lời: đưa nguồn reroll không phải relic (thẻ thưởng, shop, event) vào loại trừ với `twinfates`.

## TRẠNG THÁI SAU KHI ÁP (11/10)

Bộ relic sau sửa: **133 relic** (117 passive + 16 active), 44 mới. Rarity C 26 · R 31 · E 51 · L 25. Economy layer 3. Đã đối chiếu số đếm, xem `relic-set-v2.md` §0. Tiêu đề bên dưới giữ "134" là số của bản được review.

| # | Sev | Trạng thái | Đã làm ở đâu / lý do |
|---|---|---|---|
| F-01 | BLOCKER | FIXED | Bỏ `tithepurse` (Q1, không thay). `merchantscale` làm lại: shop 3 relic, không đổi giá/giá bán. `fortuneledger` chỉ là sink 25. Luật "economy không đổi dòng tiền", H8 bỏ `price_mod`/`income_mod`, R14 mới. Set §1.5, §3.7 |
| F-02 | BLOCKER | FIXED | G theo từng Axie, chỉ mặt dmg (Q2), `axie_g_bonus` thay nhân `oc` trên mặt dmg. Ví dụ 3 viết lại. Set §3.2–§3.4, §3.8, R1. Phần nhỏ chưa quyết: trần ×2.0 cho mặt phi sát thương (OPEN, set §7 câu 16) |
| F-03 | BLOCKER | FIXED | H1 tách: `on_roll_end` một lần/lượt; `on_roll_settled` stateless sau roll và mỗi reroll. Vẫn 8 hook (H1 đã có hai điểm vào). `keeneye`, `linkstone`, `tithepips` sang settled. R15. Set §5 |
| F-04 | MAJOR | FIXED một phần + OPEN | Danh sách relic loại trừ đủ, hai chiều, hard exclude (§4.2 mục 6). **OPEN:** thẻ `reroll`, shop `reroll`, event `bless_reroll`, `curse` chưa áp, cần Liam (set §7 câu 15) |
| F-05 | MAJOR | FIXED | Một hàm `is_wounded(tgt, threshold)`; `dawnlance` dùng `not is_wounded`. Set §3.5, §5 |
| F-06 | MAJOR | FIXED | Ghi reroll thẻ đã có (`reroll_pending_rewards`); `fortuneledger` = +1 charge tốn 25; A10 không offer (set §1.5, ascension §3.1) |
| F-07 | MAJOR | FIXED | Mỗi PACT một lần/run (Q3). Thuật toán bốc 3 pact, xử lý <3 nhóm/<3 pact. Set §4.4, §4.2 mục 5, R16; ascension §3.1/§5 |
| F-08 | MAJOR | FIXED | Bảng luật ô đầy: relic nhân phải bán cùng ô nhân; pact ép → hộp bán bắt buộc, chỉ bán không-Eternal; `ironvow` ô A; bán pact không trả nhóm (vẫn tính đã dùng). Set §3.1 |
| F-09 | MAJOR | FIXED | Mọi state relic vào `_state_dict`/`from_data`; liệt kê state; R13. Set §5 |
| F-10 | MAJOR | FIXED | Action mới: `reorder_party`, `sell_relic`, `loaded_pick`, `hold_pick`, `swap_on_full`, `tweak`; tamper test. Set §5 |
| F-11 | MAJOR | FIXED | `linkstone` tĩnh (Q4), khác LINK gốc, ghi rõ; `symmetrycharm` định nghĩa "cùng loại" và chết/đã dùng. Set §1.5 |
| F-12 | MAJOR | FIXED (không thêm trần, theo Q6) | Không cap. Thêm sim A+ và đặt cộng phẳng làm ưu tiên sim số 1 (set §6.1, §6.5 mục 0). Liam xét lại nếu sim cho thấy trần G thành trang trí |
| F-13 | MINOR | ACCEPTED-DEFERRED | `fumeblossom`: sức mạnh thật (Plague Lord cho 2 status) chỉ biết được bằng sim; đã có trong §6.5 mục 4 và cap 30 stack (R11). Không sửa số khi chưa có sim |
| F-14 | MINOR | FIXED | R9 đếm theo layer, `scaling` tính cho enabler hoặc payoff (set §6.4) |
| F-15 | MINOR | FIXED | `breakersward` chỉ hưởng Shield bị phá; gate: cần `talonedge` hoặc `a_pinning` (set §1.5, §4.2 mục 4) |
| F-16 | MINOR | ACCEPTED-DEFERRED | Ba relic cùng cho "Pierce bỏ qua Thorns" là có chủ ý (dư khi có `worldpiercer`, vẫn có ích khi chưa có). Không phải subset thuần nên không vào `exSub`. Xem lại nếu sim thấy dead-draw |
| F-17 | MINOR | FIXED + OPEN nhỏ | Quy ước "sau mọi mod, Mana = 0", `ear`/`tidecaller` `m=1`. **Chưa kiểm:** boss có miễn nhiễm stun không (ghi vào "chưa kiểm" của set §0) |
| F-18 | MINOR | ACCEPTED-DEFERRED | Công thức A3 đã sàn 0 sau khi cộng relic; mức yếu đi của `bloodpact` phụ thuộc số reroll gốc thật sau meta (chưa kiểm). Đo ở sim ladder của ascension |
| F-19 | MINOR | FIXED | Bảng §4.1 thêm `bet_small`, `gamble_legend`, chest gồm L; Q5: giữ −Max HP của event (set §4.1) |
| F-20 | MINOR | FIXED | `alphafang` chỉ tính kill do mặt Axie Beast; `on_kill` ctx thêm `killer` (set §1.5, §5) |
| F-21 | MINOR | FIXED | `scavengereye`: Treasure có thêm 1 thẻ relic (set §1.5) |
| F-22 | MINOR | FIXED | Trần Reroll nhận từ relic ≤4/lượt (`relic_reroll_cap`, núm). Giá trị 4 là đoán đầu, sim chỉnh (set §3.6, §6.3) |

**Còn cần Liam (OPEN):** (1) F-04: nguồn reroll không phải relic có vào loại trừ với `twinfates` không (đề xuất: có). (2) F-02 phần nhỏ: chặn ×2.0 cho mặt Shield/Heal/Mana nhân từ ascend/forge không (đề xuất: có, nhưng Liam chỉ quyết trần cho mặt dmg).

# Review độc lập: relic-set-v2 (134 relic)

Reviewer: game-designer · 11/10/2026. Đọc: `relic-set-v2.md`, `relic-audit-research.md`, `ascension-v2.md`, đầu `core-loop-v2.md`, và code `RunState.gd`, `reward_generator.gd`, `combat_engine.gd`, `damage_pipeline.gd`, `status_engine.gd`, `relic_hooks.gd`, `rng.gd`, `t_rules_version.gd`. Không chạy sim. Không đọc hết `.tres` từng relic (xem mục "Chưa kiểm").

## 1. Verdict: LOCK AFTER FIXES

Bộ relic sạch về số đếm và id (mục 3 đều khớp). Cấu trúc tốt. Nhưng có 3 chỗ mà nếu khoá và code đúng như đang viết thì ra kết quả sai hoặc phạm quyết định của Liam. Cả 3 sửa bằng vài dòng spec, không cần thiết kế lại. Tổng: 3 BLOCKER, 9 MAJOR, 8 MINOR.

## 2. Bảng phát hiện

| # | Sev | Relic / chỗ | Vấn đề | Bằng chứng | Đề xuất sửa |
|---|---|---|---|---|---|
| F-01 | BLOCKER | `tithepurse`, `merchantscale`, `fortuneledger`, R6, §3.7 | Quyết định 11 (header set) nói tiền in-run **là** Gene Shard. Code đúng vậy: `shards_this_run` được `MetaState.add_shards()` bank khi `end_run`. Vậy `tithepurse` (+20% tiền sau trận) là faucet Gene Shard meta, trái quyết định audit Q8 "không bao giờ cho Gene Shard", trái §3.7, và R6 (so meta save trước/sau) sẽ fail ngay. `merchantscale` (giá −15%, bán 60%) và `fortuneledger` đổi lượng Shard dư được bank, gián tiếp. Gene Shard có sink thật (Echo Box, cược nhiệm vụ) nên +20% là chạm economy toàn game | `RunState.gd:35,386,447,783-787`; set header dòng 8 vs §3.7 và R6; audit Q8 | Hỏi Liam (Q1). Đề xuất: bỏ `tithepurse`, thay bằng relic không chạm tiền (xem Q1). Nếu giữ thì economy-designer duyệt và sửa R6/§3.7 thành "không cộng Shard ngoài đường income trong run" |
| F-02 | BLOCKER | `ascend`, `forge`, §3.3, ví dụ 3, R1 | Set coi `ascend`/`forge` là nguồn +0,25 / +0,30 toàn đội trong trục G. Code: cả hai là mutation `oc` trên **một Axie** (ascend do người chơi chọn, forge chọn ngẫu nhiên), nhân `ceil(v*mult)` lúc dựng die trên **mọi mặt có giá trị** (cả Shield/Heal/Mana), cộng thêm +6 Max HP cho ascend, và nhân dồn (1,25^n). Còn G của set chạy trong pipeline `dmgMult` và chỉ cho mặt dmg. Không thể cùng một trần ×2,5 nếu không quyết: theo Axie hay toàn đội, chỉ dmg hay mọi mặt. Ví dụ 3 (G = 2,10 với 2 lần ascend) sai vì ascend không đi vào mọi Axie | `RunState.gd:607-616,731-738`; `damage_pipeline.gd:51-53`; set §3.3, §3.8 | Hỏi Liam (Q2). Đề xuất: G tính **theo từng Axie**: `G_axie = min(2.5, 1 + Σ relic G + 0.25×ascend_axie + 0.30×forge_axie)`, chỉ cho mặt dmg; mặt Shield/Heal/Mana giữ nhân `oc` cũ nhưng chặn ×2,0. Viết lại ví dụ 3 |
| F-03 | BLOCKER | H1, `quickenroot`, `keeneye`, `claw`, `symmetrycharm` | H1 nói sau mỗi reroll "mọi hook ROLL-END chạy lại". `quickenroot` cộng +1 growth vĩnh viễn mỗi lần `on_roll_end` chạy, cho mọi Axie đang sống. Vậy mỗi reroll (kể cả reroll 1 die) cho +1 growth cho cả 5 Axie. Với `infinitedie`, `a_chaos`, `devilsreroll`, hoàn Reroll thì growth nhân lên theo số reroll. Đây là bug do spec | `relic_hooks.gd:734-749` (quickenroot, không idempotent); `combat_engine.gd:379,452-486` | Tách hai loại: `on_roll_end` giữ nguyên (chỉ sau roll đầu lượt); thêm `on_roll_settled` (sau roll và mỗi reroll) chỉ dành cho relic tính lại không có state: `claw`, `symmetrycharm`, `keeneye`. Ghi rõ trong H1 |
| F-04 | MAJOR | `twinfates`, §4.2/§4.3, quyết định 13 | Liam duyệt "twinfates vào danh sách không đưa ra khi đang giữ". Set mới chỉ hạ `m=1` một chiều (đang giữ twinfates thì relic Reroll `m=1`), không hề có trong §4.2 (loại cứng). Danh sách cũng thiếu: `cullingorder`, `apexpredator`, `alphafang`, `a_chaos`, class Aqua CONDUIT (4 Mana = 1 Reroll), thẻ reward `reroll`, shop item `reroll`, event `bless_reroll`, `curse` (+1 reroll). Chiều ngược (đang giữ reroll relic rồi mới ra twinfates) không xử lý | `reward_generator.gd:127-128`; `RunState.gd:625-626,700-702,797-798`; set §4.2, §4.3 | Thêm vào §4.2: không offer `twinfates` khi đang giữ nhóm nguồn Reroll (liệt kê đủ ở mục 5), và ngược lại không offer nhóm đó khi giữ `twinfates`; bỏ thẻ `reroll` khỏi pool khi giữ `twinfates` |
| F-05 | MAJOR | `carrioncall`, `dawnlance`, `scentofblood`, `deathspiral`, FERAL | Điều kiện "wounded" hiện là `tgt.hp < max_hp*0.5` viết thẳng trong pipeline. `carrioncall` coi địch ≥5 Poison là "dưới 50%". `dawnlance` cần "trên 50%". Địch đầy máu có 5 Poison vừa wounded vừa không: được ×1,9 opener và ×1,6 FERAL và +4 Scent cùng lúc | `damage_pipeline.gd:46-48`; set dòng 175, 109 | Một hàm `is_wounded(tgt)` duy nhất; `dawnlance` dùng `not is_wounded`. Ghi vào bảng 3.5 |
| F-06 | MAJOR | Ascension A10 + `fortuneledger` | A10 "không còn reroll reward" làm `fortuneledger` vô dụng hoàn toàn. Ascension doc nói "không relic nào bị đòi/ảnh hưởng" nhưng bỏ sót. Ngoài ra reroll reward **đã có sẵn** (`reroll_pending_rewards`, `reward_reroll_max` = 1 từ meta), nên Q12 "thêm nút reroll" và ghi chú "hiện chưa chắc có" lệch thực tế: `fortuneledger` thật ra là +1 charge trả tiền | `RunState.gd:565-574,71`; ascension §2.1 A10 | A10: không offer `fortuneledger`. Sửa mô tả: "thêm 1 charge reroll reward, tốn 25". UI nút reroll đã có, chỉ cần hiện thêm charge |
| F-07 | MAJOR | Pact ở boss, Ascension A6/A10 | Chọn theo nhóm drawback, mỗi nhóm 1 lần/run: boss 1 chọn 1/3, boss 2 chỉ còn 2 nhóm, boss 3 còn 1 nhóm (không có lựa chọn). A10 bắt buộc pact ở mọi boss nên boss 3 là pact ép, có thể là cái giết build (twinfates với build Reroll). Ascension doc nói "luôn còn một pact hợp lệ" nhưng bỏ qua điều này. Thêm: nhóm Mana chỉ 2 pact, nhóm Dice 4, nên mỗi pact Mana hiện nhiều gấp 2 lần pact Dice | set §4.4; ascension §2.1, §5.5 | Quyết ở Q3. Đề xuất: chỉ "mỗi relic một lần", không "mỗi nhóm một lần"; ba thẻ chọn từ 3 nhóm khác nhau khi còn đủ nhóm, nếu thiếu thì lấy nhóm đã dùng. Pact chọn trong nhóm theo trọng số đều theo pact, không theo nhóm |
| F-08 | MAJOR | Luồng ô đầy / pact bắt buộc | Chưa định nghĩa: (a) relic nhân khi ô G/A đầy: bán relic nào mới được? §4.2 chỉ `m=1`, ví dụ 1 lại nói "bị chặn"; (b) pact ép (A6/A10) khi 7 ô passive đầy: có hộp bán bắt buộc không cho hủy? (c) pact `ironvow` chiếm ô A nhưng luật `m=1` của pact chỉ nhắc ô G; (d) bán pact có "trả lại" nhóm drawback không | set §3.1, §4.3, §4.4, ví dụ 1; ascension §5.5 | Viết một bảng luật: relic nhân vào được nếu bán một relic cùng ô nhân; pact ép khi đầy → hộp bán bắt buộc, chỉ bán được relic không-Eternal; bán pact không trả nhóm (nhóm vẫn tính đã dùng) |
| F-09 | MAJOR | Save / undo / replay | Có undo miễn phí trong lượt (`_push_undo`, snapshot `_state_dict`). Mọi trạng thái mới (ngân sách Tweak, bộ đếm `mana_spent` đã thưởng, hoàn Reroll/lượt, ramp `crescendofang`, `tideglass`, bank `amberdie`, `relic_state` theo trận) mà không nằm trong `_state_dict`/`from_data` sẽ: hoặc cho tweak/thưởng vô hạn qua undo, hoặc mất khi save-resume giữa trận. Ví dụ: tiêu Mana nhận Shield, undo trả Mana, lặp lại | `combat_engine.gd:189-232,689-703` | Thêm vào §5: "mọi state mới của relic phải nằm trong `_state_dict` và test undo/resume cho từng hook". R mới: R13 undo không tăng ngân sách |
| F-10 | MAJOR | Action mới thiếu trong ActionLog | §5 chỉ ghi tweak/hold. Chưa ghi: đổi thứ tự đội ở Map (ảnh hưởng LINK và 5 relic positional nên verifier phải biết), bán relic, chọn mặt khoá của `loadeddie`, chọn die hold của `amberdie`, nhận pact / bán đổi khi đầy | `RunState.gd` đã có `action_log.record` cho `shop_buy`, `take_reward`, `reroll_rewards`; set §5 H7 | Liệt kê action mới: `reorder_party`, `sell_relic`, `loaded_pick`, `hold_pick`, `swap_on_full`; `RunVerifier` và test tamper cho từng cái. Vẫn trong một lần bump |
| F-11 | MAJOR | `linkstone`, `symmetrycharm`, §3.5 LINK | Set mô tả LINK là "hai Axie kề cùng loại mặt" (trạng thái tĩnh). Code: LINK là sự kiện lúc dùng mặt: Axie dùng đầu ghi vào `resonance_log`, Axie kề dùng sau cùng loại mới ăn ×1,15; loại tính: dmg, shield, heal, poison, mana; token (Egg) bị loại. `linkstone` "mỗi Axie đang trong cặp LINK" không xác định được lúc BUILD/AGG; người dùng đầu cặp chưa biết mình trong cặp | `combat_engine.gd:34-35,714-745,751-775` | Hai lựa chọn: (a) `linkstone` kích lúc dùng, thưởng cho cả Axie ghi và Axie ăn; (b) đổi sang điều kiện tĩnh "hai Axie kề đang hiện cùng loại mặt" và dùng định nghĩa này luôn cho `symmetrycharm`. Đề xuất (b), ghi rõ là khác LINK gốc |
| F-12 | MAJOR | Cộng phẳng không có trần | Trần ×2,5 chỉ chặn nhân. Cộng phẳng lên mọi mặt dmg không giới hạn: `brittledice` +4, `patientfang` đến +14, `bookend` +3, `tideglass` +6, `heirloom` +5, `towershield` +6, `soulforge` +6, `deathmark` không trần/trận, `claw` +4, `symmetrycharm` +3, `relaybaton` cộng dồn. Một build đủ 5-6 cái này cộng +25-35 trên mỗi mặt, lớn hơn mọi chuyện nhân. Trần G thành trang trí. Thêm: `echostone` ×2 mặt đầu nhân luôn các số này | set §3.2, §6.2 | Ghi vào kế hoạch sim: đo "dmg phẳng cộng từ relic" và đặt trần mềm (ví dụ tổng cộng phẳng từ relic/mặt ≤ +16, trừ `patientfang` thay thế). Đây là núm đầu tiên cần |
| F-13 | MINOR | `fumeblossom` | Legendary nhưng chỉ +1 Poison và +1 Burn mỗi địch mỗi lượt. Yếu hơn `a_plague` (Poison 3). Đồng thời §6.5 mục 4 coi là "vòng khuếch đại". Mâu thuẫn. Thực chất cộng 1 stack/lượt cân bằng với decay −1, nên nó là Plague Lord cho cả hai status (không giảm) | set dòng 164, §6.5 | Hạ Epic hoặc tăng lên +2 và cho tối đa 1 lần/địch/lượt; sửa mô tả combo, bỏ khỏi danh sách rủi ro vượt trần |
| F-14 | MINOR | `crescendofang` | Layer `scaling` nhưng bảng 2.1 xếp vào cột enabler; exec chỉ có 1 enabler thật (`gorehook`) nếu đếm theo layer, R9 fail | set dòng 228, 282 | Đổi layer thành enabler, hoặc R9 ghi "scaling đếm cho enabler hoặc payoff". Cách sau đơn giản hơn |
| F-15 | MINOR | `breakersward`, `talonedge` | Không rõ `breakersward` tự phá Shield hay cần `talonedge`. Nếu tự phá thì phần phá Shield của `talonedge` là tập con; nếu cần `talonedge` thì là dead-draw khi thiếu | set dòng 127, 169 | Ghi rõ: `breakersward` chỉ hưởng Shield bị phá, nguồn phá là `talonedge`/`a_pinning`; thêm gate offer (cần `talonedge` hoặc `a_pinning`) hoặc cho tự phá |
| F-16 | MINOR | `falconhood`, `hollowbone`, `worldpiercer` | Cùng ba relic cho "Pierce bỏ qua Thorns". Nửa của `falconhood` và nửa của `hollowbone` thừa khi có `worldpiercer`. Không phải subset thuần nên không vào `exSub` | set dòng 101, 134, 186 | Chấp nhận và ghi là có chủ ý, hoặc đổi nửa còn lại của `falconhood` |
| F-17 | MINOR | `hollowchalice` | "Mặt Mana cho 0": không rõ mod cộng (`ear`, Aqua CONDUIT +1, `tidecaller` +1) có thành 1 hay vẫn 0. `ear`, `tidecaller` là dead-draw khi có chalice. Ngoài ra Mana rẻ + `a_freeze` 2MP cho phép stun boss mỗi lượt; `play_active` không thấy miễn nhiễm boss | `combat_engine.gd:567-571,792-793`; set dòng 194 | Quy ước "sau mọi mod, mặt Mana = 0". Thêm `ear`/`tidecaller` vào dead-draw `m=1`. Kiểm miễn nhiễm stun của boss (chưa kiểm) |
| F-18 | MINOR | A3 + `bloodpact` | Công thức A3 `max(1, base−1)` rồi cộng `−2` sàn 0: drawback của `bloodpact` giảm từ mất 2 xuống mất 1 reroll ở A3+. Pact yếu đi đúng khi game khó hơn | ascension §2.3 | Tính `bloodpact`/sàn 0 sau cùng: `max(0, base + Σ − 1)` hoặc ghi chấp nhận |
| F-19 | MINOR | Bảng §4.1 | "Band hôm nay" của event `chest` ghi R,E nhưng code `pick_relic(1,3)` gồm cả Legendary; `bet_small` (E,L, tung đồng xu, −10% Max HP khi thua) và `gamble_legend` (−20% Max HP) không có trong bảng. Hai event còn lại đụng Max HP, trái tinh thần quyết định pact không HP (nhưng giữ như cũ) | `RunState.gd:703-721,743-753` | Ghi đủ vào §4.1; hỏi Liam có giữ phạt Max HP của event không (Q5) |
| F-20 | MINOR | `alphafang`, KILL | `on_kill` chỉ nhận `tgt`, không biết ai giết. "Axie Beast kill" cần thêm `killer`; kill bằng tick/thorns/relic không có killer | `damage_pipeline.gd:210-215` | Ghi: chỉ tính kill bằng mặt của Axie Beast; mở rộng ctx với `killer` |
| F-21 | MINOR | `scavengereye` | "Treasure chọn 1 trong 2 relic": Treasure hiện là reward tier 1 nhiều loại thẻ, không phải thẻ relic | `RunState.gd:547-548` | Viết lại: Treasure có thêm 1 thẻ relic, hoặc đổi sang +1 thẻ như Battle |
| F-22 | MINOR | `cullingorder`, `apexpredator`, `alphafang` | Ba nguồn hoàn Reroll, mỗi cái "tối đa 2/lượt", không có trần chung (chỉ `a_chaos` có trần 6). Cộng `tidecaller` và `infinitedie` | set dòng 133, 136, 182 | Trần chung "Reroll nhận từ relic ≤ 4/lượt" (núm) |

(Ghi chú: Execute và FERAL không nhân dồn: pipeline dùng một ×1,6 cho `beast or exec`. Đã kiểm nên không đưa vào bảng.)

## 3. Kiểm số đếm: tất cả khớp

| Mục | Set ghi | Đếm lại | Kết quả |
|---|---|---|---|
| Tổng | 134 (118 + 16) | 52 + 19 + 2 + 45 + 16 = 134 | OK |
| Rarity | C27 R31 E51 L25 | C 8+10+7+2=27; R 14+1+10+6=31; E 15+5+1+24+6=51; L 15+4+4+2=25 | OK |
| Layer | 32/23/7/14/9/12/6/5/6/4/16 | enabler 32, payoff 23, scaling 7, engine 14, pact 9, duo 12, dice 6, pos 5, class 6, econ 4, active 16 | OK |
| Mới | 45 = 12+6+8+6+5+3+4+1 | đếm bảng 1.5 | OK |
| Tag (cả active) | exec11 shield17 pierce11 mana16 thorns12 summon9 growth11 poison11 crit9 aoe9 burn9 uni26 class6 | đếm từng tag | OK (số này đã gồm 16 active) |
| Id cũ | 94 − 6 + festermark = 89 | 52+19+1 (infinitedie)+16 active = 88 + festermark | OK, 6 id mất đúng: rotbite tinderbox openwound voidgene spines swarmnest |
| Mất id thầm lặng | không | đối chiếu 78 passive cũ với 52+19+merge | Không mất id nào |
| Duo | cặp tag khớp archetype | 12 cặp bảng 2.3 = bảng 1.5; mỗi archetype ≥2 duo | OK |
| 2 tag tối đa | | không relic nào 3 tag | OK |
| Hook | trigger dùng H1..H8 | không thấy relic dùng hook ngoài danh sách | OK |
| Rework R→C | 6 relic | đúng 6 (ear gustwing heart talonedge eggshell luckycharm); `claw`,`carapace`,`cleaveall`,`barbedhide` vốn là C | OK |

Ghi chú nhỏ: header ghi "Giữ nguyên 68 (52 passive + 16 active)" và cũng "Mới 45" cộng `festermark` nằm ở 1.4 (không tính trong 45). Nhất quán.

## 4. Tuân thủ quyết định Liam

| Mục | Kết quả |
|---|---|
| Chạm HP carry | Không. HP phẳng nhỏ còn lại (`growthcore` +2, `bloodmouth` +2, `heart` +8) không phá luật hồi đầy |
| Enemy counter-trait | Không. Boss Clock của Ascension là đồng hồ |
| Phụ thuộc Chimera/roster | Không |
| Gene Shard | Vi phạm gián tiếp: F-01 |
| ≤2 tag | OK |
| Ô nhân | `ironvow` chiếm ô A nhưng luật `m=1` của pact chỉ nhắc ô G (F-08); `ascend`/`forge` xem F-02 |
| Pact không HP | OK |
| Quyết định 13 (twinfates) | Làm một nửa: F-04 |
| Quyết định 12 (reroll reward) | Lệch thực tế: F-06 |

## 5. Danh sách "không đưa ra khi đang giữ" đầy đủ đề xuất

- `twinfates` <-> mọi nguồn Reroll: `tidalbrand`, `infinitedie`, `tidecaller`, `devilsreroll`, `cullingorder`, `apexpredator`, `alphafang`, `a_chaos`; thẻ reward `reroll`; shop `reroll`; event `bless_reroll`; Aqua CONDUIT chỉ là cảnh báo UI (class không đổi được).
- `twinfates` <-> `devilsreroll` (khác nhóm nên cùng xuất hiện được: chết).
- `hollowchalice` -> `ear`, `tidecaller` (`m=1`).
- A10 -> `fortuneledger` (không offer).
- `exSub` giữ 3 cặp cũ (`pierceall`<`worldpiercer`, `gorehook`<`apexferal`, `windlash`<`stormcall`).

## 6. Rủi ro cân bằng cho sim đầu tiên (thứ tự)

1. Tổng cộng phẳng trên mỗi mặt dmg (F-12). Đo phân phối, đặt trần mềm.
2. `patientfang` (+14 ở lượt 8, lượt 1 = 0): dài trận thì rất mạnh, trận 2-3 lượt thì là relic chết. Cần độ dài trận thật theo node.
3. `twinfates`: roll 2 giữ cao hơn cho cả 5 Axie, mất hết Reroll. Kỳ vọng mạnh hơn mọi pact còn lại. Đo pick rate.
4. `lonewolf` + `bloodpact` đều G; `lonewolf` +100% chỉ slot 1 nên với ascend/forge trên cùng Axie đạt trần nhanh.
5. `tithepips`/`manaspring`/`conduitcrown` + `hollowchalice` + `a_freeze`: stun boss mỗi lượt (F-17).
6. Reroll nhận từ relic (F-22) + `devilsreroll` + `a_chaos` (cap 6 chỉ cho chaos).
7. Ba relic đếm `mana_spent` (`aegiscapacitor`, `wellspringroots`, `tideglass`) + `tidecaller`: chỉ cần 1 mốc rẻ đã chạy đủ ba.
8. `relaybaton` cộng dồn + `echostone` ×2 mặt đầu + G: đỉnh một mặt.
9. `coupmark` (chết ngay ≤25% Max HP khi crit) + `apexferal` (≤15%): xem boss có miễn nhiễm chết ngay không (chưa kiểm).
10. `scavengereye` + `fortuneledger`: số lần xem offer nhân lean.
11. `carrioncall` + FERAL/`scentofblood`/`deathspiral` sau khi sửa F-05.
12. Economy: sau khi quyết F-01, chạy sim D.
13. Pick rate pact theo nhóm không so sánh được vì số pact mỗi nhóm khác nhau (F-07).

Archetype còn mỏng payoff: growth (cả hai payoff đều `scaling`, không payoff đòn lớn nào ngoài engine `worldtree`); exec chỉ 1 enabler thật. Chưa kết luận, chờ sim reach.

## 7. Rủi ro triển khai khác

- `RULES_VERSION`: `t_rules_version` theo dõi cả `res://scripts/core` và `res://autoload`, nên `ContentDB.gd` đã nằm trong dấu vân tay (trả lời câu "chưa verify" của Ascension). Một lần bump vẫn đủ nếu F-03 và F-10 xử lý trong cùng đợt.
- `offer_seed`: code hiện đã dùng `Rng.derive_combat_seed(run_seed, node_id, salt)` với salt tăng khi reroll; nên dùng đúng đường này thay vì hàm hash mới.
- Thẻ reward hiện là thẻ có kiểu (`relic`, `level`, `ascend`, `hp`, `reroll`, `chaos`, `curse`), số thẻ relic mỗi lần thay đổi; "thẻ dẫn = thẻ relic đầu tiên" vẫn dùng được nhưng phải test trường hợp 0 thẻ relic.
- `twinfates`: mỗi Axie 2 lần bốc RNG; `loadeddie` trọng số; `amberdie` bỏ qua 1 lần bốc. Tất định nhưng phải có test replay cho từng cái.
- Thứ tự "theo thứ tự nhận" của H3 cần `owned_relic_ids` giữ thứ tự khi bán/đổi (bán rồi nhận lại).
- UI thiếu mockup: nút bán, hộp bán bắt buộc khi đầy, chọn Tweak, reorder ở Map, hiện ô nhân đầy, sticker Eternal, hiện charge reroll reward thêm, chọn mặt khoá `loadeddie`, chọn die hold `amberdie`. Cần request cho Claude Design.

## 8. Chưa kiểm

- Giá trị mặt dmg gốc của từng part (để định cỡ cộng phẳng ở F-12 thành số cụ thể).
- Boss có miễn nhiễm stun / chết ngay hay không.
- Nội dung từng file `.tres` của 52 relic giữ nguyên (chỉ đối chiếu với bảng audit).
- Số reroll gốc thật sau meta unlock, và độ dài trận trung bình theo loại node.
- UI hiện tại của màn reward (nút reroll đã có ở mức nào).
- Số boss trong run short (ảnh hưởng F-07).

## 9. Sửa cơ học đã áp dụng vào relic-set-v2.md

Một sửa duy nhất, SỬA REVIEW 11/10: `relic-set-v2.md` §4.2 thêm mục 6 (twinfates và relic cộng Reroll loại nhau trong offer, theo quyết định 13 của Liam, bản gốc chỉ có `m=1` một chiều ở §4.3). Không sửa số đếm nào vì mục 3 khớp hết. Các thẻ reward `reroll`, shop `reroll`, event `bless_reroll` chưa thêm vì cần Liam duyệt (F-04).

## 10. Câu hỏi cho Liam (chỉ câu thật)

| # | Câu hỏi | Đề xuất |
|---|---|---|
| Q1 | Tiền in-run là Gene Shard và được bank. `tithepurse` +20% thành faucet Shard meta, trái quyết định "không bao giờ cho Shard". Bỏ, đổi, hay giữ và nhờ economy-designer? | Bỏ `tithepurse`, thay bằng relic không chạm tiền (ví dụ "mỗi shop có 1 món giảm nửa giá" cũng chạm tiền nên không; chọn relic reroll shop). Nếu giữ thì chỉ khi economy-designer duyệt và sửa R6 |
| Q2 | `ascend`/`forge` là mutation một Axie, mọi mặt. Trần G tính theo Axie và chỉ cho mặt dmg? Mặt Shield/Heal/Mana giữ nhân cũ? | Theo Axie; dmg vào G, các mặt khác giữ `oc` nhưng chặn ×2,0 |
| Q3 | Pact "mỗi nhóm một lần" làm lựa chọn co từ 3 → 2 → 1, và A10 ép pact không có lựa chọn ở boss 3. Đổi thành "mỗi relic một lần"? | Có |
| Q4 | `linkstone`: dùng điều kiện tĩnh (hai Axie kề đang hiện cùng loại mặt) thay vì LINK lúc dùng? | Tĩnh, và ghi rõ khác LINK gốc |
| Q5 | Event `gamble_legend`/`bet_small` còn phạt Max HP. Giữ (đã duyệt "giữ như cũ") hay bỏ phạt cho khớp tinh thần pact không HP? | Giữ, vì Liam đã chọn "giữ"; chỉ ghi lại trong §4.1 |
| Q6 | Trần cộng phẳng từ relic mỗi mặt (F-12): đồng ý thêm một núm trần mềm trước sim? | Đồng ý, mặc định +16 chưa tính `patientfang` |
