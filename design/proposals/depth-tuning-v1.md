# Depth tuning v1: kéo tỉ lệ thắng về mục tiêu và làm quyết định có trọng lượng

Người viết: systems-designer, 20/10/2026. Chưa chạy sim nào cho bản này, chưa sửa code, chưa commit.
Mọi số "dự đoán" bên dưới là ước lượng có lập luận, KHÔNG phải kết quả đo. Sim (`godot/tools/sim_balance.gd`) mới là trọng tài.

Mục tiêu Liam chốt (21/10): người biết chơi + biết ghép Lõi thắng 15-25% (Short A0); `random_legal`, `attack_spam`, `attack_only` <= 5%; khoảng cách khôn - bừa >= ~15 điểm.

Nguồn số: `sim-2026-10-20-final_A0.md` (4500 run, bản trước khi bỏ trần thorn và sửa review Lõi). Knob: `combat_tune.json`, `elite_affixes.json` (worktree FX). Đọc code bot: `sim_balance.gd` (worktree SB).

---

## 1. Chẩn đoán

### 1.1 Cái thước đo đang hỏng một nửa: bot "bừa" không bừa, bot "khôn" không khôn

Đọc `sim_balance.gd` thì ra:

- `random_legal`: mỗi lượt **dùng hết mọi viên** (không bao giờ bỏ viên), thứ tự ngẫu nhiên, mục tiêu ngẫu nhiên. Không Hold, không reroll.
- `attack_spam`: dùng hết mọi viên, mặt dmg trước (đánh quái máu thấp nhất), mặt khác thì rơi về `_move_random` (khiên/hồi cho Axie ngẫu nhiên). Cũng không Hold, không reroll.
- `attack_only`: chỉ dùng mặt dmg, bỏ hết viên khác. Đây là bot duy nhất bị phạt đúng (5.3%).
- `expert`: mỗi lượt chấm điểm từng nước đi 1 bước (`use_die` + `undo_last`), Hold 1 viên dmg lớn ở lượt Đòn của boss, dùng **đúng 1 reroll miễn phí**. Không bao giờ trả mana, không sắp thứ tự viên cho Mồi/Kết, không biết combo Lõi (xem 1.4).

Hệ quả:
- "Dùng hết viên, ai cũng được" đã thắng 20%. Chống-spam hiện chỉ bắt được kiểu "bỏ viên không phải attack", chưa bắt được kiểu "dùng hết nhưng không nghĩ".
- Con số khoảng cách 6.3 điểm phần lớn là **lỗi của bot expert**, không chắc là lỗi của game:
  - Expert chết ở boss 1 nhiều hơn mọi bot khác: 113/500 (khoảng 23% số run) so với random 52/1000 (5%), greedy 42/1000, spam 63/1000.
  - Expert đánh boss lâu nhất: 7.4 lượt, random 6.3, greedy 6.0, spam 6.5.
  - Đội beast_bird: expert 5.6% nhưng greedy 25.2% và attack_only 25.2%. Bot "khôn" thua bot "bấm bừa" trên cùng đội là dấu hiệu bot có lỗi (nghi: Hold/bỏ viên khi `best_d < -0.01` làm mất đòn ở lượt Giáp, hoặc `_eval` coi nhẹ sát thương).
- Kết luận: **chưa thể chỉnh số game dựa trên khoảng cách này**. Việc đầu tiên là sửa thước (mục 3, bước S0).

### 1.2 Run thắng nhờ đội, không nhờ quyết định

Cùng một bot random, tỉ lệ thắng theo đội dao động từ 6.3% (aqua_plant) tới 32.4% (thorn_shield), tức 26 điểm. Cùng cột đó, khoảng cách expert - random theo đội:

| Đội | random | expert | Khoảng cách |
|---|---|---|---|
| mixed_dmg | 18.9% | 45.1% | +26 |
| tank_heavy | 17.5% | 40.8% | +23 |
| mixed_std | 16.8% | 26.8% | +10 |
| reptile_bug | 28.7% | 29.2% | +0.5 |
| thorn_shield | 32.4% | 33.8% | +1.4 |
| aqua_plant | 6.3% | 6.9% | +0.6 |
| beast_bird | 23.1% | 5.6% | -17.5 (nghi lỗi bot) |

Đọc ra: ở 3 đội "đủ công cụ" (mixed_dmg, tank_heavy, mixed_std) tay nghề có giá. Ở 3 đội còn lại kết quả gần như định sẵn từ lúc dựng đội: reptile_bug (poison tự chạy, xuyên khiên/Giáp, không cần quyết định), thorn_shield (thorn tự đánh, và số này còn TRƯỚC khi bỏ trần thorn nên sẽ lên nữa), aqua_plant (không có gì phá Giáp, xem 1.5). Đội được chọn ngẫu nhiên trong sim, nên sim đang đo "may đội" nhiều hơn đo "chơi hay".

### 1.3 Chết ở đâu (random_legal, 1000 run)

