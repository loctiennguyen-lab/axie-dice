# v4: vì sao quyết định không trả lãi, và 3 cách sửa

Ngày 21/10/2026. Người viết: systems-designer. Chưa sửa code, chưa commit. Số trong doc là ước lượng tay từ GDD 4.2/4.3 và sim SV4, để chọn điểm khởi động; sim quyết.

## 0. Cách đo dùng chung

Đơn vị: "viên-tương-đương" (VTĐ) = tổng (số viên trong Bộ x phần cộng `bo_add` đã nhân `bo.scale`) của một lượt. Chia 5 ra phần trăm sức mạnh đội nếu cả đội là dmg (GDD 4.3).

| Symbol | Type | Range | Description |
|---|---|---|---|
| `a3, a4, a5` | float | 0-3 | phần cộng của Bộ ba/bốn/năm (= `bo.add_k` x `bo.scale`) |
| `V` | float | 0-10 | VTĐ trung bình một lượt = P(ba chính xác) x 3·a3 + P(bốn chính xác) x 4·a4 + P(năm) x 5·a5 |
| `h` | float | 0.14-0.20 | xác suất một viên tung lại rơi đúng part (1/5 vì Tai cantrip; Liều thêm nhân 0.7 do Nứt: 0.14) |
| `ΔV_hunt` | float | 0-4 | lãi gộp của một lần săn từ Bộ ba, tung 2 viên: P(+1)·(4·a4 - 3·a3) + P(+2)·(5·a5 - 3·a3) |
| `λ` | float | 0.2-0.5 | giá trị một mana tính bằng VTĐ (mana chỉ còn đổi được sang Overcast, reroll, relic active) |
| `g` | float | 0-1 | sức mạnh thật = 0.45 x (V/5) (GDD 4.5 dùng 0.4-0.5) |

Ghi chú: V đầu ra không chặn, nhưng `M` mỗi viên bị cắt ở `bo.m_cap` 3.0.

Độ nhạy win-rate (suy từ sim, thô): expert hơn random 14 điểm, hai bên chênh khoảng 0.18 `g` (V ~2.4 vs 0.42 sau hệ số 0.45), tức khoảng 0.8 điểm win-rate cho mỗi 1% sức mạnh thật. Để quyết định mang được +12 điểm cần ~+15% `g`, tức ~+1.7 VTĐ ròng (đã trừ mana) từ phần trả giá. Đây là mục tiêu số cho mọi phương án.

## 1. Vì sao quyết định không trả lãi

Knob hiện tại: ba +0.40, bốn +0.80, năm +1.60 (`bo.scale` 0.8), cap 3.0, Liều Nứt 30%, An toàn 2 rồi 3 mana, Mặt Tạm 2 mana, Overcast 3 mana +0.5.

Phân rã V theo nguồn (5 part, bảng 4.2):

| Nguồn | P(ba+ / bốn+ / năm) | V | Phần của V đầy đủ |
|---|---|---|---|
| Lần tung đầu, không làm gì | 29.0 / 3.4 / 0.16% | 0.42 | 17% |
| + 1 lần miễn phí, giữ nhóm lớn nhất (không rủi ro, không mana) | 65.0 / 19.7 / 2.4% | 1.29 | +36% |
| + 2 lần trả giá (An toàn 2+3 mana, hoặc Liều) | ~93 / ~55 / ~16% | ~3.0 | +47% nhưng tốn 5 mana |

Tức người chơi chỉ cần giữ nhóm và bấm reroll miễn phí là lấy 53% tổng lợi từ BỘ, không cần quyết định gì. Phần quyết định thật chỉ còn khoảng 1.7 VTĐ gộp, rồi phải trừ giá:

