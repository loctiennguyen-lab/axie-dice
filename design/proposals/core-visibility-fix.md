# Lõi ít hiện / không fire: nguyên nhân và cách sửa

Ngày 21/10/2026. Người viết: systems-designer. Chưa sửa code, chưa commit. Chờ Liam duyệt trước khi làm.

Nguồn số liệu: `production/qa/sim/sim-2026-10-20-new_final_A0.md` (8000 run, cột offered/picked/fired là % run), `production/qa/sim/combo-draw-sim.md` (5000 run Short, "shown per 100 runs"), và code `core_offer.gd`, `core_hooks.gd`, `relic_hooks.gd`, `RunState.gd`, `combat_engine.gd`, `sim_balance.gd`. Mình không chạy được sim trong lượt này nên mọi con số "sau sửa" là ước tính từ mô hình bên dưới, sim phải xác nhận.

## 0. Nguyên nhân chính (đọc cái này trước)

**A. Ít hiện: cách rút thẻ làm loãng các Lõi trục `dice`.**
`build_offer` chọn TRỤC trước (ngẫu nhiên đều giữa các trục còn lại), rồi mới chọn Lõi đều trong ô (trục, bậc). Không có trọng số Lõi nào ở đây. (`RelicDef.weight` chỉ Run Rule dùng.) Kết quả: mỗi lần mở bộ 3 thẻ, trục `dice` chỉ hiện trung bình khoảng 0.46 thẻ, bất kể trong trục có 2 hay 7 Lõi. Chuỗi bậc cho trung bình 1.5 lượt chọn bậc Amber và 1.15 lượt chọn bậc Crystal mỗi run (Short). Vậy "khối lượng hiện" của một ô là cố định:

| Ô (trục, bậc) | Số Lõi hợp lệ | Khối lượng ≈ | Trung bình mỗi Lõi | Đo được |
|---|---|---|---|---|
| dice Amber | 7 | 0.46 × 1.5 = ~69% | 9.9% (chưa tính cổng) | tổng đo 69.3, mỗi Lõi 7.4-11.3 |
| dice Crystal | 6 | 0.46 × 1.15 = ~53% | 8.8% | tổng đo 52.9, mỗi Lõi 6.5-10.3 |
| rule Crystal | 5 | ~60-65% | 12-13% | tổng đo 59.4, mỗi Lõi 9.1-14.0 |
| pos Crystal | 3 | | | tổng đo 45.1 (open_ranks kéo xuống) |

Hệ quả cứng: **ô dice Crystal (6 Lõi) và dice Amber (7 Lõi) không thể cho mọi Lõi đạt ≥10% run chỉ bằng chỉnh trọng số**, vì tổng khối lượng chia cho số Lõi đã dưới 10%. Cần đổi cách rút trục hoặc giảm số Lõi trong ô.

**B. Lõi có cổng (requires) chịu thêm một cú trừ.** Cổng `face:poison`, `class_pair`, `owned_tag:front`, `egg_source` chỉ đúng với một phần đội/run. Đo được: Lõi dice Amber có cổng poison hiện 7.4-7.5% so với 10.3-11.3% của Lõi không cổng cùng ô, tức cổng poison đúng khoảng 70% (đúng với 5/7 đội mẫu của sim).

**C. "DEAD" của fossil, dim_stone, steady_hold là sim đếm sai, không phải Lõi hỏng.** Cả ba có đường fire thật và test `t_core_fires` đã chứng minh (xem mục 1). Sim chỉ ghi "fired" cho Lõi đang nằm trong `owned` lúc hết trận (`_note_triggers(eng, owned_snap)`), và bot không bao giờ dùng Hold.

## 1. Từng Lõi: vì sao