Từ bảng "Chết theo node": Elite 1 (r5) 115, boss 1 (r6) 52, Elite 2 (r9) 71, boss 2 (r12) 125, Elite 3 (r15) 90, boss 3 (r18) 262, trận thường ~76 (số cộng tay, để định hướng; sim phải in thẳng phễu). Số run tới boss 3 xấp xỉ 262 + 205 thắng = 467, qua boss 3 khoảng 44%.

Nghĩa là: tường cuối (boss 3) làm gần hết việc lọc, đoạn đầu (boss 1, trận thường) gần như không lọc ai. Người bừa thắng ~20% vì vượt được act 1-2 dễ dàng rồi 44% qua boss cuối. Muốn random <= 5% mà expert 15-25% thì **mỗi cổng (Elite/boss) phải giết random nhiều hơn expert** khoảng 2.7 lần về hazard: random cần giữ ~80% sau mỗi cổng trong 6 cổng (0.8^6 = 0.26 nên 20% -> 5%), expert chỉ giữ ~92% mỗi cổng (0.92^6 = 0.61 nên 33% -> 20%). Tức là thay đổi phải "chọn lọc theo tay nghề", không phải đẩy HP chung (đẩy chung giết cả hai như nhau).

### 1.4 Vì sao chọn Lõi "theo combo" không tạo khác biệt

- Bot `combo` chỉ làm: "chọn trục đang có, rồi bậc cao nhất". Nó không biết ghép (ví dụ Thác Đổ + Xúc Xắc Thứ Sáu + Mặt Gương, hay Bức Tường Sống + Kẻ Gác Cổng). Nên 28.0% vs 26.2% là kết quả hợp lý: bot không ghép combo thì tất nhiên không thấy chênh.
- 71.7% run bị cap (2 Lõi cùng trục dice/mana/pos/rule), nên "cùng trục" thường chỉ là cap chứ không phải combo.
- Top Lõi thắng là **Lõi thụ động** (Nổ Bào Tử 46.7%, Trứng Vàng 44.7%, Tổ Ấm 37.3%): chúng chạy khi Axie ngã / Egg chết, bot không cần làm gì. Lõi thua nhiều là Lõi **cần chơi**: Ba Viên 8.5%, Hồ Mana 13.7%, Ngọn Triều 14.2%, Kết Cục 18.9%, Mana Ward 20.0%, Giọt Sương 20.6%, Khế Ước Gai 20.8%. 5 trong 10 Lõi đáy là trục mana: bot không bao giờ trả mana (chỉ có reroll ngoài hạn mức mới tốn mana, và expert chỉ reroll miễn phí) nên cả trục mana chạy rỗng.
- Win-rate "khi có Lõi" còn bị nhiễu bởi đội (người ta chọn Lõi khi nào đội cần). Phải tách theo đội trước khi nerf/buff (mục 3).
- Điểm xấu thật về thiết kế (không chỉ lỗi bot): **chưa có Lõi nào mà chọn đúng thì nhảy 15+ điểm trên một đội không bị lệch**. Cặp "mạnh bất thường" (Chữ Ký Máu + Vòng Lặp 76%, Thân Cổ Thụ + Nổ Bào Tử 75%) toàn là cặp tự chạy, không đòi quyết định.

### 1.5 Vì sao class lệch

- Aqua/Plant: theo 6.7b của depth-v3, hai class này có 0 mặt poison/debuff, rất ít `pierce`/`aoe`. Giáp (M1: tank trait, Elite Giáp Sắt, Giáp nhịp boss) biến mặt dmg 2-5 thành ~1. Aqua dmg 13/25 biến thể, Plant 9/26. Đội này không có thứ để mở Giáp và dmg thô thấp, nên policy nào cũng ~6%. Đây là lỗi thiết kế, không phải lỗi bot.
- Beast/Bird: nghịch lý. attack_only thắng 25.2% (các đội khác <= 3.5%) vì mặt dmg của Beast/Bird mang `vulnerable`, tức chính mặt dmg đã tắt Giáp cho mặt dmg kế tiếp. "Chỉ bấm attack" với đội này vẫn đủ, đúng kiểu Liam ghét. Còn expert 5.6% là lỗi bot (1.1).
- Reptile_bug thắng đều (28-31%): poison xuyên Giáp + tick xuyên khiên, một bộ công cụ trọn vẹn không phụ thuộc quyết định.
- Thorn_shield 32-34%: thorn tự gây sát thương, bỏ trần thì còn lên. Cần chạy baseline mới trước khi nhận xét (mục 3).

### 1.6 Quyết định nào hiện không có trọng lượng (dự đoán, sẽ đo bằng ablation ở mục 3)