1. Săn từ bộ ba lên bộ bốn bằng An toàn: `ΔV_hunt = P(+1)·(4·0.8 - 3·0.4) + P(+2)·(5·1.6 - 3·0.4) = 0.32·2.0 + 0.04·6.8 = 0.91` VTĐ cho 2 mana. `λ`~0.25-0.3 thì giá ~0.55, ròng ~0.35 VTĐ = +7% VTĐ/5, tức `g` +3%, tức ~2.5 điểm win-rate. Nằm trong sai số +-5 của sim.
2. Liều: `h` hiệu dụng 0.14, P(+1)=24%, P(+2)=2%: `ΔV_hunt` = 0.48 + 0.13 = 0.61. Trừ phạt Nứt: kỳ vọng 0.6 viên Nứt, mỗi viên mất nửa giá trị ~0.5 VTĐ = -0.3. Ròng ~+0.3, miễn phí mana. Khớp trace: Liều +1.5 giá trị TB, Safe +3.6, 58/241 lần Liều tụt giá trị.
3. Mặt Tạm: đôi lên ba = 0.4·3 - 0 = +1.2 VTĐ (ba bốn nhân cả nhóm) cho 2 mana, ròng ~+0.65. Là lựa chọn tốt nhất, nhưng chỉ nâng một bậc và bậc 2-3 nhỏ (+0.4 mỗi viên), nên hiếm khi quyết định lượt thắng.
4. Overcast: +0.5 trên một viên = +0.5 VTĐ cho 3 mana, ròng ~0 đến +0.2.
5. Bậc thưởng gần như tuyến tính: Bộ bốn chỉ hơn bộ ba +0.40 mỗi viên (x1.8 vs x1.4). Muốn kiếm bộ bốn phải tung 2 viên với 36% thành công; kỳ vọng ~+0.9 VTĐ không bù nổi giá 2 mana, tay viên bị tung lại, và rủi ro Nứt. Săn không phải quyết định "đúng/sai", mà gần hoà.

Cộng lại: tổng ròng của cả bốn cơ chế khoảng +0.3 + 0.35 + 0.65 + 0.1 ~ 1.4 VTĐ nếu bot tối ưu hoàn hảo, thực tế bot trừ lỗi còn <= 0.5, tức ~+4% `g`, ~3 điểm. Đúng bằng độ lệch ablation (Δ -2.4 đến +4.0). Sim không sai; số knob là nguyên nhân.

Hai thứ nữa làm quyết định mỏng:
- Mana ít cạnh tranh: sink (reroll 2-3, Mặt Tạm 2, Overcast 3) nhiều nhưng không cái nào hơn rõ, nên bot không có chỗ "chọn đúng".
- Săn tốn viên: tung lại 2 viên ngoài Bộ là bỏ giá trị hiện tại của chúng (khiên, hồi). Lãi gộp 0.91 trừ chi phí này gần bằng 0.

Kết luận: tay nghề +14 điểm đến từ "giữ nhóm + 1 reroll miễn phí" (và random không biết làm) chứ không từ quyết định trả giá.

## 2. Ba phương án

### A. Bậc thưởng dốc, Mặt Tạm không tạo Bộ năm (khuyến nghị)

Đổi:
- `bo.scale` 1.0, `bo.add_3` 0.2 (x1.2), `bo.add_4` 1.2 (x2.2), `bo.add_5` 2.0 (x3.0), `bo.m_cap` 3.0 giữ nguyên (năm + Overcast bị cắt về 3.0, chấp nhận).
- Luật mới, một dòng: "Mặt Tạm không thể làm Bộ lên năm" (thêm vào `wild_block_reason`: từ chối nếu `size(slot) + 1 >= 5`). Lý do: không có luật này thì Mặt Tạm biến bộ bốn tự nhiên thành năm (+5.2 VTĐ) cho 2 mana, jackpot thành thường ngày.
- `enemy_dmg_mult` 1.45 -> ~1.50 khởi điểm, chỉnh theo sim (xem mục 3).