| Lõi | Ô | Đo (offered / picked / fired) | Nguyên nhân |
|---|---|---|---|
| c_fissure | dice Amber | 7.5 / 3.7 / 3.1 | Ô 7 Lõi (nguyên nhân A). Cổng `face:poison\|debuff`: nhãn mặt chỉ lấy `type` và đầu của `keywords`; `debuff` không phải keyword (keyword thật: weaken, vulnerable, blind, freeze, stun, xem `DEBUFF_KW` trong core_hooks.gd) nên nhánh `debuff` gần như không bao giờ đúng, cổng thực chất là `face:poison`. |
| c_plague_spread | dice Amber | 7.4 / 3.7 / 3.2 | Ô 7 Lõi + cổng `face:poison`. |
| c_concord | dice Crystal | 6.6 / 1.6 / 1.6 | Ô 6 Lõi + cổng `class_pair` (đội 5 Axie khác lớp hết thì ẩn; 2/7 đội mẫu như vậy). Chọn rất ít (24% khi hiện). |
| c_toxic_still | dice Crystal | 6.5 / 1.2 / 1.4 | Ô 6 Lõi + cổng poison + excludes `owned:c_field_medic`, `owned:c_cascade`. Chọn 18% khi hiện. |
| c_mirror_face | dice Crystal | 9.3 / 4.4 / 4.6 | Chỉ do ô 6 Lõi (không cổng). Gần ngưỡng, thiếu 0.7 điểm. |
| c_open_ranks | pos Crystal | 4.9 / 1.8 / 1.8 | Cổng `owned_tag:front` (phải đã sở hữu bastion/gatekeeper/growing_shell/thorn_growth trước) + 5 excludes (living_wall, backline_glow, descend, rule_rising_tide, rule_upside_down) + chỉ hiện ở lượt Crystal. Ba điều kiện nhân nhau. |
| c_golden_egg | rule Amber | 9.2 / 8.1 / 4.6 | Cổng `egg_source`: chỉ đúng khi đội có mặt summon/egg, hoặc đang sở hữu Lõi tag `egg`; mà trong `c_*.tres` chỉ `c_nest` mang tag `egg`. Ô rule Amber chỉ có 2 Lõi (golden_egg, dim_stone). Khi hiện thì 88% được chọn (win 47.8%, cao nhất nhóm) nên đây là Lõi người chơi MUỐN mà không gặp. Fired/picked chỉ 57%: fire khi Egg chết, nhiều run Egg không chết. |
| c_blood_sign | rule Crystal | 9.1 / 4.4 / 4.5 | Cổng `face:poison` (70%). Ô 5 Lõi nên chỉ thiếu 0.9 điểm. |
| c_fossil | rule Amber | 33.9 / 5.3 / 0 (DEAD) | Hiện nhiều (33.9%) vì ô rule Amber hay rỗng, rút lùi về rule Moss. Fire thật: `RunState.gd` ~2256 `CoreHooks.fire("c_fossil", -1, n, "tier")`, rồi NGAY SAU ĐÓ `owned_relic_ids.erase("c_fossil")`. Sim kiểm `owned` sau khi nó đã bị xoá nên không bao giờ đếm. Win 0/96 là con số lạ (các Lõi tệ nhất khác 14-24%), nghi lỗi kế toán của sim, cần kiểm. |
| c_dim_stone | rule Amber | 11.3 / 2.0 / 0 (DEAD) | Fire thật ở `RunState.gd` 2364 và 2385 (`"reroll"` / `"tier"`), nhưng thẻ này không bao giờ vào `owned` (được thay bằng Lõi Crystal ban cho), nên sim không đếm được. |
| c_steady_hold | dice Amber | 10.3 / 2.1 / 0 (DEAD) | Fire thật ở `combat_engine.gd` 1418-1420 (`stash`, khi Hold lần 2 hoặc Hold lại die đang mang). Bot tắt Hold nên không bao giờ chạm. Hiện 10.3% nhưng chỉ 20% chọn: Lõi yếu về thiết kế. |

Lõi ngoài danh sách nhưng cùng bệnh, ghi lại để khỏi sót: `c_tidecaller` fired 0% (picked 8.3%; hook `on_reroll_paid` / `on_active_played` có thật, test `t_core_fires` qua, nghi bot ít tiêu mana qua đường này, cần log), `c_kindle` 11% (fire theo `on_stash`, cùng lý do Hold), `rule_tundra` 4% (Hold), `c_key_strike` 3%, `rule_cheap_mana` 22%.