| Quyết định | Vì sao nhẹ (theo code/data) | Kỳ vọng sau chỉnh |
|---|---|---|
| Hold | Chỉ có thưởng ở lượt Hở boss (+30%) và mặt dư của boss; trận thường không có lý do Hold | Hở +60%, Đòn Nạp, Cất Lửa |
| Reroll | 1 miễn phí, 3 trả 2 mana; mana gần như không có chỗ tiêu khác nên không ai thấy mana đáng giá | Mặt dư -> mana, Lõi mana buff |
| Thứ tự viên | Chỉ Mồi/Kết/Thác Đổ ăn thứ tự; không Lõi nào bắt buộc | Giáp tắt bằng mặt debuff phải đi TRƯỚC mặt dmg |
| Mục tiêu khiên/stun | Random chọn bừa vẫn trúng ~1/5 | Đòn Nạp x3, Khiên cho đúng Axie bị khoá |
| Hàng trước/sau | Chưa có số; trận thường vẫn thắng dù xếp bừa. Đề xuất đo trước khi đụng (xem 3) | |
| Thứ tự gán Axie | Chưa có số | Đo trước |

---

## 2. Đề xuất chỉnh

Quy ước: "đụng luật?" = file nằm trong fingerprint `t_rules_version` nên phải bump `RULES_VERSION` (đi cùng lần bump depth v3). Knob thuần số trong `combat_tune.json`/`elite_affixes.json` vẫn nằm trong fingerprint 19 file luật, nên cũng tính là bump. Gom hết vào cùng một lần bump.

### (a) Độ khó chung: chỉ dùng làm núm cuối để hiệu chuẩn, không phải đòn bẩy chính

Lý do: tăng HP/sát thương chung giết random và expert gần như bằng nhau, nên chỉ nên chỉnh sau khi nhóm (b) đã tạo độ chọn lọc, để kéo mức tuyệt đối về đúng 15-25%.

| Knob | Cũ -> Mới | Phạt lối chơi nào | Dự đoán | Đụng luật? |
|---|---|---|---|---|
| `difficulty.enemy_dmg_mult` | 1.2 -> 1.35 (khởi điểm, hiệu chuẩn lại ở bước cuối) | Người không chặn đòn bằng khiên đúng Axie; hồi bừa | random -5..-8, expert -3..-5 | Có |
| `TUNE.elite_mult` | giữ 1.5 | Elite 1 đã lọc tốt (expert 24/500 chết ~5%, random 115/1000 ~11.5%) | | Không đổi |
| `difficulty.boss_hp_mult` | giữ 1.1 | Boss 3 đã là tường chính (1.3), không đẩy thêm | | Không đổi |
| `TUNE.growth2` | giữ 1.05 (không lên 1.06 như depth-v3 6.5) | Tường cuối đã đủ cao | | Không đổi |
| Elite 1 và boss 1 (khuyến nghị) | Nâng nhẹ hazard cho NGƯỜI BỪA qua (b) chứ không qua HP | Vì boss 1 hiện chỉ giết random 5%, đoạn đầu không lọc | | |

### (b) Tăng trọng lượng quyết định: nhóm quan trọng nhất

Mỗi mục: đổi gì, phạt lối nào, thưởng quyết định nào, dự đoán.

**b1. Lượt Hở của boss nhân lớn hơn, lượt Chuẩn bị/Đòn khó đánh hơn**
- [Reviewer sửa] `boss_rhythm.hollow_taken_pct` 30 -> 50 (không 60); `hollow_dealt_pct` giữ -30. Lý do: +60% cộng Lõi chạm trần +10/mặt, và -50% sát thương lượt Hở biến lượt đó thành lượt nghỉ, trận boss lê thê. Gốc: 60 / -50.
- Giữ nguyên Giáp nhịp (M6) ở lượt Chuẩn bị + Đòn.
- Phạt: đánh đều mọi lượt (random/spam), dùng hết viên lớn trong lượt Giáp. Thưởng: Hold viên lớn (và Cất Lửa/Giữ Vững), mở Giáp bằng debuff/poison trước khi đánh.
- Dự đoán: boss 1-3 giết random thêm nhiều (random thiếu cả Hold lẫn thứ tự), expert (khi đã sửa bot Hold) giảm ít. Đây là đòn lọc mạnh nhất của đợt này.
- Cẩn thận: mặt 5 x 1.6 = 8 -> chạm trần +10/mặt của 3.4 nếu cộng Lõi. Kiểm khi sim. Đụng luật: có.

**b2. Giáp mỏng (M1) tắt ngắn hơn và đúng thứ tự**
- `plating.off_turns` 2 -> 1 (đã được depth-v3 6.7b ghi là phương án dự phòng). Nghĩa là phải **duy trì** debuff/poison mỗi lượt, một viên luôn "đi mở đường".
- `plating.div` 12 -> 10, `plating.max` 4 -> 5 (P: pw5 ~2, pw11 ~4, pw17 ~5).
- Bonus: mặt dmg có keyword `vulnerable` **không tự tắt Giáp cho chính nó**, chỉ cho mặt dmg đến sau trong cùng lượt (xử lý thứ tự). Đây là cách giết lối `attack_only` của Beast/Bird (25% -> dự đoán ~8-12%) mà không đụng bản sắc debuff của họ.
- Phạt: bấm attack theo thứ tự ngẫu nhiên; mặt nặng đi trước mặt mở đường. Thưởng: thứ tự viên, chọn Axie nào gánh mặt debuff.
- Cần kiểm trước: định nghĩa "lượt" của `off_turns` (6.7b) và chỗ code trừ P trong `damage_pipeline`. Đụng luật: có (code + knob).