EV mới (5 part):
- V không làm gì: 0.256·0.6 + 0.032·4.8 + 0.0016·10 = 0.32 (cũ 0.42).
- V với 1 reroll miễn phí giữ nhóm: 0.453·0.6 + 0.173·4.8 + 0.024·10 = 1.34 (cũ 1.29).
- Săn An toàn từ ba: `0.32·(4.8-0.6) + 0.04·(10-0.6) = 1.34 + 0.38 = 1.72` VTĐ cho 2 mana (cũ 0.91). Ròng ~+1.1.
- Mặt Tạm đôi->ba chỉ +0.6, nhưng ba->bốn +4.2 VTĐ (cũ +2.0) cho 2 mana: lãi cao nhất, chắc chắn, nhưng chỉ khi đã có ba.
- Liều từ ba: `0.24·4.2 + 0.02·9.4 = 1.2`, trừ Nứt -0.3 ~ +0.9 miễn mana. Gần hoà với An toàn (ròng ~+1.1): đây mới là quyết định thật, phụ thuộc mana còn lại và giá trị 2 viên ngoài.
- Expert: ~3.4 VTĐ (cũ ~2.4), random 0.32. Bot `attack_spam` trong sim KHÔNG reroll, không giữ nhóm (`_move_attack_spam` chỉ bấm viên dmg đầu tiên), nên V của nó ~0.32 (cũ 0.42), không phải 1.34. 1.34 là người chơi "giữ nhóm + 1 reroll miễn phí", sim không có bot này. Chênh expert - spam ~3.1 VTĐ gộp trong sim, nhưng phần lớn chỉ là "biết reroll" (xem Ghi chú reviewer).

Vì sao quyết định đúng thắng rõ: nhảy từ ba lên bốn gấp 7 lần nhảy từ đôi lên ba (+4.2 vs +0.6). Nên "giữ ba, bỏ 2 viên để săn" lời gấp đôi hôm nay, và "dùng Mặt Tạm vào ba chứ không vào đôi" là điều bot ngu sẽ làm sai (Mặt Tạm vào đôi chỉ +0.6 cho 2 mana, lỗ).

Rủi ro làm dễ đi: cao nhất của 3 cách. Expert ~+40% V so với cũ (2.4 -> 3.4), nhưng nhân hệ số 0.45 và chia 5 ra `g` tăng ~+9%; D^2/(1+g) cần D tăng ~4% để bù (1.45 -> 1.50). Người chơi chỉ giữ nhóm + reroll miễn phí không đổi nhiều (1.29 -> 1.34); bot spam/random (không reroll) yếu đi (0.42 -> 0.32). Nếu chỉ giữ ba mà không săn thì thua cũ (0.6 vs 1.2/bộ ba cũ). Bắt buộc sim chạy lại D.

Độ phức tạp cho người chơi: thấp. Không thêm khái niệm mới, chỉ đổi số hiển thị (x1.2/x2.2/x3.0) và một dòng cấm Mặt Tạm lên năm. Câu cho người mới giữ nguyên.

Gacha vui: bốn x2.2 là "pop" rõ (gần gấp đôi), năm x3.0 là jackpot hiếm 2.4% sau free reroll, 16% nếu chase đủ.

Chi phí code: S đến M. Đổi 4 knob trong `combat_tune.json`, thêm điều kiện trong `wild_block_reason`, cập nhật các test có số (t_dice_depth_v4*, `t_economy` nếu đọc knob), sửa chữ Codex/coach sinh từ knob. Bump replay: CÓ (`RULES_VERSION`, knob nằm trong fingerprint và đổi kết quả combat). Đã kiểm: `t_rules_version` duyệt đệ quy `res://assets/data/rules` (.json), nên `combat_tune.json` nằm trong fingerprint; đổi là phải bump `RULES_VERSION` + deploy Worker.

### B. "Chốt BỘ" (BỘ không thụ động)

Đổi: Bộ chỉ nhân sau khi người chơi gọi `lock_bo(part)` (1 lần/lượt, 0 mana). Viên bị chốt không tung lại và không Hold sang lượt sau. Không chốt thì V = 0.

EV: expert ~không đổi (3.0-3.4 VTĐ nhưng luôn chốt), random giảm ~V 0.1, spam giảm nhiều nếu bot không biết chốt. Chênh vì "biết bấm", không vì quyết định: chốt gần như luôn đúng (dominated choice). Cái duy nhất còn lại là chốt part nào khi có hai nhóm, hiếm.