Một điểm lệch số cần giải trước khi tin bảng nào: combo-draw-sim báo `c_toxic_still` hiện 41.9 lần/100 run và `c_three_dice` 29.7, trong khi sim_balance báo 6.5% và 10.3% cho cùng hai Lõi (cùng 7 đội mẫu). Hai thước đo khác nhau (lần hiện kể cả reroll so với % run) nhưng 41.9 lần/100 run mà chỉ 6.5% run thì vô lý. Phải đối chiếu (roster khác, hay đếm trùng) trước khi chốt ngưỡng.

## 2. Đề xuất sửa

Chia làm 3 nhóm. Nhóm S không đụng file luật. Nhóm R đụng file luật.

### Nhóm S: sửa sim (không đụng luật, làm trước)

- **S1. Đếm fire ngoài trận / Lõi tự xoá.** Trong `sim_balance.gd`, cuối mỗi run: với mọi id trong `_core_fired_seen` mà nằm trong `_picked`, đặt `_trig[id] = true`, không cần còn trong `owned`. Sửa luôn fossil và dim_stone. Kỳ vọng: fired/picked của hai Lõi này lên 100%.
- **S2. Bot biết Hold.** Khi sở hữu `c_steady_hold`, `c_kindle` hoặc `rule_tundra`, bot gọi `eng.stash()` lên tới `stash_cap()` (die không dùng được tốt nhất ở cuối lượt). Kỳ vọng: steady_hold, kindle, tundra fired/picked ≥90%.
- **S3. Kiểm tidecaller** bằng cách log tổng mana đã tiêu qua reroll/active mỗi run; nếu bằng 0 thì là bot, nếu >0 mà vẫn không fire thì là bug thật (khi đó báo lại, đây là sửa hook).
- **S4. Sửa cột "win khi có Lõi"** để Lõi tự xoá (fossil) không bị tính sai (0/96 nghi sai).

### Nhóm R: đụng file luật (bump `RULES_VERSION` sau `-r`, cập nhật `SUPPORTED_RULE_VERSIONS`, fingerprint `t_rules_version`, deploy Worker)

Mọi mục dưới đây nằm trong `scripts/core/` hoặc `resources/relics/`, đều trong fingerprint.

- **R1 (khuyến nghị, gốc rễ): trọng số trục theo cỡ ô.** Trong `core_offer.gd`, `_axis_order` đổi hoán vị ngẫu nhiên đều thành hoán vị có trọng số, trọng số trục = `min(số Lõi hợp lệ trong ô, 4)`. Dice Crystal (6 Lõi) có trọng số 4 thay vì 1/6 phần; trục nhỏ (stat 1, rule Amber 2) giảm. Ước tính: P(dice xuất hiện trong bộ 3) từ 0.46 lên ~0.75, mỗi Lõi dice Crystal ~13-15%, dice Amber ~13-14%. Giữ nguyên các luật còn lại (card 1 theo trục đang có, card 2 trục chưa có, tối đa 1 stat, 1 quest, 1 meme). Đây là cách duy nhất làm mọi Lõi dice qua 10% mà không phải xoá Lõi. Rủi ro: dịch chuyển tần suất mọi Lõi (thorn_shield 62% giảm mạnh), nên phải chạy lại cân bằng; seed cũ ra bộ thẻ khác nên test có kỳ vọng cố định về offer sẽ phải sửa.
  - Phương án thay nếu Liam không muốn đổi rút trục: bớt Lõi khỏi ô dice (đưa `c_steady_hold`, `c_field_medic`, `c_whittle` đi chỗ khác hoặc thiết kế lại). Mình không khuyến nghị vì mất nội dung.