**b3. Đòn Nạp (M5) giết thật nếu không chuẩn bị**
- [Reviewer sửa] GIỮ `charge.mult` 2.5. Bản gốc đề xuất 3.0 (mặt 5-6 x 3 = 15-18, một đòn hạ gần mọi Axie tier-1) nhưng người mới chưa biết đọc tell sẽ mất Axie oan, đúng kiểu "chết không hiểu vì sao". Chỉ lên 3.0 nếu sim sau b1/b2 vẫn thiếu chọn lọc VÀ tell Nạp đã hiện rõ mục tiêu bị khoá (UI) ở lượt Nạp. Gốc: 2.5 -> 3.0.
- Giữ chu kỳ 4 lượt và ngắt bằng stun/freeze. Bot random không biết khiên đúng Axie bị khoá (xác suất ~1/5 mỗi lần), expert biết (`_incoming` đã tính `charge_next`).
- Phạt: spam (random shield). Thưởng: khiên đúng mục tiêu, dành stun cho lượt Nạp, Hold viên khiên. Dự đoán: random chết thêm ở Elite 2-3; expert ít đổi. Đụng luật: có.

**b4. Mặt "dư" có giá trị qua mana (và Hold)**
- [Reviewer sửa] Luật mới `unused_to_mana`: cuối lượt, mỗi viên **chưa dùng** (và không Hold) cho +1 mana, tối đa 2/lượt. Thêm 3 điều kiện bắt buộc: (1) chỉ cho viên **chưa bị reroll** (chống bỏ viên rồi lấy mana rồi reroll tiếp); (2) tổng mana vào từ luật này tối đa 2/lượt VÀ không quá 6/trận; (3) viên bị khoá/stun không tính. Xem Ghi chú reviewer. Nghĩa là bỏ viên yếu có thể đáng hơn dùng bừa, mana đổi thành reroll viên mạnh (2 mana).
- Phạt: bot "dùng hết mọi viên" (cả random và spam) lãng phí nước đi; thưởng: biết bỏ viên yếu để lấy mana câu mặt tốt.
- Vì sao cần: nay mana không có chỗ tiêu hấp dẫn nên cả trục mana chết (1.4). Luật này nối Hold, reroll, mana và Lõi mana thành một vòng.
- Rủi ro: dễ lạm dụng ("bỏ 2 viên mỗi lượt lấy 2 mana"). Trần 2/lượt + `reroll.max_total` 4 giữ chặn. Cần Liam duyệt (câu 1). Đụng luật: có (luật mới, cần action? KHÔNG: không cần action mới vì chỉ là xử lý cuối lượt; cần xác nhận với lead-programmer).

**b5. Giáp dày hơn làm chọn mục tiêu quan trọng**
- Đã có M2 Khiên Hồi, M3 Phản Đòn. Chưa đổi thêm. Chỉ chỉnh `ward.stack_cap_mult` giữ 2 và theo dõi hạn chế "tường". Không đưa đề xuất số cho tới khi ablation (mục 3) cho thấy chọn mục tiêu có nhẹ thật.

**b6. Trận Elite phải dùng đa dạng mặt**
- Giữ nguyên bảng affix, nhưng `elite_affixes.json`: affix Đòn Nạp (`charge`) vào pool nhóm A mọi đội (đã có trong `no_break_ok`). Chỉ thêm ràng buộc: Elite 2 và 3 luôn nhận 1 affix mà chỉ "debuff/stun/khiên đúng chỗ" mới xử lý (`iron`, `charge`, `mend`), không rút `echo` (yếu). Echo ở nhóm "" đã không nằm trong group A nên đã được lọc; chỉ cần kiểm lại với `first_run`. Đụng luật: có thể (nếu đổi pool).

### (c) Lõi

**c1. Tinh Thể phải "thấy được" tác động (khi ghép đúng)**

Nguyên tắc: bonus lớn nhưng có trần, và chỉ tính khi **điều kiện combo thật sự đạt**, không tự chạy.