Vì sao đúng thắng rõ: chỉ vì phần thưởng cho bấm đúng nút, không có đánh đổi mới. Quyết định trả giá (Liều/An toàn/Mặt Tạm) vẫn mỏng như cũ.

Rủi ro làm dễ đi: thấp (random bị giảm). Độ phức tạp: cao (thêm 1 hành động, 1 trạng thái; stage 1 đã đếm 3 khái niệm, thêm "chốt" thành 4 = ngưỡng). Chi phí code: L (action mới `lock_bo` + ActionLog canon + `worker/src/epoch_args.json` + UI + bot + tests + coach). Bump replay: CÓ, và đổi cả giao thức worker (deploy Worker).

Nhận xét: phản trực giác với "dễ hiểu" và không giải quyết gốc (số knob). Không khuyến nghị.

### C. Giảm giá/rủi ro săn

Đổi: An toàn 1 rồi 2 mana, Mặt Tạm 1 mana (còn 1 lần/lượt), Liều lần đầu mỗi lượt Nứt 15% (lần sau 30%). Giữ nguyên tier (0.4/0.8/1.6, cap 3.0).

EV: săn An toàn từ ba: 0.91 VTĐ cho 1 mana, ròng ~+0.65 (cũ +0.35). Liều lần đầu `h` 0.17: ΔV 0.75, trừ Nứt (0.3 viên Nứt) -0.15, ròng +0.6. Mặt Tạm 1 mana đôi->ba +1.2 ròng +0.95. Expert ~3.0 VTĐ nhưng đạt rẻ hơn, nên chọn dễ: An toàn 1 mana luôn đáng bấm, đúng một đáp án cho mọi người, kể cả bot spam nếu nó biết mua. Chênh quyết định hẹp lại (ai cũng mua).

Rủi ro làm dễ đi: cao: tất cả mana đổi thành Bộ lớn dễ hơn, mọi người mạnh lên, phải tăng D lớn hơn A. Phức tạp: thấp. Code: S (3-4 knob + Nứt lần đầu cần biến `liều_used`, thuộc về M nếu muốn nhỏ gọn). Bump replay: CÓ.

Nhận xét: tăng sức mạnh chung, không tăng độ chênh vì lãi vẫn tuyến tính. Chỉ dùng như bổ sung nếu A làm Liều hoặc Mặt Tạm quá nghèo.

## 3. Khuyến nghị: A, bộ số khởi điểm và kế hoạch sim

Khởi điểm A (đổi trong `combat_tune.json`, `bo.*`):

```
bo.scale  1.0     (cũ 0.8)
bo.add_3  0.2     (x1.2)
bo.add_4  1.2     (x2.2)
bo.add_5  2.0     (x3.0)
bo.m_cap  3.0     (giữ)
crack.pct 30      (giữ)
reroll.mana_cost_2 / _3   2 / 3 (giữ)
wild.cost 2, per_turn 1 (giữ) + luật mới: Mặt Tạm không lên Bộ năm
difficulty.enemy_dmg_mult 1.50 (cũ 1.45), boss_hp_mult 1.10 (giữ)
```

Thứ tự chỉnh nếu lệch: (1) `enemy_dmg_mult` +-0.03 để expert vào 18-23; (2) `bo.add_3` 0.2 lên 0.3 nếu random/spam dưới 6% (quá tàn nhẫn); (3) `crack.pct` 30 lên 35 nếu Liều lấn An toàn, hạ 25 nếu Liều chết; (4) `wild.cost` 2 lên 3 nếu Mặt Tạm lượt nào cũng bấm.

Kế hoạch sim (không cần 1500 run): dùng chung seed cặp (CRN), metric trên mỗi lượt/mỗi trận nên SE nhỏ, 200-250 run mỗi bản là đủ.