- **R2 `c_fissure`:** requires đổi `face:poison|debuff` thành `face:poison|weaken|vulnerable|blind|freeze|stun`. Cổng đúng với đội có debuff thật (ước tính 70% lên ~85-90% đội). Cùng R1: ~12-14%.
- **R3 `c_plague_spread`, `c_toxic_still`, `c_concord`, `c_mirror_face`:** không đổi gì ngoài R1. Nếu sim sau R1 còn dưới 10%, thêm trường trọng số Lõi (R6) đặt 2 cho Lõi bị cổng.
- **R4 `c_open_ranks`:** bỏ `requires owned_tag:front`, giữ 5 excludes. Thêm excludes `owned:c_open_ranks` vào `c_backline_glow` và `c_descend` (hiện chỉ `c_living_wall` có chiều ngược lại, nên nhặt Open Ranks xong vẫn có thể bị đưa Lõi chết). Ước tính 4.9% lên ~11-13%. Không còn "đòi đã có Lõi front" nhưng Lõi này vẫn fire 100% khi có và giá của nó (mất hàng sau) là đủ để làm lựa chọn.
- **R5 `c_golden_egg`:** hai bước. (a) Kiểm xem `c_spore_burst` có tạo Egg không; nếu có, gắn tag `egg` cho nó để `egg_source` đúng thường hơn (nest 16.8% picked, spore_burst 15.2%). (b) Không nới cổng: golden_egg không có Egg thì vô dụng. Với R1, ô rule Amber (2 Lõi, một bị cổng) có trọng số 2 thay vì 1/6. Về fire 57%: thêm một nguồn kích hoạt (ví dụ cũng chạy khi Egg nở, hoặc khi Egg bị gỡ cuối trận) để "đã chọn thì phải fire". Cần Liam chọn luật mới (mục 4).
- **R6 (chỉ khi cần) trường trọng số Lõi:** `build_offer` chọn trong ô bằng `rng.next_int(tổng_trọng_số)` thay `next_int(n)`, mặc định 1 (dùng `RelicDef.weight`, nay chỉ rule dùng). Vẫn một lần gọi rng mỗi thẻ. Đặt 2 cho Lõi bị cổng nếu R1 chưa đủ.
- **R7 `c_blood_sign`:** chỉ R1 (ô rule Crystal 5 Lõi, ước tính 9.1 lên ~11-12%). Nếu chưa đủ: thêm token requires `poison_source` (party có mặt poison HOẶC sở hữu Lõi tạo poison) vào `token_ok`, cần cập nhật `t_core_catalog` (token lạ bị từ chối).
- **R8 `c_steady_hold`:** fire thật rồi (sau S2 sẽ thấy), nhưng chọn 2.1%/10.3% hiện. Đề xuất thiết kế (Liam quyết): die đang Hold được +1 giá trị mỗi lượt giữ (thưởng cho việc chờ), hoặc cho Hold die thứ hai không tốn gì và die Hold giữ nguyên crit. Không đổi trước khi Liam chọn.
- **`c_fossil`, `c_dim_stone`:** không đổi luật. Hiện đủ (33.9%, 11.3%) và fire thật; chỉ cần S1. Chọn thấp (16%, 18%) là bản chất "cược", không phải bug hiển thị.

### Tóm tắt từng Lõi, một dòng

- c_fissure: R1 + R2 (cổng `debuff` thật sự), đụng luật.
- c_plague_spread: R1, đụng luật.
- c_concord: R1 (R6 nếu thiếu), đụng luật.
- c_toxic_still: R1 (R6 nếu thiếu), đụng luật.
- c_open_ranks: R4 bỏ requires + excludes ngược, đụng luật.
- c_golden_egg: R1 + R5 (tag egg cho Lõi tạo Egg, thêm nguồn fire), đụng luật.
- c_mirror_face: R1, đụng luật.
- c_blood_sign: R1 (R7 nếu thiếu), đụng luật.
- c_fossil: S1 (sim), không đụng luật.
- c_dim_stone: S1 (sim), không đụng luật.
- c_steady_hold: S2 (sim) + R8 (buff, chờ Liam), R8 đụng luật.

## 3. Kế hoạch đo

Làm theo thứ tự, mỗi bước dừng đọc kết quả.