| Lõi | Cũ | Mới | Vì sao / trần |
|---|---|---|---|
| Ba Viên (T) | Chỉ dùng 3 viên; viên dư tự Giữ + Focus +3 | Viên dùng +2 giá trị; Focus +3 -> +5; viên Giữ không tính vào giới hạn Hold | 8.5% thắng (thấp nhất); trần +10/mặt giữ nguyên |
| Thác Đổ (T) | chuỗi +2/+4/+6/+8 (tổng 5 viên +20) | +2/+3/+4/+5 (tổng +14), nhưng thêm: chuỗi giữ khi qua mặt shield **có Mồi** | 42.6% thắng, quá tự chạy; M1 Giáp trừ SAU bonus nên chuỗi vẫn bị P cắt |
| Mặt Gương (T) | giữ | giữ | 42.7%, ở bậc T chấp nhận được |
| Chữ Ký Máu (T), Vòng Lặp (T) | giữ | thêm `excludes` cặp này ở bước cấp Lõi nếu sau (c) vẫn >60% | Cặp 76% (n=21) quá nhỏ để kết luận, đo lại |
| Nổ Bào Tử (R) | 20% Max HP mỗi quái, boss 8% | [Reviewer sửa] 14% / boss 5%, Egg nửa (gốc 12%); giữ nổ dây chuyền + hiệu ứng để còn "đã" | 46.7% thắng ở bậc Rêu là cao nhất, vượt cả Tinh Thể |
| Trứng Vàng (H) | 3 mana + khiên 4 + dmg +3 | 2 mana + khiên 4 + dmg +2; **thêm** cho 1 Egg đầu trận nếu chưa có Tổ Ấm (bỏ phụ thuộc cứng) | 44.7% nhưng chỉ xuất hiện 5.5% vì phụ thuộc Tổ Ấm; nerf sức, nới điều kiện |
| Tổ Ấm (R) | giữ | giữ | 37.3%, theo dõi |
| Hòn Đá Mờ (H) | giữ | giữ | 33.5%, chọn 16.2%: loại được chọn nhiều nhất, theo dõi |

**c2. Buff Lõi yếu**

| Lõi | Cũ | Mới |
|---|---|---|
| Ngọn Triều (R) | mỗi 3 mana tiêu: 2 dmg toàn địch | mỗi **2** mana tiêu: 2 dmg toàn địch, **xuyên Giáp**, tối đa 3 lần/lượt |
| Hồ Mana (R) | mặt mana +1; lãi mỗi 3 mana dư +1 (tối đa +3) | mặt mana +1; lãi mỗi **2** mana dư +1 (tối đa +3). **Chỉ áp sau khi bot đã biết tiêu mana (S0)**, nếu không buff vô nghĩa |
| Thành Trì (R, "bastion") | hàng trước -2 mọi đòn đơn | hàng trước -3 (đòn lên Axie hàng trước) khi `enemy_dmg_mult` tăng; hạ lại -2 nếu enemy_dmg_mult giữ 1.2 |
| Kết Cục (R) | +1 mỗi viên đã dùng trước, tối đa +4 | giữ số; chờ bot biết sắp thứ tự (S0) rồi mới đánh giá |
| Giọt Sương, Mana Ward, Khế Ước Gai | giữ | giữ; chờ S0 (thấp vì bot không tiêu mana) |
| Y Tá Chiến Trường (field_medic 19.4%), Nhà Sưu Tầm (20.9%) | giữ | giữ: mẫu nhỏ, nhiễu đội |

Quy tắc: chỉ buff/nerf theo bảng "win-rate khi có Lõi" **sau khi tách theo đội** (mục 3). Các hàng chưa có chữ "chờ S0" là chắc: Ba Viên, Ngọn Triều, Nổ Bào Tử, Thác Đổ, Trứng Vàng.

**c3. Sáu Lõi/luật "không bao giờ kích hoạt"**

| Id | Thật hay giả | Xử lý |
|---|---|---|
| `c_tidecaller` | **Thật** (cho bot): hook `on_reroll_paid`, bot không trả mana | Bot sửa ở S0; buff Ngọn Triều ở c2 |
| `c_fossil`, `c_dim_stone`, `rule_crow`, `rule_none` | **Giả**: hiệu ứng nằm ở khâu chọn Lõi (`CoreOffer`/chuỗi bậc), `t_core_fires.gd` đã liệt kê `NO_BEHAVIOUR` | Sửa sim: không đưa vào bảng DEAD; đo bằng số lần đổi bậc, không bằng event trận |
| `rule_hard_shell` | **Nghi giả**: có hook thật (`damage_pipeline.gd:81`, `combat_engine.gd:1398`) và `t_core_fires` có kịch bản | Sửa heuristic fire: đếm lần gọi `CoreHooks.fire` thật thay vì khớp tên key |

### (d) Cân class (giữ bản sắc)

Chưa nên làm trước khi chạy lại baseline với thorn không trần + 3 Lõi thorn mới (Khiên Gai, Gai Mọc, Phản Chấn): thorn xuyên Giáp, có thể tự cứu Aqua/Plant (đội khiên). Nếu sau baseline 2 aqua_plant vẫn < 12% thì:

| Class | Thay đổi `part_faces.json` | Bản sắc |
|---|---|---|
| Aqua | 4 biến thể dmg 4+ thêm keyword `pierce` (tia nước) | Giữ: Aqua vẫn thiên khiên/hồi, nhưng có đường xuyên Giáp |
| Plant | 3 biến thể thêm `weaken` (rễ/độc nhẹ), một nửa số mặt heal thêm Gai +1 | Giữ: Plant vẫn thiên hồi |
| Beast, Bird | Không buff. Áp b2: `vulnerable` chỉ tắt Giáp cho mặt dmg kế tiếp | Đòn mạnh nhưng phải có thứ tự |
| Reptile, Bug | Giữ | |