| Metric | Cách đo | Ngưỡng đạt |
|---|---|---|
| `V` thực (VTĐ mỗi lượt) và M trung bình trên viên dmg dùng | log từ engine mỗi lượt | expert >= 3.0, spam <= 0.4 (bot không reroll), random <= 0.4; thêm bot "free-hold" (giữ nhóm + 1 reroll miễn phí) mục tiêu 1.2-1.5 |
| dmg/lượt (dmg tổng / số lượt) | theo trận | mỗi ablation (no_lieu / no_wild / no_overcast / no_hunt) làm expert giảm >= 4%; tắt cả 4 giảm >= 15% |
| số lượt hạ boss, HP còn lại sau boss | trên trận thắng và thua | expert hơn spam >= 1 lượt hoặc >= 20% HP |
| tụt giá trị khi săn (`58/241` ở bản cũ) | trace | < 15% lần Liều |
| mana tiêu/nhận (GDD 4.4) | theo trận | expert >= 70%, dư cuối trận < 40% |

Vòng 1: expert + spam + random + 4 ablation, 200 run, chỉ để xem dmg/lượt và V (~1 giờ máy chậm). Nếu các Δ ablation >= 4% thì vòng 2: expert/spam/random 600 run để đo win-rate (mục tiêu expert 18-23, random/spam <= 10-12, chênh >= 12-15). Chỉ khi cả hai đạt mới chạy 1500 run để chốt.

Lỗi chính cần chú ý: bot expert v2 vẫn lấy mẫu 16 lần với mô hình cũ. Phải sửa mô hình giá trị bot cho tier mới (đọc từ `bo_add100`, nên tự theo knob; kiểm lại hằng nào hard-code) trước khi tin ablation.

## 4. Câu hỏi cho Liam

1. Chấp nhận Mặt Tạm không lên được Bộ năm (năm chỉ có tự nhiên) để jackpot hiếm? Khuyến nghị: có. Nếu không, Mặt Tạm phải tăng giá lên 3 mana hoặc bó 1 lần/trận, và A mạnh hơn nhiều.
2. Random/spam hiện 14/17%: nếu sau A vẫn >12% thì ưu tiên hạ `bo.add_3` xuống 0.1 (bộ ba gần như không đáng) hay tăng nhẹ `enemy_dmg_mult` (cả expert cũng đau)? Khuyến nghị gốc: hạ `bo.add_3`. Reviewer không đồng ý (xem Ghi chú): random/spam không reroll nên bộ ba gần như không dính tới họ; hạ add_3 chỉ làm người chơi thật thấy ít thưởng. Hỏi lại: "random/spam >12% thì tăng `enemy_dmg_mult` hay hạ `bo.add_3` (không khuyến nghị)?". Cần đo thêm bot free-hold trước khi hỏi.
3. Mục tiêu "expert khó hơn bản cũ 28.6" nghĩa là chốt trong khoảng 18-23, hay tuỳ vào ablation vòng 1? Khuyến nghị: chốt 20 +-3, đo bằng 600 run sau khi metric vòng 1 xanh.

## Ghi chú reviewer (game-designer)

Ngày 21/10/2026. Đã kiểm lại phép tính EV (V, săn An toàn, Liều, tổng V cũ/mới) khớp bảng 4.2. Sửa trực tiếp 4 chỗ ở trên (spam, metric, fingerprint, Q2). Còn lại là bất đồng:

1. **Spam sai giả định.** `attack_spam` không reroll/giữ nhóm, V ~0.32. Con số "spam 1.34 / 17%" trong GDD trộn hai thứ khác nhau. Việc "giữ nhóm + free reroll" (53% lợi BỘ) chỉ expert làm. Nên thêm bot free-hold vào sim trước khi tin chênh "tay nghề +12".
2. **A làm ăn may bộ năm?** Có một phần. Expert săn đủ: ~16% lượt ra Năm x10 VTĐ = ~1.6 trên 3.4 tổng, gần nửa sức mạnh đến từ 16% lượt. Tay nghề vẫn có (bốn x2.2 giữ được ở 55%) nhưng độ biến thiên lượt tăng mạnh. Đề xuất: `bo.add_5` 1.6 (x2.6) thay 2.0, V năm giảm 10 -> 8; vẫn pop, đỡ ngẫu nhiên. Đo lại độ lệch chuẩn dmg/lượt.
3. **Mặt Tạm lấn quyết định.** Sau A, Mặt Tạm ba->bốn chắc chắn +4.2 cho 2 mana, hơn hẳn săn An toàn (EV 1.72 cùng giá). Bấm Mặt Tạm vào ba là đáp án duy nhất khi có viên rảnh, nên "quyết định" chỉ còn trong phần còn mana. Đưa `wild.cost` 3 vào vòng 1 cùng lúc, không để cuối thứ tự chỉnh.
4. **Bộ ba x1.2 và "gacha vui".** Bộ ba ra 26% lần tung đầu, ~45% sau free reroll; +20% mỗi viên trong Bộ nên 0.6 VTĐ = ~12% sức đội: gần như vô hình, người chơi thấy "ba chẳng ăn gì" gần nửa số lượt. Pop thật nằm ở bốn (17% sau free reroll, ~55% khi trả giá). Chấp nhận được nếu UI chỉ ăn mừng từ bốn; còn không đặt `add_3` 0.3 (x1.3) làm mặc định, đừng hạ 0.1 như Q2 cũ.
5. **Kết hợp A + C một phần (khuyến nghị):** A + An toàn lần 1 còn 1 mana (lần 2 giữ 3) + `add_5` 1.6. Lãi săn bốn ~1.7 cho 1 mana khiến săn đáng tiền mà vẫn tốn mana; không động Liều và Mặt Tạm giá 2 (hoặc 3 như mục 3). Không lấy C đầy đủ (Mặt Tạm 1 mana + Nứt 15%) vì làm mọi người mạnh lên mà không thêm chênh.
6. **Hằng hard-code trong bot expert** (không tự theo knob): v1 `_hunt_ev` dùng p=1/6 cứng (sim_balance.gd ~818) trong khi bài tính Tai cantrip = 1/5; `ev < 1.0` ngưỡng cứng; hệ số mana x1.0 cứng (không phải λ 0.25-0.5, nên bot trả mana đắt gấp 2-4 lần giá trị thật, nghiêng về Liều); `E2_MIN_GAIN 0.8` và `E2_SAMPLES 16` cứng (sample nhỏ khi ΔV tăng thì ổn, nhưng ngưỡng 0.8 nên đo lại với tier mới). Đọc `bo_add100/bo_cap100` thì tự theo knob. Sửa mấy hằng này trước ablation, nếu không "Liều thắng An toàn" có thể do bot chứ không do số.
7. Mục 3 xác nhận 3 giả định: (a) `combat_tune.json` có trong fingerprint: ĐÚNG; (b) `attack_spam` có reroll/giữ nhóm: SAI, không có; (c) hằng hard-code trong expert: CÓ (mục 6).
8. **3 câu hỏi cho Liam**: Q1 đúng và đủ ý. Q2 đã sửa, phải đổi sang so `enemy_dmg_mult` vs bot free-hold. Q3 đúng. Thiếu câu thứ tư: Liam chọn nhịp "ăn mừng" nào, từ bộ ba hay chỉ từ bộ bốn (ảnh hưởng UI + `add_3`).

Khuyến nghị cuối: A + An toàn 1 mana + `add_5` 1.6 + `wild.cost` 3 thử ở vòng 1; sửa bot trước; chưa chốt trước khi có số.

## Liam chốt (22/10)
1. Đồng ý hướng A+: bộ ba ×1.3, bộ bốn ×2.2, bộ năm ×2.6; An toàn lần đầu 1 mana; Mặt Tạm 3 mana và không tạo được Bộ năm; quái ~×1.50 để bù. Sim xác nhận bằng metric nhạy trước, đạt rồi mới đo win-rate 600 run.
2. Mục tiêu người giỏi (expert) 20% ±3.
3. Ăn mừng lớn (banner, âm jackpot) từ bộ bốn; bộ ba chỉ sáng nhẹ.