0. **Đối chiếu số trước.** Thêm cột "% run hiện ≥1 lần" vào `sim_combo_draw.gd` (ngưỡng 10% là theo % run, cột hiện tại là số lần hiện). Giải thích vụ lệch toxic_still 41.9 so với 6.5.
1. **Baseline đã sửa sim (S1-S4).** `sim_balance` 1000 run × 4 đội, A0, `final`, seed cố định, ghi lại fired/picked mỗi Lõi. Mục tiêu: fossil, dim_stone, steady_hold, kindle, tundra ≥90%. Nếu tidecaller vẫn 0 thì mở bug hook.
2. **Rút thẻ trước/sau.** `sim_combo_draw` 5000 run Short và 5000 run Full, hai chính sách random và hunt, ghi % run hiện ≥1 cho từng Lõi và tổng khối lượng từng ô. Qua khi: mỗi Lõi (bỏ test/disabled) ≥11% (sai số 95% ở p=10%, n=5000 là ±0.8 điểm nên đặt 11 để chắc ≥10), không Lõi nào hiện >70% (tránh ô nhỏ bị nhồi).
3. **Sim đánh sau R-nhóm.** `sim_balance` 8000 run như bản `new_final_A0` (cùng seed): (a) fired/picked ≥90% với mọi Lõi có ≥30 lượt chọn, (b) win-rate tổng và theo chính sách vẫn trong dải mục tiêu đã chốt ở commit `652037d`, (c) Lõi mới được rút nhiều (dice Crystal) không vượt dải win +10 điểm so với trung bình, (d) cặp Lõi bất thường (bảng cuối báo cáo) không thêm cặp 0%.
4. **Test.** `t_core_fires`, `t_core_catalog` (nếu thêm token), test offer/seed (sửa kỳ vọng nếu R1), `t_rules_version` (bump), rồi cả suite một lần (số sàn ở `.claude/docs/technical-preferences.md`). Replay cũ lệch RULES_VERSION, bản `-r` phải còn trong `SUPPORTED_RULE_VERSIONS` nếu cần replay run đang dở.
5. **Quan sát thật.** Chụp một run có `c_open_ranks`, một run có `c_golden_egg` + nest, một run có `c_steady_hold`, kiểm float text `core_fired` hiện đúng lúc (theo nguyên tắc "Lõi mới phải thấy được khi chơi").

## 4. Cần Liam quyết

1. R1 (đổi cách rút trục, ảnh hưởng mọi Lõi) hay giữ cách rút và bớt Lõi khỏi ô dice? Mình khuyến nghị R1.
2. `c_open_ranks`: đồng ý bỏ cổng "phải có Lõi front"?
3. `c_golden_egg`: nguồn fire thứ hai là gì (Egg nở, Egg bị gỡ, hay đầu trận khi có Egg)?
4. `c_steady_hold`: buff như R8 hay để nguyên?
5. Cho làm S1-S4 (chỉ sim, không bump luật) trước để có số thật rồi mới quyết R-nhóm?

## Lõi ít kích hoạt
Đo 21/10: expert, 40 run/Lõi, `--force=<id>`, seed 7000, A0, mọi đội. "fired" = % run có fire (raw `production/qa/sim/sim-2026-10-21-lf*_<id>.md`). Không có lỗi hook thật (a). Không đổi số thiết kế.

| Lõi | loại | fired (ép sở hữu) | điều kiện / ghi chú | đề xuất (chờ Liam duyệt) |
|---|---|---|---|---|
| c_key_strike | c (bot) | 7.5% -> 77.5% sau sửa bot | cần Hold một die đánh >=9; bot cũ Hold die nhỏ nhất và không có Core này trong HOLD_CORES. Sửa trong sim_balance.gd (9827d2f). | không |
| c_prism | c | 70% | cần 4 loại face trong 1 lượt; số cũ 33% là mẫu nhỏ (12 pick) | không |
| c_overflow | c | 70% | cần mana >8; xảy ra khi có mana dư | không |
| c_golden_egg | b | 52.5% | cần Egg chết; core_offer đã chặn theo egg_source nên ép sở hữu không có Egg thì không fire | thêm nguồn fire thứ hai (câu hỏi 3 ở trên) |
| c_tidecaller | b | 55% | cần tiêu >=3 mana trong trận; trận ngắn thì không đủ | cân nhắc ngưỡng 3 -> 2 (chưa đổi) |
| c_chimera_hunt | b | 87.5% | chỉ tính kill của die "finisher" (die cuối lượt); số cũ 63% là mẫu nhỏ | không |
| c_mana_ward | c | 87.5% | cần mana >=2 cuối lượt; bot chi hết mana | không |
| c_deep_current | b/c | 87.5% | cần mana dư cuối trận thắng; bot chi hết | không |
| c_thorn_rebound | b | 75% | cần có Axie có Thorns và bị đánh | không (nếu muốn: gate offer theo nguồn Thorns) |