Cảnh báo: tôi chưa đọc `part-skill-identity.md`; đối chiếu bản sắc ở đó trước khi chốt (đụng `part_faces.json` = đụng file luật). Aqua/Plant chỉ cần đạt >= `team_can_break` và win >= 15% với tay nghề khôn, không cần bằng mixed_dmg.

### (e) Tần suất Lõi (< 10% run)

- Ngưỡng "LOW < 10%" không công bằng cho Tinh Thể: pool T lớn nên mỗi Lõi T ra ~7-10% là bình thường. Đề nghị đổi định nghĩa trong sim: LOW = dưới 0.6 x mức trung bình cùng bậc.
- Thật sự thấp: `c_golden_egg` 5.5% (phụ thuộc Tổ Ấm, xử lý ở c1), `c_open_ranks` 6.2% (phụ thuộc Lõi hàng trước; đề nghị nới `requires` về "có >= 1 Lõi trục pos"), `c_toxic_still` 7.1%, `c_concord` 7.6% (cần 2+ cùng class), `c_fissure` 7.8%, `c_plague_spread` 8.6%.
- Phép sửa: nới `requires` (ví dụ poison -> `team_can_break`), không thêm trọng số vì `CoreOffer` chỉ có trọng số cho luật run, không cho Lõi (thêm trọng số = đổi schema `RelicDef`). Cần đọc token ở `core_offer.gd:11-17` trước khi chốt token nào.
- Chuỗi bậc (`tier_chains_short` trong `RelicTuning`) tôi chưa đọc; nếu muốn T xuất hiện nhiều hơn thì đổi ở đó, nhưng đó là đòn bẩy sức mạnh tổng, để sau bước (c).

### Việc thêm nếu thorn quá mạnh (chưa bật)

Thorn không trần + thorn_shield đã 32-34% trước đó. Chuẩn bị sẵn knob `thorns.boss_turn_cap_pct` (thorn lên boss mỗi lượt tối đa 25% Max HP boss) chỉ bật khi baseline 2 cho thorn_shield expert > 45% hoặc có run một-đòn-giết-boss. Liam đã chốt "bỏ trần", nên mặc định tắt.

---

## 3. Kế hoạch sim và thứ tự áp dụng

Chỉnh số chỉ có nghĩa khi thước đo đúng, nên thứ tự là: sửa thước -> độ chọn lọc -> Lõi/class -> hiệu chuẩn mức tuyệt đối.

**S0. Sửa bot (không đổi game) rồi chạy baseline 2**
1. Expert2: sửa lỗi boss 1 (log vì sao chết ở r6), Hold cho cả lượt Hở của trận thường nếu có Lõi Giữ, **trả mana để reroll**, sắp thứ tự viên (mặt Mồi/mở Giáp trước, Kết cuối), 2-3 bước tìm kiếm cho thứ tự thay vì 1 bước.
2. Core picker có danh sách combo thật (Thác Đổ + Xúc Xắc Thứ Sáu + Mặt Gương; Bức Tường Sống + Kẻ Gác Cổng + Hàng Sau Phát Sáng; Sóng Khiên + Hàng Sau + Chữ Ký Máu) thay cho "cùng trục".
3. Đo thêm: **phễu** (tỉ lệ tới/qua từng cổng), **thắng theo Lõi tách theo đội**, số lần `CoreHooks.fire` thật, mana dùng/lượt, số lần Hold/reroll.
4. **Ablation**: expert2 bỏ lần lượt Hold / reroll / thứ tự / chọn mục tiêu khiên / chọn mục tiêu dmg. Trọng lượng quyết định = win(expert2) - win(expert2 thiếu X). Mục tiêu sau chỉnh: mỗi quyết định >= 3 điểm, quyết định nào < 1 điểm là chưa có trọng lượng.
5. Cỡ mẫu: >= 2000 run mỗi policy (SE ~0.9 điểm ở 20%). Bản cũ expert chỉ 500 (khoảng tin 95% ~ +/-3.9 điểm), không đủ. Dùng cùng seed (đội/map/Lõi giống nhau) giữa các policy để giảm nhiễu.
6. Kỳ vọng S0 (ước, chưa đo): expert 30-35% (sửa lỗi boss 1 và beast_bird), random/spam gần như không đổi (~20%). Nếu expert2 vẫn không hơn random > 10 điểm ở mixed_dmg/tank_heavy thì lỗi nằm ở thiết kế, không phải bot.

**B. Nhóm (b)** áp theo thứ tự b1 -> b2 -> b3 -> b4, sim lại sau MỖI mục (5 policy x A0 x 2000 run).
- Chấp nhận mục nếu: random và attack_spam tụt ít nhất 3 điểm, expert2 tụt không quá 1/3 mức tụt của random, ablation của quyết định liên quan tăng >= 2 điểm.
- Kỳ vọng sau b1-b4: random ~8-10%, spam ~8-10%, attack_only <= 3%, expert2 ~24-30%.

**D. Class (d)**, chỉ khi aqua_plant < 12% sau B. Đo theo đội: aqua_plant expert >= 15%.

**C. Lõi (c)**: áp c1/c2 chắc chắn (Ba Viên, Ngọn Triều, Nổ Bào Tử, Thác Đổ, Trứng Vàng), sim lại, xem bảng thắng theo Lõi đã tách đội. Mục tiêu: mọi Lõi trong khoảng +/- 8 điểm quanh trung bình cùng đội, và combo thật (bot có danh sách) thắng hơn Lõi ngẫu nhiên >= 10 điểm cho expert2.

**A. Hiệu chuẩn cuối**: chỉnh `enemy_dmg_mult` (1.2 -> 1.35 làm khởi điểm) theo từng nấc 0.05 tới khi expert2 vào 15-25%. Kiểm cuối: random <= 5%, spam <= 5%, attack_only <= 5%, greedy 15-25%, khoảng cách >= 15, chạy 2 lần với 2 bộ seed khác nhau.

**Dự đoán win-rate cuối** (khoảng, chưa đo): random 4-7%, attack_spam 5-8%, attack_only 1-3%, greedy 15-20%, expert2 20-25%. Khả năng cao nhất không đạt đủ cả 3 mục tiêu ngay vòng 1: attack_spam là bot khó ép <= 5% nhất vì nó dùng hết viên và ưu tiên mục tiêu máu thấp; nếu còn ~8% sau b1-b4 thì cần thêm một cơ chế phạt "mặt khác" (ví dụ ép khiên đúng Axie bị khoá ở nhiều trận hơn), không nên nâng HP chung để bù.

Kiểm bằng người: sau nhóm B, Liam hoặc người chơi có kinh nghiệm chơi >= 5 run Short A0 với build mới, vì bot chỉ đo được các quyết định bot biết làm.

---

## 4. Câu hỏi cho Liam (cần quyết)

0. (Reviewer thêm) **Có cho thử `enemy_dmg_mult` 1.2 -> 1.35 không, hay ưu tiên đẩy qua Giáp/Hở/Nạp trước?** Khuyến nghị: để cuối, chỉ chạm sau khi b1-b4 đã sim, và dừng ở 1.30.
1. **Luật mới "viên chưa dùng cuối lượt cho +1 mana (tối đa 2/lượt)" (b4) có cho phép không?** Đây là thay đổi luật lớn nhất nhưng là thứ duy nhất làm Hold/reroll/mana nối vào nhau. Khuyến nghị: có, thử ở sim trước, tắt được bằng một knob.
2. **Được đổi `part_faces.json` cho Aqua (thêm `pierce`) và Plant (thêm `weaken`) không?** Chỉ làm khi baseline 2 vẫn cho aqua_plant < 12%. Khuyến nghị: chờ baseline 2 rồi hỏi lại; chưa cần quyết ngay.
3. **Có chấp nhận sim chạy hai vòng bot (S0 sửa bot trước, rồi mới chỉnh số game) không**, kể cả khi vòng S0 cho ra expert ~30%+ (cao hơn mục tiêu)? Khuyến nghị: có, vì chỉnh số khi thước sai sẽ tốn công làm lại.

---

## Ghi chú reviewer (20/10/2026, reviewer độc lập; chưa chạy sim, chỉ đọc doc + doc nền)

Verdict: NEEDS REVISION nhẹ. Hướng đúng (sửa thước trước, lọc theo tay nghề, độ khó chung để cuối). Đã sửa thẳng 4 chỗ ở trên (đánh dấu "Reviewer sửa").

**1. Chọn lọc hay chỉ khó chung.**
- b1 (Hở), b2 (Giáp 1 lượt + vulnerable chỉ cho đòn sau), b3 (Nạp): về nguyên tắc chọn lọc đúng, vì thưởng Hold / thứ tự / khiên đúng chỗ. Nhưng "dự đoán random chết nhiều hơn expert" là giả định, chưa đo; sim sau mỗi mục (đã có trong mục 3) là bắt buộc, đừng gộp.
- Đòn Nạp x3: sửa về 2.5 (xem b3). Người mới không thấy tell thì chết oan, và Liam đang ở giai đoạn playtest nên cảm giác "unfair" là rủi ro lớn hơn lợi ích lọc.
- Giáp: `off_turns` 2 -> 1 cộng `max` 4 -> 5 cộng `div` 12 -> 10 là ba núm cùng lúc đẩy một hướng. Đổi một núm một lần (off_turns trước). Nếu cả ba, mặt dmg đơn của Axie thường còn 1, trận dài lê thê, người chơi khôn cũng bị phạt vì không còn đường nhanh. Ràng buộc: thời lượng trận trung bình (số lượt) phải đo, mục tiêu không quá +25% so với bản hiện tại.
- `enemy_dmg_mult` 1.35: nhảy 12.5% là lớn; nấc 0.05, dừng ở 1.30 trừ khi sim bắt buộc.

**2. Luật viên chưa dùng -> mana.**
- Có quyết định thật: biết bỏ viên yếu để lấy mana câu mặt mạnh. Tốt vì nối Hold, reroll, mana, Lõi mana.
- Lỗ hổng: (a) bỏ viên rồi dùng mana đó reroll viên khác cùng lượt, tạo vòng "bỏ 2, reroll 1 miễn phí" gần như reroll vô hạn nên đã thêm ràng buộc chưa-reroll + trần 6/trận. (b) Tách mana khỏi trục mana của Lõi (Hồ Mana, Ngọn Triều): nếu mana dễ ra thì mấy Lõi đó mất giá, nên Lõi mana phải đọc "mana từ luật này" tính riêng hoặc không tính. (c) Ở A3 (mất reroll miễn phí) luật này thành nguồn mana duy nhất, có thể là điều tốt, nhưng cần Liam biết. (d) Đừng để bot random/spam "tình cờ" hưởng: random dùng hết viên nên không nhận mana, đó là tín hiệu đúng.
- Phá lối: không phá lối nào, nhưng làm Lõi Ba Viên (tự Giữ viên dư) xung đột: viên dư tự Giữ nên không đủ điều kiện "chưa dùng và không Hold". Phải ghi rõ để khỏi bug.
- Rủi ro bot: expert chỉ sẽ biết dùng luật này nếu S0 dạy nó; nếu không, luật này không đo được.

**3. Lõi: giữ "jackpot".**
- Thác Đổ giảm tổng +20 -> +14 và Nổ Bào Tử 20% -> 12% là cắt thẳng con số, mà Liam muốn "phấn khích khi ra combo". Nerf kiểu này làm combo bớt đã.
- Đề xuất: nerf tần suất/điều kiện, đừng nerf đỉnh. (i) Thác Đổ giữ +2/+4/+6/+8 nhưng chuỗi đứt khi viên đi sai thứ tự hoặc bị Giáp trừ trước bonus, tức yêu cầu kỹ năng. (ii) Nổ Bào Tử 14% nhưng nổ lan thêm (chuỗi) khi quái chết do nổ, giữ khoảnh khắc "bùm". (iii) Lõi mạnh thường phải kèm một đánh đổi rõ (kiểu Phản Chấn) thay vì chỉ nerf số.
- Cách "đã": ra hiệu ứng riêng (banner/âm thanh/slow-mo nhẹ) khi combo kích hoạt đủ điều kiện; bot không cần, người chơi cần. Việc này của ux/vfx, ghi để Liam biết.
- Chốt: không quyết nerf Lõi nào cho tới khi có bảng thắng theo Lõi đã tách đội (mục c đã nói đúng như vậy; tôi chỉ nhấn mạnh là Nổ Bào Tử/Thác Đổ cũng phải chờ).

**4. Đòn bẩy tay nghề bị bỏ sót.**
- Intent quái đã công khai (doc nền, boss lượt Đòn). Vấn đề là liệu người chơi đọc được dễ không: cần màn hiển thị mục tiêu rõ (nhất là Nạp). Không phải thêm luật, chỉ cần UI; ghi lại để ux-designer.
- Thứ tự hàng, chọn mục tiêu dmg (quái nào giết trước): doc đã nêu "đo trước" nhưng không có đề xuất. Đề nghị thêm vào ablation: mục tiêu dmg (giết quái hỗ trợ trước) và thứ tự hàng ở Elite.
- Quản lý mana qua trận (giữ mana qua trận hay xả hết): mana có giữ qua trận không? Nếu reset mỗi trận thì luật b4 chỉ có ý nghĩa trong trận. Cần kiểm code, tôi chưa kiểm.
- Chọn Lõi theo đội (chọn đúng là quyết định lớn nhất, và 71.7% bị cap): ablation "chọn Lõi theo combo vs ngẫu nhiên" với expert2 nên là mục đầu tiên, vì đó là mục tiêu cốt lõi Liam nêu (biết ghép Lõi).

**5. Việc cần Liam quyết (gọn).**
- Q0 ở mục 4 (`enemy_dmg_mult` dừng 1.30): khuyến nghị đồng ý.
- Q1 luật mana: khuyến nghị có, kèm 3 ràng buộc ở b4.
- Q2 part_faces Aqua/Plant: chờ baseline 2.
- Q3 hai vòng bot: có.

**Rủi ro lớn nhất:** toàn bộ dự đoán win-rate chưa đo; mục tiêu "random <= 5% mà expert 15-25%" cách hiện tại 15 điểm, mà các núm đều đẩy cả hai bot xuống. Nếu sau S0 expert2 vẫn không hơn random ít nhất 10 điểm ở mixed_dmg/tank_heavy thì lỗi ở thiết kế quyết định, không phải số; khi đó cần thêm đòn bẩy (mục 4 ở trên) chứ không thêm độ khó. Rủi ro thứ hai: attack_spam khó xuống 5% (doc cũng tự nhận).
